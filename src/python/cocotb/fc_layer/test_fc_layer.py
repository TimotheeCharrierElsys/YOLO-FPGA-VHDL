import sys

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

sys.path.insert(1, "../")
from utils import enable_dut, matrix_init, print_progress_bar, reset_dut


def get_generics(dut):
    return dut.DO_PIPELINE.value, dut.BITWIDTH.value, dut.MATRIX_SIZE.value


def initialize_operands_matrix(dut, NUM_ROWS, NUM_COLUMNS, BITWIDTH):
    """Initialize DUT operands with random signed values in a matrix and return the expected result."""

    def compute_expected_value(matrix1, matrix2):
        """Compute the sum of the element-wise product of two matrices."""
        return sum(
            matrix1[i][j] * matrix2[i][j]
            for i in range(len(matrix1))
            for j in range(len(matrix1[0]))
        )

    matrix1 = matrix_init(NUM_ROWS, NUM_COLUMNS, BITWIDTH, use_random=True)
    matrix2 = matrix_init(NUM_ROWS, NUM_COLUMNS, BITWIDTH, use_random=True)

    expected_value = compute_expected_value(matrix1, matrix2)

    dut.i_matrix1.value = matrix1
    dut.i_matrix2.value = matrix2

    return expected_value


async def wait_pipeline(dut, DO_PIPELINE, NUM_OPERAND, BITWIDTH):
    delay = int(np.ceil(np.log2(NUM_OPERAND))) + 1 + 1

    for i in range(delay):
        await RisingEdge(dut.clock)


@cocotb.test()
async def computation_test(dut):
    # Get the Generics
    DO_PIPELINE, BITWIDTH, MATRIX_SIZE = get_generics(dut)
    NUM_ROWS = NUM_COLUMNS = MATRIX_SIZE

    # Start the clock
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.start_soon(clock.start(start_high=False))

    # Initialize inputs
    matrix = [[0] * NUM_COLUMNS for _ in range(NUM_ROWS)]
    dut.i_matrix1.value = matrix
    dut.i_matrix2.value = matrix

    # Apply reset and check output
    await reset_dut(dut)
    assert dut.o_result.value == 0, "Output was not reset correctly"

    # Enable DUT
    await enable_dut(dut)

    # Wait for pipeline to process
    await wait_pipeline(dut, DO_PIPELINE, NUM_ROWS * NUM_COLUMNS, BITWIDTH)
    assert dut.o_result.value == 0, "Output value incorrect after enabling DUT"

    total_iterations = 20000
    for i in range(total_iterations):
        # Generate random values

        print_progress_bar(
            i + 1, total_iterations, prefix="Progress:", suffix="Complete", length=50
        )

        expected_value = initialize_operands_matrix(
            dut, NUM_ROWS, NUM_COLUMNS, BITWIDTH
        )
        await wait_pipeline(dut, DO_PIPELINE, NUM_ROWS * NUM_COLUMNS, BITWIDTH)
        actual_value = dut.o_result.value.signed_integer

        assert (
            actual_value == expected_value
        ), f"Output value incorrect: expected {expected_value}, got {actual_value}"
    print()

    # Apply reset and check output
    await reset_dut(dut)
    assert dut.o_result.value == 0, "Output was not reset correctly"

    # Test after reset
    expected_value = initialize_operands_matrix(
        dut, NUM_ROWS, NUM_COLUMNS, BITWIDTH)
    await wait_pipeline(dut, DO_PIPELINE, NUM_ROWS * NUM_COLUMNS, BITWIDTH)
    actual_value = dut.o_result.value.signed_integer

    assert (
        actual_value == expected_value
    ), f"Output value incorrect: expected {expected_value}, got {actual_value}"
