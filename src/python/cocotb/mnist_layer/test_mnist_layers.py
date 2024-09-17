import random
import sys

import cocotb
import matplotlib.pyplot as plt
import numpy as np
import torch
from cocotb.triggers import RisingEdge
from tabulate import tabulate

sys.path.insert(1, "../")
from utils import (
    assert_reset_state,
    reset_dut,
    setup_clock,
    sys_enable_dut,
    tensor_init,
    vector_init,
    volume_init,
)
from model import *

np.set_printoptions(
    suppress=True
)  # prevent numpy exponential notation on print, default False

# Constants
CLOCK_PERIOD_NS = 10
PYTORCH_PATH = r"/home/tim/Project/YOLO-FPGA-VHDL/src/python/lib/mnist_cnn.pt"


def get_generics(dut):
    """
    Retrieve the generic parameters from the DUT.
    """
    return {
        "DATA_SCALE_FACTOR": dut.DATA_SCALE_FACTOR.value,
        "BITWIDTH": dut.BITWIDTH.value,
        "INPUT_SIZE": dut.INPUT_SIZE.value,
        "KERNEL_SIZE": dut.KERNEL_SIZE.value,
        "INPUT_CHANNELS_1": dut.INPUT_CHANNELS_1.value,
        "OUTPUT_CHANNELS_1": dut.OUTPUT_CHANNELS_1.value,
        "PADDING": dut.PADDING.value,
        "STRIDE_1": dut.STRIDE_1.value,
        "OUTPUT_CHANNELS_2": dut.OUTPUT_CHANNELS_2.value,
        "STRIDE_2": dut.STRIDE_2.value,
    }


def log_generics(dut):
    """
    Log the generic parameters from the DUT in a table format.
    """
    generics = get_generics(dut)
    table = tabulate(
        generics.items(), headers=["Parameter", "Value"], tablefmt="grid"
    )
    dut._log.info(f"Running with generics:\n{table}")


def calculate_output_dimensions(generics):
    """
    Calculate the output height and width based on the input dimensions and parameters.
    """
    # first layer
    return 12, 12


def convert_output_to_int(output):
    """
    Convert the output tensor to integers based on the bitwidth.
    """
    for i in range(len(output[0])):
        for j in range(len(output[0][0])):
            for k in range(len(output)):
                output[k][i][j] = output[k][i][j].signed_integer

    return output


