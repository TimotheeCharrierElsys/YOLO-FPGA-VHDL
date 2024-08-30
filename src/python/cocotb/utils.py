import random

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
    return random.randint(min_val, max_val)


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


async def reset_dut(dut):
    """Reset the DUT."""
    dut.reset_n.value = 0
    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)
    dut.reset_n.value = 1
    await RisingEdge(dut.clock)
    dut._log.info("DUT reset complete.")


async def sys_enable_dut(dut):
    """Enable the DUT."""
    dut.i_sys_enable.value = 1
    await RisingEdge(dut.clock)
    dut._log.info("DUT enabled.")
