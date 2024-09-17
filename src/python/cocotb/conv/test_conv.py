import random
import sys

import cocotb
import matplotlib.pyplot as plt
import numpy as np
import torch
from cocotb.triggers import RisingEdge
from tabulate import tabulate
from torch.nn.functional import conv2d

sys.path.insert(1, "../")
from utils import (
    assert_reset_state,
    hardswish,
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
        "INPUT_CHANNELS": dut.INPUT_CHANNELS.value,
        "KERNEL_SIZE": dut.KERNEL_SIZE.value,
        "OUTPUT_CHANNELS": dut.OUTPUT_CHANNELS.value,
        "PADDING": dut.PADDING.value,
        "STRIDE": dut.STRIDE.value,
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
    h_out = w_out = (
        generics["INPUT_SIZE"]
        + 2 * generics["PADDING"]
        - generics["KERNEL_SIZE"]
    ) // generics["STRIDE"] + 1
    return h_out, w_out


def forward_conv2d(generics, x, kernels, bias):
    """
    Perform a forward pass of 2D convolution.
    """
    x_torch = torch.tensor(x)
    kernels_torch = torch.tensor(kernels)
    bias_torch = torch.tensor(bias)

    output_torch: torch.Tensor = conv2d(
        x_torch,
        kernels_torch,
        bias_torch,
        stride=generics["STRIDE"],
        padding=generics["PADDING"],
    )

    return output_torch.detach().numpy()


def forward_bn(x, mean, weights, bias):
    """
    Perform a forward pass of 2D batch normalization.
    """
    x_torch = torch.tensor(x)
    mean_torch = torch.tensor(mean)
    weights_torch = torch.tensor(weights)
    bias_torch = torch.tensor(bias)

    output_torch = torch.zeros_like(x_torch)

    for c in range(x_torch.shape[0]):
        output_torch[c] = (x_torch[c] - mean_torch[c]) * weights_torch[
            c
        ] + bias_torch[c]

    return output_torch.detach().numpy()


def convert_output_to_int(output):
    """
    Convert the output tensor to integers based on the bitwidth.
    """
    for i in range(len(output[0])):
        for j in range(len(output[0][0])):
            for k in range(len(output)):
                output[k][i][j] = output[k][i][j].signed_integer

    return output


def forward_silu(x, generics):
    """Apply the activation function."""
    return hardswish(x, generics["DATA_SCALE_FACTOR"])


def assert_conv2d_result(dut, generics, expected_output):
    """
    Assert the convolution result from the DUT against the expected output.

    Args:
        dut: The device under test.
        generics: A dictionary containing the generic parameters.
        expected_output: The expected output from the convolution operation.
    """
    s_current_row_win = dut.s_current_row_win.value
    s_current_col_win = dut.s_current_col_win.value

    min_value = -(2 ** (generics["BITWIDTH"] - 1))
    max_value = 2 ** (generics["BITWIDTH"] - 1) - 1

    output = [
        conv2d_layer.conv2d_layer_mac_inst.conv2d_result.value.signed_integer
        for conv2d_layer in dut.GEN_CONV2D_LAYERS
    ][::-1]

    for c, (expected, actual) in enumerate(zip(expected_output, output)):
        expected_value = expected[s_current_row_win][s_current_col_win]

        if min_value <= expected_value <= max_value:
            assert (
                expected_value == actual
            ), f"Mismatch at channel {c}: expected {expected_value}, got {actual}"


def assert_bn_result(dut, generics, expected_output):
    """
    Assert the batch normalization result from the DUT against the expected output.

    Args:
        dut: The device under test.
        generics: A dictionary containing the generic parameters.
        expected_output: The expected output from the batch normalization operation.
    """
    s_current_row_win = dut.s_current_row_win.value
    s_current_col_win = dut.s_current_col_win.value

    min_value = -(2 ** (generics["BITWIDTH"] - 1))
    max_value = 2 ** (generics["BITWIDTH"] - 1) - 1

    output = [
        bn_layer.conv2d_layer_mac_inst.batchnorm2d_layer_inst.r_data_to_silu.value.signed_integer
        for bn_layer in dut.GEN_CONV2D_LAYERS
    ][::-1]

    for c, (expected, actual) in enumerate(zip(expected_output, output)):
        expected_value = expected[s_current_row_win][s_current_col_win]

        if min_value <= expected_value <= max_value:
            assert (
                expected_value == actual
            ), f"Mismatch at channel {c}: expected {expected_value}, got {actual}"


def assert_silu_result(dut, generics, expected_output):
    """
    Assert the SiLU result from the DUT against the expected output

    Args:
        dut: The device under test.
        generics: A dictionary containing the generic parameters.
        expected_output: The expected output from the silu activation operation.
    """

    s_current_row_win = dut.s_current_row_win.value
    s_current_col_win = dut.s_current_col_win.value

    min_value = -(2 ** (generics["BITWIDTH"] - 1))
    max_value = 2 ** (generics["BITWIDTH"] - 1) - 1

    output = [out.value.signed_integer for out in dut.s_result][::-1]

    for c, (expected, actual) in enumerate(zip(expected_output, output)):
        expected_value = expected[s_current_row_win][s_current_col_win]

        if min_value <= expected_value <= max_value:
            assert (
                expected_value == actual
            ), f"Mismatch at channel {c}: expected {expected_value}, got {actual}"


async def initialize_dut(dut, generics):
    """
    Initialize the DUT with default values.
    """
    await setup_clock(dut)
    dut.i_sys_enable.value = 0
    dut.i_data_conv2d.value = volume_init(
        generics["INPUT_CHANNELS"],
        generics["INPUT_SIZE"],
        generics["INPUT_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_data_valid.value = 0
    dut.i_kernel_conv2d.value = tensor_init(
        generics["OUTPUT_CHANNELS"],
        generics["INPUT_CHANNELS"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_bias_conv2d.value = vector_init(generics["OUTPUT_CHANNELS"])
    dut.i_bias_bn.value = vector_init(generics["OUTPUT_CHANNELS"])
    dut.i_mean_bn.value = vector_init(generics["OUTPUT_CHANNELS"])
    dut.i_weight_bn.value = vector_init(generics["OUTPUT_CHANNELS"])


@cocotb.test()
async def async_reset_test(dut):
    """
    Test the DUT's behavior during reset.
    """
    generics = get_generics(dut)
    log_generics(dut)

    # Compute output dimensions
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS"], h_out, w_out)

    await initialize_dut(dut, generics)
    await reset_dut(dut)

    # Check if output is a tensor filled with zeros
    await assert_reset_state(dut, output_zeros)


# @cocotb.test()
async def random_test(dut):
    """
    Test the DUT's behavior with random inputs.
    """
    generics = get_generics(dut)

    # Compute output dimensions
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS"], h_out, w_out)

    await initialize_dut(dut, generics)
    await reset_dut(dut)

    # Check if output is a tensor filled with zeros
    await assert_reset_state(dut, output_zeros)

    # Generate random inputs and send them to DUT
    i_data_conv2d = volume_init(
        generics["INPUT_CHANNELS"],
        generics["INPUT_SIZE"],
        generics["INPUT_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    dut.i_data_conv2d.value = i_data_conv2d

    i_kernel_conv2d = tensor_init(
        generics["OUTPUT_CHANNELS"],
        generics["INPUT_CHANNELS"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    dut.i_kernel_conv2d.value = i_kernel_conv2d

    i_bias_conv2d = vector_init(
        generics["OUTPUT_CHANNELS"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    i_bias_bn = dut.i_weight_bn.value = vector_init(
        generics["OUTPUT_CHANNELS"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    i_mean_bn = dut.i_weight_bn.value = vector_init(
        generics["OUTPUT_CHANNELS"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    i_weight_bn = dut.i_weight_bn.value = vector_init(
        generics["OUTPUT_CHANNELS"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )

    dut.i_bias_conv2d.value = i_bias_conv2d
    dut.i_bias_bn.value = i_bias_bn
    dut.i_mean_bn.value = i_mean_bn
    dut.i_weight_bn.value = i_weight_bn

    # Enable System
    await sys_enable_dut(dut)
    await RisingEdge(dut.clock)

    # Set data valid flag for one clock cycle
    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0
    await RisingEdge(dut.clock)

    # Pre-compute expected output for each layer
    conv2d_expected_output = forward_conv2d(
        generics, i_data_conv2d, i_kernel_conv2d, i_bias_conv2d
    )
    bn_expected_output = forward_bn(
        conv2d_expected_output, i_mean_bn, i_weight_bn, i_bias_bn
    )
    silu_expected_output = forward_silu(bn_expected_output, generics)

    # Wait for the Conv to finish
    while dut.o_data_valid.value != 1:
        # Assert current Conv2d output
        if dut.s_valid_bn.value == 1:
            assert_conv2d_result(dut, generics, conv2d_expected_output)

        # Assert current Batchnorm2d and SiLU
        elif dut.s_conv2d_done.value == 1:
            assert_bn_result(dut, generics, bn_expected_output)
            assert_silu_result(dut, generics, silu_expected_output)

        await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)

    # Get the output from the DUT
    expected_output = dut.o_data.value
    convert_output_to_int(expected_output)

    expected_output = np.array(expected_output)
    silu_expected_output = np.array(silu_expected_output)
    assert np.array_equal(
        expected_output, silu_expected_output
    ), "Output mismatch in SiLU phase."


def check_generics(generics):
    """
    Validates the values in the `generics` dictionary for a neural network configuration.

    The function checks that the input size, input channels, output channels, kernel size,
    stride, and padding match the expected values. The expected values are:
        - INPUT_SIZE: 28
        - INPUT_CHANNELS: 1
        - OUTPUT_CHANNELS: 32
        - KERNEL_SIZE: 3
        - STRIDE: 2
        - PADDING: 1

    Parameters:
    ----------
    generics : dict
        A dictionary containing the generics configuration with the following keys:
        - "INPUT_SIZE" : int
            Expected value: 28
        - "INPUT_CHANNELS" : int
            Expected value: 1
        - "OUTPUT_CHANNELS" : int
            Expected value: 32
        - "KERNEL_SIZE" : int
            Expected value: 3
        - "STRIDE" : int
            Expected value: 2
        - "PADDING" : int
            Expected value: 1

    Raises:
    ------
    ValueError:
        If any of the values in `generics` do not match the expected values. The specific
        error message will indicate which key has the invalid value and what the current
        value is.
    """
    input_width = generics["INPUT_SIZE"]
    input_channels = generics["INPUT_CHANNELS"]
    output_channels = generics["OUTPUT_CHANNELS"]
    kernel_size = generics["KERNEL_SIZE"]
    stride = generics["STRIDE"]
    padding = generics["PADDING"]

    if input_width != 28:
        raise ValueError(
            f"Invalid value for INPUT_SIZE. It should be 28, currently {input_width}"
        )
    elif input_channels != 1:
        raise ValueError(
            f"Invalid value for INPUT_CHANNELS. It should be 1, currently {input_channels}"
        )
    elif output_channels != 32:
        raise ValueError(
            f"Invalid value for OUTPUT_CHANNELS. It should be 32, currently {output_channels}"
        )
    elif kernel_size != 3:
        raise ValueError(
            f"Invalid value for KERNEL_SIZE. It should be 3, currently {kernel_size}"
        )
    elif stride != 2:
        raise ValueError(
            f"Invalid value for STRIDE. It should be 2, currently {stride}"
        )
    elif padding != 1:
        raise ValueError(
            f"Invalid value for PADDING. It should be 1, currently {padding}"
        )


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


def generics_to_string(generics: dict):
    """
    Converts the generics dictionary to a string formatted for easy display.

    Parameters:
    ----------
        generics (dict): Configuration dictionary.

    Returns:
    -------
        str: Generics string.
    """
    generics_str = f"DATA_SCALE_FACTOR: {generics['DATA_SCALE_FACTOR']}, BITWIDTH: {generics['BITWIDTH']}, INPUT_SIZE: {generics['INPUT_SIZE']} INPUT_CHANNELS: {generics['INPUT_CHANNELS']}<br>"
    generics_str += f"OUTPUT_CHANNELS: {generics['OUTPUT_CHANNELS']}, KERNEL_SIZE: {generics['KERNEL_SIZE']}, STRIDE: {generics['STRIDE']}, PADDING: {generics['PADDING']}"

    return generics_str


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


def generate_report(generics, input, output_silu, output_hs, gotten_output):
    import plotly.graph_objects as go
    import torch
    from torchvision import transforms

    # Flip y axis for a tensor (idk why, plotly is doing weird stuff)
    output_hs = torch.flip(output_hs, [1])
    output_silu = torch.flip(output_silu, [1])
    gotten_output = torch.flip(gotten_output, [1])
    input = torch.flip(input, [1])

    # Apply inverse transformation to the input
    inverse_transform = transforms.Compose(
        [
            transforms.Normalize(mean=[-0.1307 / 0.3081], std=[1 / 0.3081]),
            transforms.ToPILImage(),
        ]
    )

    original_image = inverse_transform(input)

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
        hovertemplate="(%{x}, %{y})<br>RGB Value: %{z}",
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
            colorbar=dict(title="Input Image"),
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


@cocotb.test()
async def mnist_test_first_layer(dut):
    """
    Test the DUT's first Conv layer behavior with random inputs from the MNIST dataset.
    """
    generics = get_generics(dut)
    check_generics(generics)

    # Load Dataset and Model
    model, test_loader = load_dataset(PYTORCH_PATH)

    # Compute output dimensions and initialize
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS"], h_out, w_out)

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
    i_kernel_conv2d, i_bias_conv2d, i_mean_bn, i_weight_bn, i_bias_bn = (
        preprocess_layer(generics, extracted_model.conv1, extracted_model.bn1)
    )

    # Preprocess input image
    i_data_conv2d = preprocess_input(generics, image)

    # Set DUT values for Conv2D and BatchNorm
    dut.i_data_conv2d.value = i_data_conv2d
    dut.i_kernel_conv2d.value = i_kernel_conv2d
    dut.i_bias_conv2d.value = i_bias_conv2d

    dut.i_bias_bn.value = i_bias_bn
    dut.i_mean_bn.value = i_mean_bn
    dut.i_weight_bn.value = i_weight_bn

    # Wait few clock cycles
    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)

    # Set i_data_valid
    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0
    await RisingEdge(dut.clock)

    # Wait until the data is valid in DUT's output
    while dut.o_data_valid.value != 1:
        await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)

    # Retrieve and process DUT output
    gotten_output = dut.o_data.value
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
    )
