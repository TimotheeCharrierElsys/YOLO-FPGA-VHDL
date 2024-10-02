import sys

import cocotb
import numpy as np
import plotly.graph_objects as go
from cocotb.triggers import RisingEdge
from plotly.subplots import make_subplots
from tabulate import tabulate

sys.path.insert(1, "../")
import warnings

from utils import reset_dut, setup_clock

warnings.filterwarnings("ignore", category=ResourceWarning)

# Constants
CLOCK_PERIOD_NS = 10


def get_generics(dut):
    """
    Retrieve the generic parameters from the DUT.

    Parameters
    ----------
    dut : object
        The device under test (DUT).

    Returns
    -------
    dict
        A dictionary containing the generic parameters.
    """
    return {
        "BITWIDTH": dut.BITWIDTH.value,
        "DATA_SCALE_FACTOR": dut.DATA_SCALE_FACTOR.value,
    }


def log_generics(dut):
    """
    Log the generic parameters from the DUT in a table format.

    Parameters
    ----------
    dut : object
        The device under test (DUT).
    """
    generics = get_generics(dut)
    table = tabulate(
        generics.items(), headers=["Parameter", "Value"], tablefmt="grid"
    )
    dut._log.info(f"Running with generics:\n{table}")


def relu6(x, data_scale_factor):
    """
    Computes the ReLU6 activation function.

    The ReLU6 function is a variation of the ReLU (Rectified Linear Unit) function,
    which clips the input values to the range [0, 6 * 2^data_scale_factor].

    Parameters
    ----------
    x : array-like
        Input array or value to apply the ReLU6 function to.
    data_scale_factor : int
        An integer scale factor applied to the upper bound.

    Returns
    -------
    array-like
        The result of applying the ReLU6 function to the input `x`, where the output
        is clipped between 0 and 6 * 2^data_scale_factor.
    """
    return np.minimum(np.maximum(x, 0), 6 * 2**data_scale_factor)


def hardswish(x, data_scale_factor):
    """
    Computes the HardSwish activation function.

    The HardSwish function is a computationally efficient approximation of the
    Swish activation function, often used in neural networks. It combines the
    input with the ReLU6 activation and scales it accordingly.

    Parameters
    ----------
    x : array-like
        Input array or value to apply the HardSwish function to.
    data_scale_factor : int
        An integer scale factor that influences the behavior of both
        the ReLU6 and the final scaling.

    Returns
    -------
    array-like
        The result of applying the HardSwish function to the input `x`, where the
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

    Parameters
    ----------
    x : array-like
        Input array or value to apply the SiLU function to.
    data_scale_factor : int
        An integer scale factor that is applied to the result of the SiLU function.

    Returns
    -------
    array-like
        The result of applying the SiLU function to the input `x`, scaled by 2^data_scale_factor.
    """
    return x / (1 + np.exp(-x)) * 2**data_scale_factor


