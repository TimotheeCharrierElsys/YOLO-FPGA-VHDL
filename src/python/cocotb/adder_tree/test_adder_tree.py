import random
from numpy import ceil, log2, sum

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


def get_generics(dut):
    return dut.DO_PIPELINE.value, dut.NUM_OPERANDS.value, dut.BITWIDTH.value


def initialize_operands(dut, NUM_OPERAND, BITWIDTH):
    # Signed integer range for BITWIDTH bits
    min_value = -(1 << (BITWIDTH - 1))  # Minimum value for signed integer
    max_value = (1 << (BITWIDTH - 1)) - 1  # Maximum value for signed integer

    # Generate random signed values within the specified range
    random_values = [random.randint(min_value, max_value) for _ in range(NUM_OPERAND)]
    dut.i_operands.value = random_values

    # Calculate the expected result: sum of operands, wrapping within BITWIDTH
    expected_value = sum(random_values)

    # Wrap the expected value to fit within the BITWIDTH using two's complement
    if expected_value < min_value:
        expected_value = (expected_value + (1 << BITWIDTH)) & ((1 << BITWIDTH) - 1)
    elif expected_value > max_value:
        expected_value = expected_value & ((1 << BITWIDTH) - 1)

    # Convert to two's complement representation
    if expected_value >= (1 << (BITWIDTH - 1)):
        expected_value -= (1 << BITWIDTH)

    dut._log.info(f"Initialized operands to random signed values: {random_values}")
    dut._log.info(f"Expected output: {expected_value}")

    return expected_value


async def wait_pipeline(dut, DO_PIPELINE, NUM_OPERAND, BITWIDTH):
    delay = int(ceil(log2(NUM_OPERAND))) + 1

    for i in range(delay):
        await RisingEdge(dut.clock)


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
async def async_reset_test(dut):
    # Start the clock
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.start_soon(clock.start(start_high=False))

    # Apply reset and check output
    await reset_dut(dut)
    assert dut.o_result.value == 0, "Output was not reset correctly"
    dut._log.info("Reset test passed.")


@cocotb.test()
async def computation_test(dut):
    # Get the Generics
    DO_PIPELINE, NUM_OPERAND, BITWIDTH = get_generics(dut)

    # Start the clock
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.start_soon(clock.start(start_high=False))

    # Initialize inputs
    dut.i_operands.value = [0] * NUM_OPERAND

    # Apply reset and check output
    await reset_dut(dut)
    assert dut.o_result.value == 0, "Output was not reset correctly"

    # Enable DUT
    await enable_dut(dut)

    # Wait for pipeline to process
    await wait_pipeline(dut, DO_PIPELINE, NUM_OPERAND, BITWIDTH)
    assert dut.o_result.value == 0, "Output value incorrect after enabling DUT"


    for _ in range(20):
        # Generate random values
        expected_value = initialize_operands(dut, NUM_OPERAND, BITWIDTH)
        await wait_pipeline(dut, DO_PIPELINE, NUM_OPERAND, BITWIDTH)
        actual_value = dut.o_result.value.signed_integer
        assert (
            actual_value == expected_value
        ), f"Output value incorrect: expected {expected_value}, got {actual_value}"

    # Apply reset and check output
    await reset_dut(dut)
    assert dut.o_result.value == 0, "Output was not reset correctly"
    
    expected_value = initialize_operands(dut, NUM_OPERAND, BITWIDTH)
    await wait_pipeline(dut, DO_PIPELINE, NUM_OPERAND, BITWIDTH)
    actual_value = dut.o_result.value.signed_integer
    assert (
        actual_value == expected_value
    ), f"Output value incorrect: expected {expected_value}, got {actual_value}"
    
    dut._log.info("DUT Computation Test Complete.")