async def initialize_dut(dut, generics):
    """
        Initialize the DUT with default values.
                --

            i_data_conv2d
            i_kernel_conv2d
            i_bias_conv2d_1
    for conv2d

            --
    -- batchnorm2d
            --

    i_mean_bn_1   :
    i_weight_bn_1 :
    i_bias_bn_1   :
    for batchnorm2d

    conv2d input
            i_kernel_conv2d
            i_bias_conv2d_2
    for conv2d

    -- batchnorm2d
    i_mean_bn_2   :
    i_weight_bn_2 :
    i_bias_bn_2   :
    """
    await setup_clock(dut)
    dut.i_sys_enable.value = 0
    dut.i_data_conv2d.value = volume_init(
        generics["INPUT_CHANNELS_1"],
        generics["INPUT_SIZE"],
        generics["INPUT_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_data_valid.value = 0
    dut.i_kernel_conv2d_1.value = tensor_init(
        generics["OUTPUT_CHANNELS_1"],
        generics["INPUT_CHANNELS_1"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_bias_conv2d_1.value = vector_init(generics["OUTPUT_CHANNELS_1"])
    dut.i_bias_bn_1.value = vector_init(generics["OUTPUT_CHANNELS_1"])
    dut.i_mean_bn_1.value = vector_init(generics["OUTPUT_CHANNELS_1"])
    dut.i_weight_bn_1.value = vector_init(generics["OUTPUT_CHANNELS_1"])

    dut.i_kernel_conv2d_2.value = tensor_init(
        generics["OUTPUT_CHANNELS_2"],
        generics["OUTPUT_CHANNELS_1"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )

    dut.i_bias_conv2d_2.value = vector_init(generics["OUTPUT_CHANNELS_2"])
    dut.i_bias_bn_2.value = vector_init(generics["OUTPUT_CHANNELS_2"])
    dut.i_mean_bn_2.value = vector_init(generics["OUTPUT_CHANNELS_2"])
    dut.i_weight_bn_2.value = vector_init(generics["OUTPUT_CHANNELS_2"])
    await RisingEdge(dut.clock)


@cocotb.test()
async def async_reset_test(dut):
    """
    Test the DUT's behavior during reset.
    """
    generics = get_generics(dut)
    log_generics(dut)

    # Compute output dimensions
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS_2"], h_out, w_out)

    await initialize_dut(dut, generics)
    await reset_dut(dut)

    # Check if output is a tensor filled with zeros
    await assert_reset_state(dut, output_zeros)


def preprocess_layer(
    generics: dict,
    conv2d_layer: torch.nn.Conv2d,
    bn_layer: torch.nn.BatchNorm2d,
):
    """
    Preprocesses convolutional and batch normalization layers.
    Scales weights, biases, and batch norm parameters for integer conversion.

    Parameters:
    ----------
        generics (dict): Dictionary containing configuration parameters.
        conv2d_layer (torch.nn.Conv2d): The Conv2D layer to preprocess.
        bn_layer (torch.nn.BatchNorm2d): The BatchNorm layer to preprocess.

    Returns:
    -------
        Tuple[List[int]]: Preprocessed convolution weights, biases, batch norm mean, weight, and bias.
    """
    scale_factor = 2 ** generics["DATA_SCALE_FACTOR"]

    def scale_and_convert(tensor, scale_factor):
        return (tensor * scale_factor).int().tolist()

    # Convolutional layer weights and bias scaling
    i_kernel_conv2d = scale_and_convert(conv2d_layer.weight, scale_factor)
    i_bias_conv2d = scale_and_convert(conv2d_layer.bias, scale_factor)

    epsilon = 1e-5  # A small constant to prevent division by zero
    scaled_var = (bn_layer.running_var + epsilon).sqrt()
    new_bn_weight = scale_and_convert(
        bn_layer.weight / scaled_var, scale_factor
    )

    # BatchNorm mean and bias scaling
    bn_running_mean = scale_and_convert(bn_layer.running_mean, scale_factor)
    bn_bias = scale_and_convert(bn_layer.bias, scale_factor)

    return (
        i_kernel_conv2d,
        i_bias_conv2d,
        bn_running_mean,
        new_bn_weight,
        bn_bias,
    )


def generate_report(
    generics, input, output_silu, output_hs, gotten_output, doit=False
):
    import plotly.graph_objects as go
    import torch
    from torchvision import transforms

    # Flip y axis for a tensor (idk why, plotly is doing weird stuff)
    output_hs = torch.flip(output_hs, [1])
    output_silu = torch.flip(output_silu, [1])
    gotten_output = torch.flip(gotten_output, [1])
    input = torch.flip(input, [1])

    # Apply inverse transformation to the input
    if doit:
        inverse_transform = transforms.Compose(
            [
                transforms.Normalize(mean=[-0.1307 / 0.3081], std=[1 / 0.3081]),
                transforms.ToPILImage(),
            ]
        )

        original_image = inverse_transform(input)
    else:
        original_image = input

    # Calculate the absolute difference between the Python HS and VHDL output
    abs_diff_hs = torch.abs(output_hs - gotten_output)
    abs_diff_hs = abs_diff_hs.float()

    avg_diff_per_channel = []
    max_diff_per_channel = []
    min_diff_per_channel = []

    # Iterate over each channel to compute statistics
    num_channels = abs_diff_hs.shape[0]
    for channel in range(num_channels):
        channel_diff = abs_diff_hs[channel]
        avg_diff_per_channel.append(torch.mean(channel_diff).item())
        max_diff_per_channel.append(torch.max(channel_diff).item())
        min_diff_per_channel.append(torch.min(channel_diff).item())

    # Setup the data
    num_channels, height, width = output_hs.shape

    # Create Generic Parameters for the report
    font = dict(family="Arial, sans-serif", size=12, color="black")
    main_title = dict(
        text=(
            f"<b>Convolutional Layer Report</b><br>"
            f"<span style='font-size: 14px;'>"
            f"Input Shape: {input.shape}, Output Shape: {output_hs.shape}<br>"
        ),
        x=0.0,
        y=0.95,
        font={"family": "Arial, sans-serif", "color": "black"},
        xanchor="left",
        yanchor="top",
    )

    # Only use the first channel
    channel = 0

    # Heatmap traces
    data_hs = go.Heatmap(
        z=output_hs[channel],
        colorscale="Viridis",
        visible=False,
        coloraxis="coloraxis",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_silu = go.Heatmap(
        z=output_silu[channel],
        colorscale="Viridis",
        visible=False,
        coloraxis="coloraxis",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_gotten = go.Heatmap(
        z=gotten_output[channel],
        colorscale="Viridis",
        visible=False,
        coloraxis="coloraxis",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_abs_diff_hs = go.Heatmap(
        z=abs_diff_hs[channel],
        colorscale="Thermal",
        visible=False,
        coloraxis="coloraxis2",
        hovertemplate="(%{x}, %{y})<br>Value: %{z:.2f}",
        name="",
    )

    data_input = go.Heatmap(
        z=original_image,
        colorscale="gray",
        visible=True,
        coloraxis="coloraxis3",
        hovertemplate="(%{x}, %{y})<br>Value: %{z}",
        name="",
    )

    # Combine the data
    data = [data_input, data_hs, data_silu, data_gotten, data_abs_diff_hs]

    # Create figure
    fig = go.Figure(data=data)

    # Create buttons
    buttons = [
        dict(
            label="Input Image",
            method="update",
            args=[
                {"visible": [True, False, False, False, False]},
                {"xaxis": {"title": "Input Image"}},
            ],
        ),
        dict(
            label="Python HS",
            method="update",
            args=[
                {"visible": [False, True, False, False, False]},
                {"xaxis": {"title": "Python Result with Hardswish Function"}},
            ],
        ),
        dict(
            label="Python SiLU",
            method="update",
            args=[
                {"visible": [False, False, True, False, False]},
                {"xaxis": {"title": "Python Result with SiLU Function"}},
            ],
        ),
        dict(
            label="VHDL Output",
            method="update",
            args=[
                {"visible": [False, False, False, True, False]},
                {"xaxis": {"title": "VHDL Result"}},
            ],
        ),
        dict(
            label="Abs Diff",
            method="update",
            args=[
                {"visible": [False, False, False, False, True]},
                {
                    "xaxis": {
                        "title": "Absolute Difference between Python HS and VHDL"
                    }
                },
            ],
        ),
    ]

    # Create layout
    fig.update_layout(
        # Update the Menu
        updatemenus=[
            dict(
                buttons=buttons,
                direction="down",
                pad={"r": 10, "t": 10},
                showactive=True,
                x=1,
                xanchor="left",
                y=1.1,
                yanchor="top",
            )
        ],
        coloraxis=dict(
            colorscale="Viridis",
            colorbar=dict(
                title="Scale",
                tickformat=".2e",
                exponentformat="power",
            ),
        ),
        coloraxis2=dict(
            colorscale="Thermal",
            colorbar=dict(
                title="Abs Diff Scale",
                tickvals=[
                    min_diff_per_channel[channel],
                    avg_diff_per_channel[channel],
                    max_diff_per_channel[channel],
                ],
                ticktext=[
                    f"min: {min_diff_per_channel[channel]:.2f}",
                    f"avg: {avg_diff_per_channel[channel]:.2f}",
                    f"max: {max_diff_per_channel[channel]:.2f}",
                ],
                tickformat=".2f",
            ),
        ),
        coloraxis3=dict(
            colorscale="gray",
            colorbar=dict(title="Value"),
        ),
        # Update the layout
        title=main_title,
        xaxis_title="Input Image",
        width=800,
        height=800,
        font=font,
        margin=dict(l=20, r=20, t=100, b=20),
    )

    # Show the figure
    fig.show()


def preprocess_input(generics: dict, i_data: torch.Tensor):
    """
    Preprocesses the input data by scaling it and converting to integer format.

    Parameters:
    ----------
        generics (dict): Configuration dictionary with scale factor.
        i_data (torch.Tensor): Input data tensor.

    Returns:
    -------
        List[int]: Preprocessed input data.
    """
    scale_factor = 2 ** generics["DATA_SCALE_FACTOR"]
    return (i_data * scale_factor).int().tolist()


@cocotb.test()
async def mnist_test_first_layer(dut):
    """
    Test the DUT's first Conv layer behavior with random inputs from the MNIST dataset.
    """
    generics = get_generics(dut)

    # Load Dataset and Model
    model, test_loader = load_dataset(PYTORCH_PATH)

    # Compute output dimensions and initialize
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS_2"], h_out, w_out)

    # Initialize DUT and perform reset
    await initialize_dut(dut, generics)
    await reset_dut(dut)

    # Assert reset state
    await assert_reset_state(dut, output_zeros)

    # Enable System
    await sys_enable_dut(dut)
    await RisingEdge(dut.clock)

    # Get random image and target from dataset
    data, target = next(iter(test_loader))
    random_index = random.randint(0, len(test_loader) - 1)
    image, label = data[random_index], target[random_index]

    # Extract the first layer's and forward it
    extracted_model = ExtractedNetConv(
        model, 2 ** generics["DATA_SCALE_FACTOR"]
    )
    output_first_layer_silu = extracted_model.forward_first_layer(
        image.unsqueeze(0)
    ).int()[0]
    output_first_layer_hs = extracted_model.forward_first_layer_approximate(
        image.unsqueeze(0)
    ).int()[0]

    # Preprocess Conv2D and BatchNorm layers
    (
        i_kernel_conv2d_1,
        i_bias_conv2d_1,
        i_mean_bn_1,
        i_weight_bn_1,
        i_bias_bn_1,
    ) = preprocess_layer(generics, extracted_model.conv1, extracted_model.bn1)

    (
        i_kernel_conv2d_2,
        i_bias_conv2d_2,
        i_mean_bn_2,
        i_weight_bn_2,
        i_bias_bn_2,
    ) = preprocess_layer(generics, extracted_model.conv2, extracted_model.bn2)

    # Preprocess input image
    i_data_conv2d = preprocess_input(generics, image)

    # Set DUT values for Conv2D and BatchNorm
    dut.i_data_conv2d.value = i_data_conv2d
    dut.i_kernel_conv2d_1.value = i_kernel_conv2d_1
    dut.i_bias_conv2d_1.value = i_bias_conv2d_1

    dut.i_bias_bn_1.value = i_bias_bn_1
    dut.i_mean_bn_1.value = i_mean_bn_1
    dut.i_weight_bn_1.value = i_weight_bn_1

    dut.i_kernel_conv2d_2.value = i_kernel_conv2d_2
    dut.i_bias_conv2d_2.value = i_bias_conv2d_2
    dut.i_bias_bn_2.value = i_bias_bn_2
    dut.i_mean_bn_2.value = i_mean_bn_2
    dut.i_weight_bn_2.value = i_weight_bn_2

    # Wait few clock cycles
    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)

    # Set i_data_valid
    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0
    await RisingEdge(dut.clock)

    # Wait until the data is valid in DUT's output
    while dut.r_data_conv2d_1_valid.value != 1:
        await RisingEdge(dut.clock)
    # use get_sim_time() to get the simulation time
    from cocotb.utils import get_sim_time

    dut._log.info(f"First Layer Done in {get_sim_time('us'):.4f} us")
    await RisingEdge(dut.clock)

    # Retrieve and process DUT output
    gotten_output = dut.r_data_conv2d_1_resized.value
    gotten_output = torch.tensor(
        np.array(convert_output_to_int(gotten_output)), dtype=torch.int32
    )

    # Generate report for the first layer
    generate_report(
        generics,
        image,
        output_first_layer_silu,
        output_first_layer_hs,
        gotten_output,
        doit=True,
    )

    # Continue the test
    output_second_layer_silu = extracted_model.forward_second_layer(
        image.unsqueeze(0)
    ).int()[0]
    output_second_layer_hs = extracted_model.forward_second_layer_approximate(
        image.unsqueeze(0)
    ).int()[0]

    # Wait until the data is valid in DUT's output
    while dut.o_data_valid.value != 1:
        await RisingEdge(dut.clock)

    dut._log.info(f"Second Layer Done in {get_sim_time('us'):.4f} us")
    await RisingEdge(dut.clock)

    # Retrieve and process DUT output
    gotten_output = dut.o_data.value
    gotten_output = torch.tensor(
        np.array(convert_output_to_int(gotten_output)), dtype=torch.int32
    )

    output_first_layer_silu = output_first_layer_silu.float()

    # Generate report for the second layer
    generate_report(
        generics,
        output_first_layer_silu[0],
        output_second_layer_silu,
        output_second_layer_hs,
        gotten_output,
    )
