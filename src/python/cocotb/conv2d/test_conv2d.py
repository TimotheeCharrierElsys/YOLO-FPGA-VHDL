import sys
import random
import cocotb
import matplotlib.pyplot as plt
import numpy as np
import torch
from cocotb.triggers import RisingEdge
from tabulate import tabulate
from torch.nn.functional import conv2d

# # Adjust the system path to include the parent directory for imports
sys.path.insert(1, "../")
from utils import (
    assert_reset_state,
    print_progress_bar,
    reset_dut,
    setup_clock,
    sys_enable_dut,
    tensor_init,
    vector_init,
    volume_init,
)

# Constants
CLOCK_PERIOD_NS = 10


def get_generics(dut):
    """
    Retrieve the generic parameters from the DUT.
    """
    return {
        "DATA_SCALE_FACTOR": dut.DATA_SCALE_FACTOR.value,
        "USE_MAC_ARCH": dut.USE_MAC_ARCH.value,
        "DO_PIPELINE": dut.DO_PIPELINE.value,
        "BITWIDTH": dut.BITWIDTH.value,
        "INPUT_SIZE": dut.INPUT_SIZE.value,
        "INPUT_CHANNELS": dut.INPUT_CHANNELS.value,
        "KERNEL_SIZE": dut.KERNEL_SIZE.value,
        "OUTPUT_CHANNELS": dut.OUTPUT_CHANNELS.value,
        "PADDING": dut.PADDING.value,
        "STRIDE": dut.STRIDE.value,
    }


def get_random_dsp_filters(generics):
    filters = {
        "filter_identity": [
            [[0, 0, 0], [0, 1, 0], [0, 0, 0]]
            for _ in range(generics["OUTPUT_CHANNELS"])
        ],
        "filter_ridge": [
            [[0, -1, 0], [-1, 4, -1], [0, -1, 0]]
            for _ in range(generics["OUTPUT_CHANNELS"])
        ],
        "filter_edge": [
            [[-1, -1, -1], [-1, 8, -1], [-1, -1, -1]]
            for _ in range(generics["OUTPUT_CHANNELS"])
        ],
        "filter_sharp": [
            [[0, -1, 0], [-1, 5, -1], [0, -1, 0]]
            for _ in range(generics["OUTPUT_CHANNELS"])
        ],
        "filter_emboss": [
            [[-2, -1, 0], [-1, 1, 1], [0, 1, 2]]
            for _ in range(generics["OUTPUT_CHANNELS"])
        ],
        "filter_sobel_x": [
            [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]]
            for _ in range(generics["OUTPUT_CHANNELS"])
        ],
        "filter_sobel_y": [
            [[-1, -2, -1], [0, 0, 0], [1, 2, 1]]
            for _ in range(generics["OUTPUT_CHANNELS"])
        ],
        "filter_prewitt_x": [
            [[-1, 0, 1], [-1, 0, 1], [-1, 0, 1]]
            for _ in range(generics["OUTPUT_CHANNELS"])
        ],
        "filter_prewitt_y": [
            [[-1, -1, -1], [0, 0, 0], [1, 1, 1]]
            for _ in range(generics["OUTPUT_CHANNELS"])
        ],
        "filter_laplacian": [
            [[0, 1, 0], [1, -4, 1], [0, 1, 0]]
            for _ in range(generics["OUTPUT_CHANNELS"])
        ],
        "filter_laplacian_diag": [
            [[1, 1, 1], [1, -8, 1], [1, 1, 1]]
            for _ in range(generics["OUTPUT_CHANNELS"])
        ],
        "filter_test": [
            [[-10, 2, -9], [4, 7, -7], [-4, 9, -4]]
            for _ in range(generics["OUTPUT_CHANNELS"])
        ],
    }
    if generics["OUTPUT_CHANNELS"] > len(filters):
        raise ValueError("N cannot be greater than the number of available filters")

    # Extract the filter keys
    filter_keys = list(filters.keys())

    # Randomly select N keys
    selected_keys = random.sample(filter_keys, generics["OUTPUT_CHANNELS"])

    # Create a list of the selected filters
    selected_filters_list = [filters[key] for key in selected_keys]

    return selected_filters_list


