import random
import sys

import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


def random_signed_value(bitwidth):
    """
    Generate a random signed integer value within the given bitwidth.

    Parameters
    ----------
    bitwidth : int
        The bitwidth for the signed integer.

    Returns
    -------
    int
        A random signed integer.
    """
    min_val = -(2 ** (bitwidth - 1))
    max_val = 2 ** (bitwidth - 1) - 1
    return random.randint(min_val // 8, max_val // 8)


def vector_init(size, bitwidth=None, use_random=False):
    """
    Initialize a 1D vector with either zeroes or random signed values.

    Parameters
    ----------
    size : int
        Number of elements in the vector.
    bitwidth : int, optional
        Bitwidth for random signed integer values (required if use_random is True).
    use_random : bool, optional
        If True, fills with random signed values; otherwise, fills with zeroes.

    Returns
    -------
    list
        1D list representing the vector.
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

    Parameters
    ----------
    num_rows : int
        Number of rows.
    num_cols : int
        Number of columns.
    bitwidth : int, optional
        Bitwidth for random signed integer values (required if use_random is True).
    use_random : bool, optional
        If True, fills with random signed values; otherwise, fills with zeroes.

    Returns
    -------
    list
        2D list representing the matrix.
    """
    return [
        vector_init(num_cols, bitwidth, use_random) for _ in range(num_rows)
    ]


def volume_init(channels, num_rows, num_cols, bitwidth=None, use_random=False):
    """
    Initialize a 3D volume with either zeroes or random signed values.

    Parameters
    ----------
    channels : int
        Number of channels.
    num_rows : int
        Number of rows per channel.
    num_cols : int
        Number of columns per channel.
    bitwidth : int, optional
        Bitwidth for random signed integer values (required if use_random is True).
    use_random : bool, optional
        If True, fills with random signed values; otherwise, fills with zeroes.

    Returns
    -------
    list
        3D list representing the volume.
    """
    return [
        matrix_init(num_rows, num_cols, bitwidth, use_random)
        for _ in range(channels)
    ]


def tensor_init(
    kernel_number, channels, kernel_size, bitwidth=None, use_random=False
):
    """
    Initialize a 4D tensor with either zeroes or random signed values.

    Parameters
    ----------
    kernel_number : int
        Number of kernels (first dimension).
    channels : int
        Number of channels per kernel (second dimension).
    kernel_size : int
        Size of each kernel (height and width, third and fourth dimensions).
    bitwidth : int, optional
        Bitwidth for random signed integer values (required if use_random is True).
    use_random : bool, optional
        If True, fills with random signed values; otherwise, fills with zeroes.

    Returns
    -------
    list
        4D list representing the tensor.
    """
    return [
        volume_init(channels, kernel_size, kernel_size, bitwidth, use_random)
        for _ in range(kernel_number)
    ]


async def setup_clock(dut, period_ns=10):
    """
    Initialize and start the clock for the DUT.

    Parameters
    ----------
    dut : object
        The device under test.
    period_ns : int, optional
        Clock period in nanoseconds (default is 10).
    """
    clock = Clock(dut.clock, period_ns, units="ns")
    await cocotb.start(clock.start(start_high=False))


async def assert_reset_state(dut, expected_output):
    """
    Assert that the DUT is in the correct reset state.

    Parameters
    ----------
    dut : object
        The device under test.
    expected_output : int
        The expected output value after reset.
    """
    assert (
        dut.o_data.value == expected_output
    ), "DUT output was not reset correctly"
    assert (
        dut.o_data_valid.value == 0
    ), "DUT output data valid was not reset correctly"


async def reset_dut(dut, verbose=True):
    """
    Reset the DUT.

    Parameters
    ----------
    dut : object
        The device under test.
    verbose : bool, optional
        If True, logs the reset operation (default is True).
    """
    dut.reset_n.value = 0
    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)
    dut.reset_n.value = 1
    await RisingEdge(dut.clock)
    if verbose:
        dut._log.info("DUT reset complete.")


async def sys_enable_dut(dut, verbose=True):
    """
    Enable the DUT.

    Parameters
    ----------
    dut : object
        The device under test.
    verbose : bool, optional
        If True, logs the enable operation (default is True).
    """
    dut.i_sys_enable.value = 1
    await RisingEdge(dut.clock)
    if verbose:
        dut._log.info("DUT enabled.")


async def enable_dut(dut, verbose=True):
    """
    Enable the DUT.

    Parameters
    ----------
    dut : object
        The device under test.
    verbose : bool, optional
        If True, logs the enable operation (default is True).
    """
    dut.i_sys_enable.value = 1
    await RisingEdge(dut.clock)
    if verbose:
        dut._log.info("DUT enabled.")


def print_progress_bar(iteration, total, length=50, prefix="", suffix=""):
    """
    Print a progress bar to the console.

    Parameters
    ----------
    iteration : int
        Current iteration.
    total : int
        Total iterations.
    length : int, optional
        Length of the progress bar (default is 50).
    prefix : str, optional
        Prefix string (default is "").
    suffix : str, optional
        Suffix string (default is "").
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
        f"\r{prefix} {color_code}|{bar}| {percent:.1f}% {suffix}{reset_code}"
    )
    sys.stdout.flush()


def relu6(x, data_scale_factor):
    """
    Compute the ReLU6 activation function.

    The ReLU6 function is a variation of the ReLU (Rectified Linear Unit) function,
    which clips the input values to the range [0, 6 * 2^data_scale_factor].

    Parameters
    ----------
    x : array-like
        Input array or value to apply the ReLU6 function to.
    data_scale_factor : int
        An integer scale factor applied to the upper bound.

    Returns
    -------
    array-like
        The result of applying the ReLU6 function to the input `x`, where the output
        is clipped between 0 and 6 * 2^data_scale_factor.
    """
    return np.minimum(np.maximum(x, 0), 6 * 2**data_scale_factor)


def hardswish(x, data_scale_factor):
    """
    Compute the HardSwish activation function.

    The HardSwish function is a computationally efficient approximation of the
    Swish activation function, often used in neural networks. It combines the
    input with the ReLU6 activation and scales it accordingly.

    Parameters
    ----------
    x : array-like
        Input array or value to apply the HardSwish function to.
    data_scale_factor : int
        An integer scale factor that influences the behavior of both
        the ReLU6 and the final scaling.

    Returns
    -------
    array-like
        The result of applying the HardSwish function to the input `x`, where the
        output is computed as x * relu6(x + 3 * 2^data_scale_factor, 2^data_scale_factor) / (6 * 2^data_scale_factor).
    """
    return (
        x
        * relu6(x + 3 * 2**data_scale_factor, data_scale_factor)
        / (6 * 2**data_scale_factor)
    )


def silu(x, data_scale_factor):
    """
    Compute the Sigmoid Linear Unit (SiLU) activation function.

    The SiLU function, also known as the Swish function, is defined as x / (1 + exp(-x)).
    It is similar to the Sigmoid function but with a linear component, which makes it
    more useful in certain machine learning applications.

    Parameters
    ----------
    x : array-like
        Input array or value to apply the SiLU function to.
    data_scale_factor : int
        An integer scale factor that is applied to the result of the SiLU function.

    Returns
    -------
    array-like
        The result of applying the SiLU function to the input `x`, scaled by 2^data_scale_factor.
    """
    return x / (1 + np.exp(-x)) * 2**data_scale_factor
