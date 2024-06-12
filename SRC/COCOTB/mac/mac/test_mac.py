import os
import random
import sys
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.binary import BinaryValue


def to_signed(val, bitwidth):
    """Convert an unsigned integer to signed."""
    if val >= 2**(bitwidth - 1):
        return val - 2**bitwidth
    else:
        return val


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


def generate_random_test_vector(dut):
    """Generate random test vectors."""
    i_multiplier1 = random.randint(0, 2**dut.i_multiplier1.value.n_bits-1)
    i_multiplier2 = random.randint(0, 2**dut.i_multiplier2.value.n_bits-1)
    i_add = random.randint(0, 2**dut.i_add.value.n_bits-1)
    return i_multiplier1, i_multiplier2, i_add


async def apply_test_vector(dut, i_multiplier1, i_multiplier2, i_add):
    """Apply test vector to the DUT."""
    dut.i_multiplier1.value = i_multiplier1
    dut.i_multiplier2.value = i_multiplier2
    dut.i_add.value = i_add
    await RisingEdge(dut.clock)
    dut._log.info(
        f"Applied test vector: multiplier1={to_signed(i_multiplier1, dut.i_multiplier1.value.n_bits)}, multiplier2={to_signed(i_multiplier2, dut.i_multiplier2.value.n_bits)}, add={i_add}")


async def check_result(dut, expected_val):
    """Check the DUT result."""
    await RisingEdge(dut.clock)
    output_val = int(dut.o_result.value)
    signed_output_val = to_signed(output_val, dut.o_result.value.n_bits)
    dut._log.info(f"Expected: {expected_val}, Got: {signed_output_val}")
    assert signed_output_val == expected_val, (
        f"Output result was incorrect: expected {expected_val}, got {signed_output_val}"
    )


@cocotb.test()
async def mac_test(dut):
    # Start the clock
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.start_soon(clock.start(start_high=False))
    dut.reset_n.value = 0
    dut.i_sys_enable.value = 0
    dut.i_add.value = to_signed(0, dut.i_add.value.n_bits)
    dut.i_multiplier1.value = to_signed(0, dut.i_multiplier1.value.n_bits)
    dut.i_multiplier2.value = to_signed(0, dut.i_multiplier2.value.n_bits)

    await reset_dut(dut)
    await enable_dut(dut)

    # Test loop
    for i in range(10):
        i_multiplier1, i_multiplier2, i_add = generate_random_test_vector(dut)

        # Convert to signed values for correct computation
        signed_multiplier1 = to_signed(
            i_multiplier1, dut.i_multiplier1.value.n_bits)
        signed_multiplier2 = to_signed(
            i_multiplier2, dut.i_multiplier2.value.n_bits)
        signed_add = to_signed(i_add, dut.i_add.value.n_bits)

        expected_val = signed_multiplier1 * signed_multiplier2 + signed_add

        await apply_test_vector(dut, i_multiplier1, i_multiplier2, i_add)
        await check_result(dut, expected_val)

    # Check for edge cases, such as maximum values
    max_val = 2**(dut.i_multiplier1.value.n_bits - 1) - 1
    signed_max_val = to_signed(max_val, dut.i_multiplier1.value.n_bits)
    expected_val = signed_max_val * signed_max_val + signed_max_val

    await apply_test_vector(dut, max_val, max_val, max_val)
    await check_result(dut, expected_val)


@cocotb.test()
async def reset_test(dut):
    # Start the clock
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.start_soon(clock.start(start_high=False))

    # Apply some values
    dut.i_multiplier1.value = 1
    dut.i_multiplier2.value = 1
    dut.i_add.value = 1

    # Apply reset and check output
    await reset_dut(dut)
    assert dut.o_result.value == 0, "Output was not reset correctly"
    dut._log.info("Reset test passed.")