def log_generics(dut):
    """
    Log the generic parameters from the DUT in a table format.
    """
    generics = get_generics(dut)
    table = tabulate(generics.items(), headers=["Parameter", "Value"], tablefmt="grid")
    dut._log.info(f"Running with generics:\n{table}")


def calculate_output_dimensions(generics):
    """
    Calculate the output height and width based on the input dimensions and parameters.
    """
    h_out = w_out = (
        generics["INPUT_SIZE"] + 2 * generics["PADDING"] - generics["KERNEL_SIZE"]
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


def convert_output_to_int(output):
    """
    Convert the output tensor to integers based on the bitwidth.
    """
    for i in range(len(output[0])):
        for j in range(len(output[0][0])):
            for k in range(len(output)):
                output[k][i][j] = output[k][i][j].signed_integer


async def initialize_dut(dut, generics):
    """
    Initialize the DUT with default values.
    """
    await setup_clock(dut)
    dut.i_sys_enable.value = 0
    dut.i_data.value = volume_init(
        generics["INPUT_CHANNELS"],
        generics["INPUT_SIZE"],
        generics["INPUT_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_data_valid.value = 0
    dut.i_kernel.value = tensor_init(
        generics["OUTPUT_CHANNELS"],
        generics["INPUT_CHANNELS"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_bias.value = vector_init(generics["OUTPUT_CHANNELS"])


@cocotb.test()
async def async_reset_test(dut):
    """
    Test the DUT's behavior during reset.
    """
    generics = get_generics(dut)
    log_generics(dut)

    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS"], h_out, w_out)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    await assert_reset_state(dut, output_zeros)
    dut._log.info("Reset test passed.")


@cocotb.test()
async def computation_test(dut):
    """
    Test the DUT's behavior during normal computation.
    """
    generics = get_generics(dut)
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS"], h_out, w_out)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    await assert_reset_state(dut, output_zeros)

    await sys_enable_dut(dut)
    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0

    while dut.o_data_valid.value != 1:
        await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)
    await assert_reset_state(dut, output_zeros)
    await reset_dut(dut)
    await assert_reset_state(dut, output_zeros)

    total_iterations = 5
    for i in range(total_iterations):
        print_progress_bar(
            i + 1, total_iterations, prefix="Progress:", suffix="Complete", length=50
        )

        # Generate random values
        random_input = volume_init(
            generics["INPUT_CHANNELS"],
            generics["INPUT_SIZE"],
            generics["INPUT_SIZE"],
            bitwidth=generics["BITWIDTH"],
            use_random=True,
        )
        random_kernels = tensor_init(
            generics["OUTPUT_CHANNELS"],
            generics["INPUT_CHANNELS"],
            generics["KERNEL_SIZE"],
            bitwidth=generics["BITWIDTH"],
            use_random=True,
        )
        random_bias = vector_init(
            generics["OUTPUT_CHANNELS"], bitwidth=generics["BITWIDTH"], use_random=True
        )

        # Compute the expected output
        expected_output = forward_conv2d(
            generics, random_input, random_kernels, random_bias
        )

        # Send the input data to the DUT
        dut.i_data.value = random_input
        dut.i_kernel.value = random_kernels
        dut.i_bias.value = random_bias

        # Enable the DUT
        dut.i_data_valid.value = 1
        await RisingEdge(dut.clock)
        dut.i_data_valid.value = 0

        # Wait for the DUT to process the data
        while dut.o_data_valid.value != 1:
            await RisingEdge(dut.clock)

        await RisingEdge(dut.clock)
        gotten_output = dut.o_data.value

        convert_output_to_int(gotten_output)
        gotten_output = np.array(gotten_output)

        assert np.allclose(
            gotten_output, expected_output
        ), "DUT output did not match expected output after computation"

        # Reset the DUT
        await reset_dut(dut, verbose=False)
        await assert_reset_state(dut, output_zeros)

    dut._log.info("\nRandom Computation test passed.")


import plotly.graph_objects as go


@cocotb.test()
async def image_processing(dut):
    """
    Test the DUT's behavior during normal computation.
    """
    generics = get_generics(dut)
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS"], h_out, w_out)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    await assert_reset_state(dut, output_zeros)

    await sys_enable_dut(dut)
    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0

    while dut.o_data_valid.value != 1:
        await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)
    await assert_reset_state(dut, output_zeros)
    await reset_dut(dut)
    await assert_reset_state(dut, output_zeros)

    # Load the Input Image
    image = plt.imread(r"./wolf.jpg")
    image_transposed = image.transpose(2, 0, 1)
    image_tensor = torch.tensor(image_transposed, dtype=torch.int64)
    image_array = image_tensor.numpy()
    image_list = image_array.tolist()

    random_kernels = get_random_dsp_filters(generics)

    random_bias = vector_init(
        generics["OUTPUT_CHANNELS"], bitwidth=generics["BITWIDTH"], use_random=True
    )

    # Compute the expected output
    expected_output = forward_conv2d(generics, image_list, random_kernels, random_bias)

    # Send the input data to the DUT
    dut.i_data.value = image_list
    dut.i_kernel.value = random_kernels
    dut.i_bias.value = random_bias

    # Enable the DUT
    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0

    # Wait for the DUT to process the data
    while dut.o_data_valid.value != 1:
        await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)
    gotten_output = dut.o_data.value

    convert_output_to_int(gotten_output)
    gotten_output = np.array(gotten_output)
    expected_output = np.array(expected_output)

    abs_diff = np.abs(gotten_output - expected_output)

    for i in range(generics["OUTPUT_CHANNELS"]):
        # Common font settings
        common_font = {"family": "Arial, sans-serif", "color": "black"}

        error = abs_diff[i]

        # Compute min/max/avg
        error_min = np.min(error)
        error_max = np.max(error)
        error_avg = np.mean(error)  # Renamed for clarity

        # Create figure
        fig = go.Figure()

        # Add surface trace with a custom hovertemplate
        fig.add_trace(
            go.Surface(
                z=error,
                colorbar=dict(
                    title="Error Values",
                    tickvals=[error_min, error_avg, error_max],
                    ticktext=[
                        f"Min: {error_min:.2f}",
                        f"Avg: {error_avg:.2f}",
                        f"Max: {error_max:.2f}",
                    ],
                    title_font=common_font,
                    tickfont=common_font,
                ),
                colorscale="Viridis",
                cmin=error_min,
                cmax=error_max,
                hovertemplate="<b>X</b>: %{x}<br>"
                + "<b>Y</b>: %{y}<br>"
                + "<b>Error</b>: %{z:.2f}<br>"
                + "<extra></extra>",
            )
        )

        # Update plot sizing and layout
        fig.update_layout(
            width=800,
            height=800,
            autosize=False,
            margin=dict(t=150, b=0, l=0, r=0),
            template="plotly_white",
            title=dict(
                text=(
                    f"<b>Heatmap Absolute Error for Conv2d</b><br>"
                    "<span style='font-size: 14px;'>"
                    f"Bias={random_bias[i]}<br>"
                    f"Conv2d Parameters: Stride={generics["STRIDE"]}, Padding={
                        generics["PADDING"]}, "
                    f"Kernel Size={generics["KERNEL_SIZE"]}"
                    "</span>"
                ),
                font=common_font,
                x=0.0,
                xanchor="left",
                y=0.95,
                yanchor="top",
            ),
        )

        # Update 3D scene options
        fig.update_scenes(aspectratio=dict(x=1, y=1, z=0.7), aspectmode="manual")

        # Define annotations with common font
        annotations = [
            dict(
                text="Trace type:",
                showarrow=False,
                x=0.0,
                y=1.085,
                yref="paper",
                align="left",
                visible=True,
                font=common_font,
            )
        ]

        # Add dropdown with callback to toggle annotations visibility
        fig.update_layout(
            updatemenus=[
                dict(
                    buttons=[
                        dict(
                            args=[{"type": "surface"}, {"annotations": annotations}],
                            label="3D Surface",
                            method="update",
                        ),
                        dict(
                            args=[{"type": "heatmap"}, {"annotations": []}],
                            label="Heatmap",
                            method="update",
                        ),
                    ],
                    direction="down",
                    pad={"r": 10, "t": 10},
                    showactive=True,
                    x=0.0,
                    xanchor="left",
                    y=1.1,
                    yanchor="top",
                ),
            ]
        )

        # Show and save the figure
        fig.show()
