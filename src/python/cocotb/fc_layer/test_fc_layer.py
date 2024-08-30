import random
import numpy as np
import sys
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


def print_progress_bar(iteration, total, length=50, prefix="", suffix=""):
    percent = 100 * (iteration / float(total))
    filled_length = int(length * iteration // total)
    bar = "█" * filled_length + "-" * (length - filled_length)

    # Determine color based on percentage
    if percent < 33:
        color_code = "\033[91m"  # Red
    elif percent < 66:
        color_code = "\033[93m"  # Yellow
    else:
        color_code = "\033[92m"  # Green

    reset_code = "\033[0m"

    sys.stdout.write(
        f"\r\r\r{prefix} {color_code}|{bar}| {percent:.1f}% {suffix}{reset_code}"
    )
    sys.stdout.flush()


def get_generics(dut):
    return dut.DO_PIPELINE.value, dut.BITWIDTH.value, dut.MATRIX_SIZE.value


def initialize_operands_matrix(dut, NUM_ROWS, NUM_COLUMNS, BITWIDTH):
    """Initialize DUT operands with random signed values in a matrix and return the expected result."""

    # Signed integer range for BITWIDTH bits
    min_value = -(1 << (BITWIDTH - 1))  # Minimum value for signed integer
    max_value = (1 << (BITWIDTH - 1)) - 1  # Maximum value for signed integer

    def generate_matrix(rows, columns, min_val, max_val):
        """Generate a matrix with random integers within the given range."""
        return [
            [random.randint(min_val, max_val) for _ in range(columns)]
            for _ in range(rows)
        ]

    def compute_expected_value(matrix1, matrix2):
        """Compute the sum of the element-wise product of two matrices."""
        return sum(
            matrix1[i][j] * matrix2[i][j]
            for i in range(len(matrix1))
            for j in range(len(matrix1[0]))
        )

    def is_within_range(value, bitwidth):
        """Check if the value is within the acceptable range based on bitwidth."""
        lower_bound = -(1 << (2 * bitwidth - 1))
        upper_bound = (1 << (bitwidth - 1)) - 1
        return lower_bound <= value <= upper_bound

    # Main logic to generate matrices and compute expected value
    while True:
        matrix1 = generate_matrix(NUM_ROWS, NUM_COLUMNS, min_value, max_value)
        matrix2 = generate_matrix(NUM_ROWS, NUM_COLUMNS, min_value, max_value)

        expected_value = compute_expected_value(matrix1, matrix2)

        if is_within_range(expected_value, BITWIDTH):
            break

    dut.i_matrix1.value = matrix1
    dut.i_matrix2.value = matrix2

    return expected_value


async def wait_pipeline(dut, DO_PIPELINE, NUM_OPERAND, BITWIDTH):
    delay = int(np.ceil(np.log2(NUM_OPERAND))) + 1 + 1

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
    expected_value = initialize_operands_matrix(dut, NUM_ROWS, NUM_COLUMNS, BITWIDTH)
    await wait_pipeline(dut, DO_PIPELINE, NUM_ROWS * NUM_COLUMNS, BITWIDTH)
    actual_value = dut.o_result.value.signed_integer

    assert (
        actual_value == expected_value
    ), f"Output value incorrect: expected {expected_value}, got {actual_value}"
