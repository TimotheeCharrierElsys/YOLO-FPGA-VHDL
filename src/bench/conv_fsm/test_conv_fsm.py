import sys

import cocotb
from cocotb.triggers import RisingEdge
from tabulate import tabulate

sys.path.insert(1, "../")
from utils import reset_dut, setup_clock, sys_enable_dut

# Constants
CLOCK_PERIOD_NS = 10

states = {
    "idle": 0,
    "start": 1,
    "mac": 2,
    "adder": 3,
    "batchnorm": 4,
    "silu": 5,
    "output_update": 6,
    "done": 7,
}


def get_generics(dut):
    """
    Retrieve the generic parameters from the DUT.
    """
    return {
        "INPUT_CHANNELS": dut.INPUT_CHANNELS.value,
        "KERNEL_SIZE": dut.KERNEL_SIZE.value,
        "OUTPUT_SIZE": dut.OUTPUT_SIZE.value,
    }


def get_state_name(state):
    """
    Retrieve the state name from the state number.
    """
    for name, value in states.items():
        if value == state:
            return name
    return "Unknown"


def assert_reset(dut):
    """
    Assert that the DUT is in a reset state.
    """
    assert dut.o_valid_mac.value == 0, "o_valid_mac was not reset correctly"
    assert dut.o_valid_adder.value == 0, "o_valid_adder was not reset correctly"
    assert dut.o_valid_bn.value == 0, "o_valid_bn was not reset correctly"
    assert dut.o_clear_mac.value == 1, "o_clear_mac was not reset correctly"
    assert dut.o_clear_adder.value == 1, "o_clear_adder was not reset correctly"
    assert dut.o_conv2d_done.value == 0, "o_conv2d_done was not reset correctly"
    assert dut.o_done.value == 0, "o_done was not reset correctly"


def log_generics(dut):
    """
    Log the generic parameters from the DUT in a table format.
    """
    generics = get_generics(dut)
    table = tabulate(
        generics.items(), headers=["Parameter", "Value"], tablefmt="grid"
    )
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
    dut.i_current_row_conv2d.value = 0
    dut.i_current_col_conv2d.value = 0
    dut.i_current_channel_conv2d.value = 0
    dut.i_current_row_win.value = 0
    dut.i_current_col_win.value = 0


@cocotb.test()
async def async_reset_test(dut):
    """
    Test the DUT's behavior during reset.
    """
    generics = get_generics(dut)
    log_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    assert_reset(dut)
    dut._log.info("Reset test passed.")


@cocotb.test()
async def test(dut):
    """
    Test the DUT's behavior.
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    assert_reset(dut)
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
    ), f"Current State = {get_state_name(dut.current_state.value)}, expected is 'start'"
    dut._log.info(
        f"Transitioned to state: {get_state_name(dut.current_state.value)}"
    )
    await RisingEdge(dut.clock)

    assert (
        dut.current_state.value == states["mac"]
    ), f"Current State = {get_state_name(dut.current_state.value)}, expected is 'mac'"
    dut._log.info(
        f"Transitioned to state: {get_state_name(dut.current_state.value)}"
    )

    # Update input Counters
    for i in range(generics["KERNEL_SIZE"]):
        for j in range(generics["KERNEL_SIZE"]):
            dut.i_current_row_conv2d.value = i
            dut.i_current_col_conv2d.value = j
            await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)
    assert (
        dut.current_state.value == states["adder"]
    ), f"Current State = {get_state_name(dut.current_state.value)}, expected is 'adder'"
    dut._log.info(
        f"Transitioned to state: {get_state_name(dut.current_state.value)}"
    )
    await RisingEdge(dut.clock)

    for k in range(generics["INPUT_CHANNELS"] + 1):
        dut.i_current_channel_conv2d.value = k
        await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)

    assert (
        dut.current_state.value == states["batchnorm"]
    ), f"Current State = {get_state_name(dut.current_state.value)}, expected is 'batchnorm'"
    dut._log.info(
        f"Transitioned to state: {get_state_name(dut.current_state.value)}"
    )

    # Directly set i_current_col_win and i_current_row_win to max value to go to done state
    dut.i_current_col_win.value = generics["OUTPUT_SIZE"] - 1
    dut.i_current_row_win.value = generics["OUTPUT_SIZE"] - 1
    await RisingEdge(dut.clock)

    assert (
        dut.current_state.value == states["silu"]
    ), f"Current State = {get_state_name(dut.current_state.value)}, expected is 'silu'"
    dut._log.info(
        f"Transitioned to state: {get_state_name(dut.current_state.value)}"
    )

    await RisingEdge(dut.clock)

    assert (
        dut.current_state.value == states["output_update"]
    ), f"Current State = {get_state_name(dut.current_state.value)}, expected is 'output_update'"
    dut._log.info(
        f"Transitioned to state: {get_state_name(dut.current_state.value)}"
    )

    await RisingEdge(dut.clock)

    assert (
        dut.current_state.value == states["done"]
    ), f"Current State = {get_state_name(dut.current_state.value)}, expected is 'done'"
    dut._log.info(
        f"Transitioned to state: {get_state_name(dut.current_state.value)}"
    )
