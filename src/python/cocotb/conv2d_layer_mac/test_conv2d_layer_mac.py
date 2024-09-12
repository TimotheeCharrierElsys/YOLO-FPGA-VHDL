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
    reset_dut,
    setup_clock,
    sys_enable_dut,
    volume_init,
    random_signed_value,
)

# Constants
CLOCK_PERIOD_NS = 10


def get_generics(dut):
    """
    Retrieve the generic parameters from the DUT.
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
                output += i_data[channel][row][col] * i_kernel[channel][row][col]

    return output + i_bias


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
    Test the DUT's behavior.
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"

    i_data_conv2d = volume_init(
        generics["INPUT_CHANNELS"],
        generics["KERNEL_SIZE"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    dut.i_data_conv2d.value = i_data_conv2d

    i_kernel_conv2d = volume_init(
        generics["INPUT_CHANNELS"],
        generics["KERNEL_SIZE"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    dut.i_kernel_conv2d.value = i_kernel_conv2d

    i_bias_conv2d = random_signed_value(generics["BITWIDTH"])
    dut.i_bias_conv2d.value = i_bias_conv2d

    # Batchnormn2d and SiLU Init
    i_bias_bn = random_signed_value(generics["BITWIDTH"])
    dut.i_bias_bn.value = i_bias_bn
    i_mean_bn = random_signed_value(generics["BITWIDTH"])
    dut.i_mean_bn.value = i_mean_bn
    i_weight_bn = random_signed_value(generics["BITWIDTH"])
    dut.i_weight_bn.value = i_weight_bn

    # Control Signals Init
    dut.i_valid_mac.value = 0
    dut.i_valid_adder.value = 0
    dut.i_valid_bn.value = 0
    dut.i_clear_mac.value = 0
    dut.i_clear_adder.value = 0
    dut.current_row.value = 0
    dut.current_col.value = 0
    dut.current_channel.value = 0

    # Compute expected value
    expected_conv2d = compute_conv2d(i_data_conv2d, i_kernel_conv2d, i_bias_conv2d)
    expected_bn = hardswish(expected_conv2d, generics["DATA_SCALE_FACTOR"])
    print(f"Conv2d: {expected_conv2d}, bn: {expected_bn}")

    await RisingEdge(dut.clock)
    dut.i_sys_enable.value = 1
    await RisingEdge(dut.clock)

    print(i_data_conv2d)
    print(i_kernel_conv2d)

    for i in range(generics["KERNEL_SIZE"]):
        for j in range(generics["KERNEL_SIZE"]):
            dut.current_row.value = i
            dut.current_col.value = j
            dut.i_valid_mac.value = 1
            await RisingEdge(dut.clock)

    dut.i_valid_mac.value = 0
    dut.i_valid_adder.value = 1

    for i in range(generics["INPUT_CHANNELS"] + 1):
        dut.current_channel.value = i
        await RisingEdge(dut.clock)

    dut.i_valid_adder.value = 0
    dut.i_valid_bn.value = 1
    await RisingEdge(dut.clock)
    dut.i_valid_bn.value = 0
    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)
