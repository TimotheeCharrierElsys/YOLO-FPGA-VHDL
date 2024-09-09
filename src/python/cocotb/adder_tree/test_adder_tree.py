import sys

import cocotb
import numpy as np
from cocotb.triggers import RisingEdge
from tabulate import tabulate

sys.path.insert(1, "../")
from utils import (
    print_progress_bar,
    reset_dut,
    setup_clock,
    sys_enable_dut,
    vector_init,
)

# Constants
CLOCK_PERIOD_NS = 10


def get_generics(dut):
    """
    Retrieve the generic parameters from the DUT.
    """
    return {
        "DO_PIPELINE": dut.DO_PIPELINE.value,
        "NUM_OPERANDS": dut.NUM_OPERANDS.value,
        "BITWIDTH": dut.BITWIDTH.value,
    }


def log_generics(dut):
    generics = get_generics(dut)
    table = tabulate(generics.items(), headers=["Parameter", "Value"], tablefmt="grid")
    dut._log.info(f"Running with generics:\n{table}")


async def initialize_dut(dut, generics):
    """
    Initialize the DUT with default values.
    """
    await setup_clock(dut)

    dut.i_sys_enable.value = 0
    dut.i_operands.value = vector_init(
        generics["NUM_OPERANDS"], generics["BITWIDTH"], use_random=False
    )


async def wait_pipeline(dut, generics):
    if generics["DO_PIPELINE"] == 1:
        delay = int(np.ceil(np.log2(generics["NUM_OPERANDS"]))) + 1
    else:
        delay = 1

    for i in range(delay):
        await RisingEdge(dut.clock)


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
async def computation_test(dut):
    """
    Test the DUT's behavior during normal computation.
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"

    await sys_enable_dut(dut)

    await RisingEdge(dut.clock)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"
    await reset_dut(dut)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"

    total_iterations = 100000
    dut._log.info(f"\n--- Running {total_iterations} Iterations ---")

    for i in range(total_iterations):
        # Update Progress Bar
        print_progress_bar(
            i + 1, total_iterations, prefix="Progress:", suffix="Complete", length=50
        )

        # Generate Random Inputs and set them to DUT
        random_operand = vector_init(
            generics["NUM_OPERANDS"], generics["BITWIDTH"], use_random=True
        )
        dut.i_operands.value = random_operand

        expected_output = np.sum(random_operand)

        # Wait for the adder tree to process
        await wait_pipeline(dut, generics)

        # Output Check
        gotten_output = dut.o_result.value.signed_integer
        if np.abs(expected_output) <= 2 ** (generics["BITWIDTH"] - 2) - 1:
            assert (
                expected_output == gotten_output
            ), f"DUT output incorrect, Expected: {expected_output}, Gotten {gotten_output} at iteration {i}"

    dut._log.info("\nRandom Addition test passed.")
