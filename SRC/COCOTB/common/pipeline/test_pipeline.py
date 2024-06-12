import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


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
async def delay(dut):
    # Get generic parameter
    N_STAGES = int(dut.N_STAGES)

    # Start the clock
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.start_soon(clock.start(start_high=False))

    # Input data
    dut.i_sys_enable.value = 0
    dut.i_data.value = 0

    # Apply reset and check output
    await reset_dut(dut)
    assert dut.o_data.value == 0, "Output was not reset correctly"

    # Enable DUT
    await enable_dut(dut)

    # Input one and see if delay is matching expected
    dut.i_data.value = 1
    await RisingEdge(dut.clock)
    dut.i_data.value = 0

    for i in range(N_STAGES):
        await RisingEdge(dut.clock)

    assert dut.o_data.value == 1, f"Output is not correct got {dut.o_data.value} expected 1"
    await RisingEdge(dut.clock)
    assert dut.o_data.value == 0, f"Output is not correct got {dut.o_data.value} expected 0"
    await RisingEdge(dut.clock)
    
    dut._log.info("Pipeline test passed.")

