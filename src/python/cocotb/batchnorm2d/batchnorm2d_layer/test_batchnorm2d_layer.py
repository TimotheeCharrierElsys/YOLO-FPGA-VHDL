import sys

import cocotb
import numpy as np
from cocotb.triggers import RisingEdge
from tabulate import tabulate
from random import random

# # Adjust the system path to include the parent directory for imports
sys.path.insert(1, "../../")
from utils import (
    print_progress_bar,
    reset_dut,
    setup_clock,
    sys_enable_dut,
)

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


def relu6(x, scale_factor):
    """
    Applies the ReLU6 activation function with a given scale factor.

    Args:
        x (float): The input value.
        scale_factor (int): The scale factor for the activation function.

    Returns:
        float: The result of applying the ReLU6 function.
    """
    return np.minimum(np.maximum(x, 0), 6 * 2**scale_factor)


def hardswish(x, scale_factor):
    """
    Applies the Hardswish activation function with a given scale factor.

    Args:
        x (float): The input value.
        scale_factor (int): The scale factor for the activation function.

    Returns:
        float: The result of applying the Hardswish function.
    """
    return x * relu6(x + 3 * 2**scale_factor, scale_factor) / (6 * 2**scale_factor)


async def initialize_dut(dut, generics):
    """
    Initialize the DUT with default values.
    """
    await setup_clock(dut)
    dut.i_sys_enable.value = 0
    dut.i_valid.value = 0

    dut.i_data.value = 0
    dut.i_mean.value = 0
    dut.i_weight.value = 0
    dut.i_bias.value = 0
    dut.i_valid.value = 0


@cocotb.test()
async def async_reset_test(dut):
    """
    Test the DUT's behavior during reset.
    """
    generics = get_generics(dut)
    log_generics(dut)

    output_zeros = 0

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    assert dut.o_data == 0, "DUT output was not reset correctly"
    dut._log.info("Reset test passed.")


@cocotb.test()
async def computation_test(dut):
    """
    Test the DUT's behavior during normal computation.
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    assert dut.o_data == 0, "DUT output was not reset correctly"

    await sys_enable_dut(dut)
    dut.i_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_valid.value = 0

    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)
    assert dut.o_data == 0, "DUT output was not reset correctly"
    await reset_dut(dut)
    assert dut.o_data == 0, "DUT output was not reset correctly"

    total_iterations = 100000
    min_val = -(2 ** (generics["BITWIDTH"] - 1))
    max_val = 2 ** (generics["BITWIDTH"] - 1) - 1

    abs_error_array = []

    for i in range(total_iterations):
        print_progress_bar(
            i + 1, total_iterations, prefix="Progress:", suffix="Complete", length=50
        )

        # Generate Random Input Datas
        random_input = int(random() * 2 ** generics["DATA_SCALE_FACTOR"])
        random_mean = int(random() * 2 ** generics["DATA_SCALE_FACTOR"])
        random_var = int(random() * 2 ** generics["DATA_SCALE_FACTOR"])
        random_weight = int(random() * 2 ** generics["DATA_SCALE_FACTOR"])
        random_bias = int(random() * 2 ** generics["DATA_SCALE_FACTOR"])

        if random_var != 0:
            dut_weight = int(random_weight / np.sqrt(random_var))
        else:
            dut_weight = random_weight

        # Send the input data to the DUT
        dut.i_data.value = random_input
        dut.i_mean.value = random_mean
        dut.i_weight.value = dut_weight
        dut.i_bias.value = random_bias

        # Compute Output Value
        if random_var != 0:
            output = int(
                random_weight
                * (random_input - random_mean)
                / np.sqrt(random_var)
                / 2 ** generics["DATA_SCALE_FACTOR"]
                + random_bias
            )
        else:
            output = int(
                random_weight
                * (random_input - random_mean)
                / 2 ** generics["DATA_SCALE_FACTOR"]
                + random_bias
            )

        output = hardswish(output, generics["DATA_SCALE_FACTOR"])

        # Enable the DUT
        dut.i_valid.value = 1
        await RisingEdge(dut.clock)
        dut.i_valid.value = 0

        await RisingEdge(dut.clock)
        await RisingEdge(dut.clock)

        gotten_output = dut.o_data.value.signed_integer
        abs_error_array.append(np.abs(gotten_output - output))

    # Calculate statistics
    abs_errors = np.array(abs_error_array)
    mean_error = np.mean(abs_errors)
    median_error = np.median(abs_errors)
    std_deviation = np.std(abs_errors)
    metrics = [
        ["Mean Absolute Error (MAE)", f"{mean_error:.4f}"],
        ["Median Absolute Error", f"{median_error:.4f}"],
        ["Standard Deviation of Error", f"{std_deviation:.4f}"],
    ]

    # Log the results
    dut._log.info("\n--- Error Metrics Summary ---")
    table = tabulate(metrics, headers=["Metric", "Value"], tablefmt="pretty")
    dut._log.info(table)
    dut._log.info("\nRandom Computation test passed.")