async def initialize_dut(dut, generics):
    """
    Initialize the DUT with default values.

    Parameters
    ----------
    dut : object
        The device under test (DUT).
    generics : dict
        A dictionary containing the generic parameters.
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

    Parameters
    ----------
    dut : object
        The device under test (DUT).
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

    Parameters
    ----------
    dut : object
        The device under test (DUT).
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

    # Initialize arrays
    output_array = []
    expected_hardswish_array = []
    expected_silu_array = []
    error_hardswish_array = []
    error_silu_array = []

    # Loop through the entire interval and compare the values
    for value in interval:
        dut.i_data.value = int(value)
        await RisingEdge(dut.clock)

        expected_hardswish = hardswish(value, generics["DATA_SCALE_FACTOR"])
        expected_silu = silu(
            value / 2 ** generics["DATA_SCALE_FACTOR"],
            generics["DATA_SCALE_FACTOR"],
        )
        await RisingEdge(dut.clock)
        output_value = dut.o_data.value.signed_integer

        output_array.append(output_value)
        expected_hardswish_array.append(expected_hardswish)
        expected_silu_array.append(expected_silu)

        error_hardswish_array.append(np.abs(output_value - expected_hardswish))
        error_silu_array.append(np.abs(output_value - expected_silu))

    # Compute statistics for Hardswish
    stats_hardswish = {
        "Avg Error": np.average(error_hardswish_array),
        "Max Error": np.max(error_hardswish_array),
        "Min Error": np.min(error_hardswish_array),
        "Std Dev Error": np.std(error_hardswish_array),
        "Median Error": np.median(error_hardswish_array),
        "Total Error": np.sum(error_hardswish_array),
    }

    # Compute statistics for SiLU
    stats_silu = {
        "Avg Error": np.average(error_silu_array),
        "Max Error": np.max(error_silu_array),
        "Min Error": np.min(error_silu_array),
        "Std Dev Error": np.std(error_silu_array),
        "Median Error": np.median(error_silu_array),
        "Total Error": np.sum(error_silu_array),
    }

    # Log and print statistics using tabulate
    table = [
        ["Avg Error", stats_hardswish["Avg Error"], stats_silu["Avg Error"]],
        ["Max Error", stats_hardswish["Max Error"], stats_silu["Max Error"]],
        ["Min Error", stats_hardswish["Min Error"], stats_silu["Min Error"]],
        [
            "Std Dev Error",
            stats_hardswish["Std Dev Error"],
            stats_silu["Std Dev Error"],
        ],
        [
            "Median Error",
            stats_hardswish["Median Error"],
            stats_silu["Median Error"],
        ],
        [
            "Total Error",
            stats_hardswish["Total Error"],
            stats_silu["Total Error"],
        ],
    ]

    dut._log.info(
        tabulate(
            table, headers=["Metric", "Hardswish", "SiLU"], tablefmt="grid"
        )
    )

    # Log the average errors
    dut._log.info(
        f"Hardswish Avg Error: {stats_hardswish['Avg Error']:.6f}, SiLU Avg Error: {stats_silu['Avg Error']:.6f}"
    )

    fig = make_subplots(
        rows=2,
        cols=1,
        shared_xaxes=True,
        vertical_spacing=0.12,
        subplot_titles=("Function Outputs", "Logarithmic Absolute Errors"),
    )

    traceHW = go.Scatter(
        x=interval,
        y=expected_hardswish_array,
        mode="lines",
        name="Expected Hardswish",
        line=dict(width=2, color="#1f77b4"),
    )
    traceSILU = go.Scatter(
        x=interval,
        y=expected_silu_array,
        mode="lines",
        name="Expected SiLU",
        line=dict(width=2, color="#ff7f0e"),
    )
    traceOutput = go.Scatter(
        x=interval,
        y=output_array,
        mode="lines",
        name="DUT Output",
        line=dict(width=2, color="#2ca02c", dash="dashdot"),
    )

    fig.add_trace(traceHW, row=1, col=1)
    fig.add_trace(traceSILU, row=1, col=1)
    fig.add_trace(traceOutput, row=1, col=1)

    traceErrorHW = go.Scatter(
        x=interval,
        y=error_hardswish_array,
        mode="lines",
        name="Error Hardswish-DUT",
        line=dict(width=2, color="#d62728", dash="solid"),
    )
    traceErrorSILU = go.Scatter(
        x=interval,
        y=error_silu_array,
        mode="lines",
        name="Error SiLU-DUT",
        line=dict(width=2, color="#9467bd", dash="solid"),
    )

    fig.add_trace(traceErrorHW, row=2, col=1)
    fig.add_trace(traceErrorSILU, row=2, col=1)

    fig.add_annotation(
        x=interval[-1],
        y=np.log(stats_hardswish["Avg Error"]),
        text=f"Avg Error (Hardswish): {stats_hardswish['Avg Error']:.4f}",
        showarrow=False,
        yshift=-10,
        row=2,
        col=1,
        font=dict(size=10, color="black", family="Cambria, sans-serif"),
    )
    fig.add_annotation(
        x=interval[-1],
        y=np.log(9),
        text=f"Avg Error (SiLU): {stats_silu['Avg Error']:.4f}",
        showarrow=False,
        yshift=-10,
        row=2,
        col=1,
        font=dict(size=10, color="black", family="Cambria, sans-serif"),
    )

    fig.update_layout(
        title=dict(
            text="Comparison of Hardswish and SiLU Functions with DUT Output and Errors",
            font=dict(size=16, color="black", family="Cambria, sans-serif"),
            x=0,
        ),
        xaxis_title=dict(
            text="Input Value", font=dict(family="Cambria, sans-serif")
        ),
        xaxis2_title=dict(
            text="Input Value", font=dict(family="Cambria, sans-serif")
        ),
        yaxis_title=dict(
            text="Function Output", font=dict(family="Cambria, sans-serif")
        ),
        legend=dict(
            x=0.02,
            y=0.98,
            traceorder="normal",
            bgcolor="rgba(255, 255, 255, 0.9)",
            bordercolor="Black",
            borderwidth=1,
            font=dict(family="Cambria, sans-serif"),
        ),
        plot_bgcolor="white",
        hovermode="x unified",
        autosize=False,
        width=950,
        height=700,
        margin=dict(t=70, r=120),
    )

    fig.update_xaxes(
        showgrid=True,
        gridwidth=1,
        gridcolor="LightGray",
        zeroline=True,
        titlefont=dict(size=14, family="Cambria, sans-serif"),
        title_standoff=10,
        tickfont=dict(family="Cambria, sans-serif", size=12),
    )
    fig.update_xaxes(
        row=2,
        col=1,
        title_text="Input Value",
        title_standoff=10,
        titlefont=dict(family="Cambria, sans-serif"),
    )

    fig.update_yaxes(
        showgrid=True,
        gridwidth=1,
        gridcolor="LightGray",
        tickfont=dict(family="Cambria, sans-serif", size=12),
        titlefont=dict(size=14, family="Cambria, sans-serif"),
    )
    fig.update_yaxes(
        title_text="Function Output",
        row=1,
        col=1,
        tickfont=dict(family="Cambria, sans-serif"),
    )

    fig.update_yaxes(
        title_text="Absolute Error (Log Scale)", type="log", row=2, col=1
    )
    fig.update_xaxes(exponentformat="power")
    fig.update_yaxes(exponentformat="power")

    # Show the figure
    fig.show()
