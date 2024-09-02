import random
import sys

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


def random_signed_value(bitwidth):
    """
    Generate a random signed integer value within the given bitwidth.

    :param bitwidth: The bitwidth for the signed integer
    :return: A random signed integer
    """
    min_val = -(2 ** (bitwidth - 1))
    max_val = 2 ** (bitwidth - 1) - 1
    return random.randint(min_val // 4, max_val // 4)


def vector_init(size, bitwidth=None, use_random=False):
    """
    Initialize a 1D vector with either zeroes or random signed values.

    :param size: Number of elements in the vector
    :param bitwidth: Bitwidth for random signed integer values (required if use_random is True)
    :param use_random: If True, fills with random signed values; otherwise, fills with zeroes
    :return: 1D list representing the vector
    """
    if use_random:
        if bitwidth is None:
            raise ValueError("bitwidth must be specified if use_random is True")
        return [random_signed_value(bitwidth) for _ in range(size)]
    else:
        return [0] * size


def matrix_init(num_rows, num_cols, bitwidth=None, use_random=False):
    """
    Initialize a 2D matrix with either zeroes or random signed values.

    :param num_rows: Number of rows
    :param num_cols: Number of columns
    :param bitwidth: Bitwidth for random signed integer values (required if use_random is True)
    :param use_random: If True, fills with random signed values; otherwise, fills with zeroes
    :return: 2D list representing the matrix
    """
    return [vector_init(num_cols, bitwidth, use_random) for _ in range(num_rows)]


def volume_init(channels, num_rows, num_cols, bitwidth=None, use_random=False):
    """
    Initialize a 3D volume with either zeroes or random signed values.

    :param channels: Number of channels
    :param num_rows: Number of rows per channel
    :param num_cols: Number of columns per channel
    :param bitwidth: Bitwidth for random signed integer values (required if use_random is True)
    :param use_random: If True, fills with random signed values; otherwise, fills with zeroes
    :return: 3D list representing the volume
    """
    return [
        matrix_init(num_rows, num_cols, bitwidth, use_random) for _ in range(channels)
    ]


def tensor_init(kernel_number, channels, kernel_size, bitwidth=None, use_random=False):
    """
    Initialize a 4D tensor with either zeroes or random signed values.

    :param kernel_number: Number of kernels (first dimension)
    :param channels: Number of channels per kernel (second dimension)
    :param kernel_size: Size of each kernel (height and width, third and fourth dimensions)
    :param bitwidth: Bitwidth for random signed integer values (required if use_random is True)
    :param use_random: If True, fills with random signed values; otherwise, fills with zeroes
    :return: 4D list representing the tensor
    """
    return [
        volume_init(channels, kernel_size, kernel_size, bitwidth, use_random)
        for _ in range(kernel_number)
    ]


async def setup_clock(dut, period_ns=10):
    """
    Initialize and start the clock for the DUT.
    """
    clock = Clock(dut.clock, period_ns, units="ns")
    await cocotb.start(clock.start(start_high=False))


async def assert_reset_state(dut, expected_output):
    """
    Assert that the DUT is in the correct reset state.
    """
    assert dut.o_data.value == expected_output, "DUT output was not reset correctly"
    assert dut.o_data_valid.value == 0, "DUT output data valid was not reset correctly"


async def reset_dut(dut, verbose=True):
    """
    Reset the DUT.
    """
    dut.reset_n.value = 0
    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)
    dut.reset_n.value = 1
    await RisingEdge(dut.clock)
    if verbose:
        dut._log.info("DUT reset complete.")


async def sys_enable_dut(dut, verbose=True):
    """Enable the DUT."""
    dut.i_sys_enable.value = 1
    await RisingEdge(dut.clock)
    if verbose:
        dut._log.info("DUT enabled.")


async def enable_dut(dut, verbose=True):
    """
    Enable the DUT.
    """
    dut.i_sys_enable.value = 1
    await RisingEdge(dut.clock)
    if verbose:
        dut._log.info("DUT enabled.")


def print_progress_bar(iteration, total, length=50, prefix="", suffix=""):
    """
    Print a progress bar to the console.

    :param iteration: Current iteration
    :param total: Total iterations
    :param length: Length of the progress bar
    :param prefix: Prefix string
    :param suffix: Suffix string
    """
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
        f"\r\r\r{prefix} {color_code}|{bar}| {
            percent:.1f}% {suffix}{reset_code}"
    )
    sys.stdout.flush()
