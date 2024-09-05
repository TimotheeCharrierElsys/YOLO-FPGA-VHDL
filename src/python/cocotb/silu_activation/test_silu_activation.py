import sys
from random import randint

import cocotb
import numpy as np
import plotly.graph_objects as go
from cocotb.triggers import RisingEdge
from plotly.subplots import make_subplots
from tabulate import tabulate

# # Adjust the system path to include the parent directory for imports
sys.path.insert(1, "../")
from utils import reset_dut, setup_clock

# Constants
CLOCK_PERIOD_NS = 10


def get_generics(dut):
    """
    Retrieve the generic parameters from the DUT.
    """
    return {
        "BITWIDTH": dut.BITWIDTH.value,
        "DATA_SCALE_FACTOR": dut.DATA_SCALE_FACTOR.value,
    }


def log_generics(dut):
    """
    Log the generic parameters from the DUT in a table format.
    """
    generics = get_generics(dut)
    table = tabulate(generics.items(), headers=["Parameter", "Value"], tablefmt="grid")
    dut._log.info(f"Running with generics:\n{table}")


def relu6(x, data_scale_factor):
    """
    Computes the ReLU6 activation function.

    The ReLU6 function is a variation of the ReLU (Rectified Linear Unit) function,
    which clips the input values to the range [0, 6 * 2^data_scale_factor].

    Parameters:
    - x: Input array or value to apply the ReLU6 function to.
    - data_scale_factor: An integer scale factor applied to the upper bound.

    Returns:
    - The result of applying the ReLU6 function to the input `x`, where the output
      is clipped between 0 and 6 * 2^data_scale_factor.
    """
    return np.minimum(np.maximum(x, 0), 6 * 2**data_scale_factor)


def hardswish(x, data_scale_factor):
    """
    Computes the HardSwish activation function.

    The HardSwish function is a computationally efficient approximation of the
    Swish activation function, often used in neural networks. It combines the
    input with the ReLU6 activation and scales it accordingly.

    Parameters:
    - x: Input array or value to apply the HardSwish function to.
    - data_scale_factor: An integer scale factor that influences the behavior of both
      the ReLU6 and the final scaling.

    Returns:
    - The result of applying the HardSwish function to the input `x`, where the
      output is computed as x * relu6(x + 3 * 2^data_scale_factor, 2^data_scale_factor) / (6 * 2^data_scale_factor).
    """
    return (
        x
        * relu6(x + 3 * 2**data_scale_factor, data_scale_factor)
        / (6 * 2**data_scale_factor)
    )


def silu(x, data_scale_factor):
    """
    Computes the Sigmoid Linear Unit (SiLU) activation function.

    The SiLU function, also known as the Swish function, is defined as x / (1 + exp(-x)).
    It is similar to the Sigmoid function but with a linear component, which makes it
    more useful in certain machine learning applications.

    Parameters:
    - x: Input array or value to apply the SiLU function to.
    - data_scale_factor: An integer scale factor that is applied to the result of the SiLU function.

    Returns:
    - The result of applying the SiLU function to the input `x`, scaled by 2^data_scale_factor.
    """
    return x / (1 + np.exp(-x)) * 2**data_scale_factor


async def initialize_dut(dut, generics):
    """
    Initialize the DUT with default values.
    """
    await setup_clock(dut, CLOCK_PERIOD_NS)

    # Set initial values
    dut.i_sys_enable.value = 0
    dut.i_data.value = 0


@cocotb.test()
async def async_reset_test(dut):
    """
    Test the DUT's behavior during reset.
    Verifies that the output is correctly reset and remains stable.
    """
    generics = get_generics(dut)
    log_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)  # Assert and deassert reset signal

    # After reset, the output should be zero
    assert dut.o_data.value == 0, "DUT output was not reset correctly"
    dut._log.info("Reset test passed.")


