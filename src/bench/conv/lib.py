# Description: Library functions for the convolution testbench.

from sys import path

import plotly.graph_objects as go
import torch
from torch.nn.functional import conv2d
from torchvision import transforms

path.insert(1, "../")
from utils import (
    hardswish,
)


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
        conv2d_layer.conv2d_layer_inst.conv2d_result.value.signed_integer
        for conv2d_layer in dut.GEN_CONV2D_LAYERS
    ][::-1]

    for c, (expected, actual) in enumerate(zip(expected_output, output)):
        expected_value = expected[s_current_row_win][s_current_col_win]

        if min_value <= expected_value <= max_value:
            assert (
                expected_value == actual
            ), f"Mismatch at channel {c}: expected {expected_value}, got {actual} for Conv2D"


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
        bn_layer.conv2d_layer_inst.batchnorm2d_layer_inst.r_data_to_silu.value.signed_integer
        for bn_layer in dut.GEN_CONV2D_LAYERS
    ][::-1]

    for c, (expected, actual) in enumerate(zip(expected_output, output)):
        expected_value = expected[s_current_row_win][s_current_col_win]

        if min_value <= expected_value <= max_value:
            assert (
                expected_value == actual
            ), f"Mismatch at channel {c}: expected {expected_value}, got {actual} for BatchNorm2D"


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
            ), f"Mismatch at channel {c}: expected {expected_value}, got {actual} for SiLU"


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
