import sys

import cocotb
import numpy as np
from cocotb.triggers import RisingEdge
from tabulate import tabulate

sys.path.insert(1, "../")
from utils import (
    reset_dut,
    setup_clock,
    sys_enable_dut,
    volume_init,
    random_signed_value,
    hardswish,
)

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
        "DATA_SCALE_FACTOR": dut.DATA_SCALE_FACTOR.value,
        "BITWIDTH": dut.BITWIDTH.value,
        "INPUT_CHANNELS": dut.INPUT_CHANNELS.value,
        "KERNEL_SIZE": dut.KERNEL_SIZE.value,
    }


def compute_conv2d(i_data, i_kernel, i_bias):
    output = 0

    for channel in range(len(i_data)):
        for row in range(len(i_data[0])):
            for col in range(len(i_data[0][0])):
                output += (
                    i_data[channel][row][col] * i_kernel[channel][row][col]
                )

    return output + i_bias


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
    await setup_clock(dut)
    dut.reset_n.value = 0
    dut.i_sys_enable.value = 0

    # Conv2d Init
    dut.i_data_conv2d.value = volume_init(
        generics["INPUT_CHANNELS"],
        generics["KERNEL_SIZE"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_kernel_conv2d.value = volume_init(
        generics["INPUT_CHANNELS"],
        generics["KERNEL_SIZE"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_bias_conv2d.value = 0

    # Batchnormn2d and SiLU Init
    dut.i_bias_bn.value = 0
    dut.i_mean_bn.value = 0
    dut.i_weight_bn.value = 0

    # Control Signals Init
    dut.i_valid_mac.value = 0
    dut.i_valid_adder.value = 0
    dut.i_valid_bn.value = 0
    dut.i_clear_mac.value = 0
    dut.i_clear_adder.value = 0
    dut.current_row.value = 0
    dut.current_col.value = 0
    dut.current_channel.value = 0


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
    await reset_dut(dut)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"
    dut._log.info("Reset test passed.")


@cocotb.test()
async def test(dut):
    """
    Test the DUT's behavior during a single convolutional layer operation.

    Verifies that the DUT correctly computes the convolutional layer operation

    Parameters
    ----------
    dut : object
        The device under test (DUT).
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"

    # TODO: Implement the test