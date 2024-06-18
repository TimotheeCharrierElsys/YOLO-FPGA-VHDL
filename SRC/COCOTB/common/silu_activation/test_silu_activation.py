import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


async def check_output(dut):
    input_data = dut.i_data.value

    if input_data < -3 * 2**(dut.SCALE_FACTOR_POWER2):
        output_data = 0
    elif input_data < 3 * 2**(dut.SCALE_FACTOR_POWER2):
        output_data = input_data * \
            (input_data + 3 * 2**(dut.SCALE_FACTOR_POWER2))/6
    else:
        output_data = input_data

    assert dut.o_data.value == output_data, f"Output data incorrect. Got {dut.o_data.value}, expected {output_data}"


async def reset_dut(dut):
    """Reset the DUT."""
    dut.reset_n.value = 0
    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)
    dut.reset_n.value = 1
    await RisingEdge(dut.clock)
    dut._log.info("DUT reset complete.")


async def enable_dut(dut):
    """Enable the DUT."""
    dut.i_sys_enable.value = 1
    await RisingEdge(dut.clock)
    dut._log.info("DUT enabled.")


@cocotb.test()
async def reset_test(dut):
    # Start the clock
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.start_soon(clock.start(start_high=False))

    # Input data
    dut.i_sys_enable.value = 0
    dut.i_data.value = 0

    # Apply reset and check output
    await reset_dut(dut)
    assert dut.o_data.value == 0, "Output was not reset correctly"
    dut._log.info("Reset test passed.")


@cocotb.test()
async def computation_test(dut):
    # Start the clock
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.start_soon(clock.start(start_high=False))

    # Input data
    dut.i_sys_enable.value = 0
    dut.i_data.value = 0

    # Apply reset and check output
    await reset_dut(dut)
    assert dut.o_data.value == 0, "Output was not reset correctly"
    dut.reset_n.value = 1

    dut.i_sys_enable.value = 1
    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)
    assert dut.o_data.value == 0, "Output incorrect"

    dut.i_data.value = 4000
    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)
    check_output(dut)
    dut._log.info("Computation test passed.")
