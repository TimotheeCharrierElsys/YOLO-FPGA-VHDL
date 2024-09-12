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

states = {"idle": 0, "start": 1, "mac": 2, "adder": 3, "batchnorm2d_silu": 4, "done": 5}


def get_generics(dut):
    """
    Retrieve the generic parameters from the DUT.
    """
    return {
        "INPUT_PADDED_SIZE": dut.INPUT_PADDED_SIZE.value,
        "INPUT_CHANNELS": dut.INPUT_CHANNELS.value,
        "KERNEL_SIZE": dut.KERNEL_SIZE.value,
        "OUTPUT_SIZE": dut.OUTPUT_SIZE.value,
    }


def log_generics(dut):
    """
    Log the generic parameters from the DUT in a table format.
    """
    generics = get_generics(dut)
    table = tabulate(generics.items(), headers=["Parameter", "Value"], tablefmt="grid")
    dut._log.info(f"Running with generics:\n{table}")


async def initialize_dut(dut, generics):
    """
    Initialize the DUT with default values.
    """
    await setup_clock(dut)
    dut.reset_n.value = 0
    dut.i_sys_enable.value = 0

    # Conv2d Init
    dut.i_start.value = 0
    dut.i_batchnorm_silu_conv2d.value = 0
    dut.i_current_row_conv2d.value = 0
    dut.i_current_col_conv2d.value = 0
    dut.i_current_channel_conv2d.value = 0
    dut.i_current_row_conv.value = 0
    dut.i_current_col_conv.value = 0


@cocotb.test()
async def async_reset_test(dut):
    """
    Test the DUT's behavior during reset.
    """
    generics = get_generics(dut)
    log_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    assert dut.o_valid_mac.value == 0, "o_valid_mac was not reset correctly"
    assert dut.o_valid_adder.value == 0, "o_valid_adder was not reset correctly"
    assert dut.o_valid_bn.value == 0, "o_valid_bn was not reset correctly"
    assert dut.o_clear_mac.value == 1, "o_clear_mac was not reset correctly"
    assert dut.o_clear_adder.value == 1, "o_clear_adder was not reset correctly"
    assert dut.o_change_window.value == 0, "o_change_window was not reset correctly"
    assert dut.o_done.value == 0, "o_done was not reset correctly"
    dut._log.info("Reset test passed.")


@cocotb.test()
async def test(dut):
    """
    Test the DUT's behavior.
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    assert dut.o_valid_mac.value == 0, "o_valid_mac was not reset correctly"
    assert dut.o_valid_adder.value == 0, "o_valid_adder was not reset correctly"
    assert dut.o_valid_bn.value == 0, "o_valid_bn was not reset correctly"
    assert dut.o_clear_mac.value == 1, "o_clear_mac was not reset correctly"
    assert dut.o_clear_adder.value == 1, "o_clear_adder was not reset correctly"
    assert dut.o_change_window.value == 0, "o_change_window was not reset correctly"
    assert dut.o_done.value == 0, "o_done was not reset correctly"
    await RisingEdge(dut.clock)

    # Enable DUT
    await sys_enable_dut(dut)

    # Start Testing the DUT
    dut.i_start.value = 1
    await RisingEdge(dut.clock)
    dut.i_start.value = 0
    await RisingEdge(dut.clock)

    assert (
        dut.current_state.value == states["start"]
    ), f"Current State = {dut.current_state.value}, expected is {states["start"]}"
    await RisingEdge(dut.clock)

    assert (
        dut.current_state.value == states["mac"]
    ), f"Current State = {dut.current_state.value}, expected is {states["mac"]}"

    # Update input Counters
    for i in range(generics["KERNEL_SIZE"]):
        for j in range(generics["KERNEL_SIZE"]):
            dut.i_current_row_conv2d.value = i
            dut.i_current_col_conv2d.value = j
            await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)
    assert (
        dut.current_state.value == states["adder"]
    ), f"Current State = {dut.current_state.value}, expected is {states["adder"]}"
    await RisingEdge(dut.clock)

    for k in range(generics["INPUT_CHANNELS"] + 1):
        dut.i_current_channel_conv2d.value = k
        await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)

    assert (
        dut.current_state.value == states["batchnorm2d_silu"]
    ), f"Current State = {dut.current_state.value}, expected is {states["batchnorm2d_silu"]}"

    dut.i_batchnorm_silu_conv2d.value = 1
    await RisingEdge(dut.clock)
    dut.i_batchnorm_silu_conv2d.value = 0
    dut.i_current_row_conv.value = generics["OUTPUT_SIZE"] - 1
    dut.i_current_col_conv.value = generics["OUTPUT_SIZE"] - 1
    await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)
    assert (
        dut.current_state.value == states["done"]
    ), f"Current State = {dut.current_state.value}, expected is {states["done"]}"
    await RisingEdge(dut.clock)