@cocotb.test()
async def test_interval(dut):
    """
    Test the DUT's behavior on the entire interval.
    Verifies that the output is correct and checks the average error.
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)  # Assert and deassert reset signal

    # After reset, the output should be zero
    assert dut.o_data.value == 0, "DUT output was not reset correctly"
    dut._log.info("Reset test passed.")

    bitwidth = generics["BITWIDTH"]
    min_val = -(2 ** (bitwidth - 1))
    max_val = 2 ** (bitwidth - 1) - 1
    interval = np.arange(
        min_val, max_val + 1, 1
    )  # Ensure the entire interval is covered

    # Enable DUT
    dut.i_sys_enable.value = 1
    await RisingEdge(dut.clock)

    output_array = []
    expected_hardswish_array = []
    expected_silu_array = []
    error_hardswish_array = []
    error_silu_array = []

    # Loop through the entire interval and compare the values
    for value in interval:
        # Set the DUT current value and compute expected
        dut.i_data.value = int(value)
        await RisingEdge(dut.clock)

        expected_hardswish = hardswish(value, generics["DATA_SCALE_FACTOR"])
        expected_silu = silu(
            value / 2 ** generics["DATA_SCALE_FACTOR"], generics["DATA_SCALE_FACTOR"]
        )

        output_value = int(dut.o_data.value.signed_integer)

        output_array.append(output_value)
        expected_hardswish_array.append(expected_hardswish)
        expected_silu_array.append(expected_silu)

        error_hardswish_array.append(np.abs(output_value - expected_hardswish))
        error_silu_array.append(np.abs(output_value - expected_silu))

    avg_error_hardswish = np.average(error_hardswish_array)
    avg_error_silu = np.average(error_silu_array)
    dut._log.info(
        f"Hardswish error: {avg_error_hardswish:.6f}, SiLU error: {avg_error_silu:.6f}"
    )

    fig = make_subplots(
        rows=2,
        cols=1,
        shared_xaxes=True,
        vertical_spacing=0.1,
        subplot_titles=("Function Outputs", "Logarithmic Absolute Errors"),
    )

    # Add traces for expected Hardswish, SiLU, and DUT output
    traceHW = go.Scatter(
        x=interval,
        y=expected_hardswish_array,
        mode="lines",
        name="Expected Hardswish",
        line=dict(width=2, color="#1f77b4"),
        legendgroup="group1",
    )
    traceSILU = go.Scatter(
        x=interval,
        y=expected_silu_array,
        mode="lines",
        name="Expected SiLU",
        line=dict(width=2, color="#ff7f0e"),
        legendgroup="group1",
    )
    traceOutput = go.Scatter(
        x=interval,
        y=output_array,
        mode="lines",
        name="DUT Output",
        line=dict(width=2, color="#2ca02c", dash="dot"),
        legendgroup="group1",
    )

    # Add traces to the first subplot
    fig.add_trace(traceHW, row=1, col=1)
    fig.add_trace(traceSILU, row=1, col=1)
    fig.add_trace(traceOutput, row=1, col=1)

    # Add traces for the errors
    traceErrorHW = go.Scatter(
        x=interval,
        y=error_hardswish_array,
        mode="lines",
        name="Error Hardswish-DUT",
        line=dict(width=2, color="#d62728"),
        legendgroup="group2",
    )
    traceErrorSILU = go.Scatter(
        x=interval,
        y=error_silu_array,
        mode="lines",
        name="Error SiLU-DUT",
        line=dict(width=2, color="#9467bd"),
        legendgroup="group2",
    )

    # Add traces to the second subplot
    fig.add_trace(traceErrorHW, row=2, col=1)
    fig.add_trace(traceErrorSILU, row=2, col=1)

    # Update layout
    fig.update_layout(
        title={
            "text": "Comparison of Hardswish and SiLU Functions with DUT Output and Errors",
            "font": {
                "size": 20,
                "family": "Cambria, sans-serif",
                "color": "black",
            },
        },
        xaxis_title={
            "text": "Input Value",
            "font": {"family": "Cambria, sans-serif", "size": 16, "color": "black"},
        },
        yaxis_title={
            "text": "Function Output",
            "font": {"family": "Cambria, sans-serif", "size": 16, "color": "black"},
        },
        legend=dict(
            x=0.01,
            y=0.98,
            traceorder="normal",
            font=dict(family="Cambria, sans-serif", size=12, color="black"),
            bgcolor="rgba(255, 255, 255, 0.8)",
            bordercolor="black",
            borderwidth=1,
        ),
        plot_bgcolor="white",
        hovermode="x unified",
        margin=dict(l=60, r=40, t=80, b=60),
        autosize=False,
        width=900,
        height=650,
        xaxis_showspikes=True,
    )

    # Update x-axis and y-axis grid and format
    fig.update_xaxes(
        showgrid=True,
        gridwidth=1,
        gridcolor="LightGray",
        tickfont=dict(family="Cambria, sans-serif", size=12, color="black"),
        exponentformat="power",
        zeroline=True,
        zerolinewidth=1,
        zerolinecolor="LightGray",
    )
    fig.update_yaxes(
        showgrid=True,
        gridwidth=1,
        gridcolor="LightGray",
        tickfont=dict(family="Cambria, sans-serif", size=12, color="black"),
        exponentformat="power",
    )

    # Update the layout for the second subplot (Errors) with log scale
    fig.update_yaxes(title_text="Absolute Error (Log Scale)", type="log", row=2, col=1)

    # Make x-axis visible on the first subplot
    fig.update_xaxes(visible=True, row=1, col=1)

    # Show the figure
    fig.write_html("interval_plot.html")
    fig.show()
