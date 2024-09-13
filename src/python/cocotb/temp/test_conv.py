import random
import sys

import cocotb
import matplotlib.pyplot as plt
import numpy as np
import torch
from cocotb.triggers import RisingEdge
from tabulate import tabulate
from torch.nn.functional import conv2d

sys.path.insert(1, "../")
from utils import (
    assert_reset_state,
    hardswish,
    reset_dut,
    setup_clock,
    sys_enable_dut,
    tensor_init,
    vector_init,
    volume_init,
)

np.set_printoptions(
    suppress=True
)  # prevent numpy exponential notation on print, default False

# Constants
CLOCK_PERIOD_NS = 10


def get_generics(dut):
    """
    Retrieve the generic parameters from the DUT.
    """
    return {
        "DATA_SCALE_FACTOR": dut.DATA_SCALE_FACTOR.value,
        "BITWIDTH": dut.BITWIDTH.value,
        "INPUT_SIZE": dut.INPUT_SIZE.value,
        "INPUT_CHANNELS": dut.INPUT_CHANNELS.value,
        "KERNEL_SIZE": dut.KERNEL_SIZE.value,
        "OUTPUT_CHANNELS": dut.OUTPUT_CHANNELS.value,
        "PADDING": dut.PADDING.value,
        "STRIDE": dut.STRIDE.value,
    }


def log_generics(dut):
    """
    Log the generic parameters from the DUT in a table format.
    """
    generics = get_generics(dut)
    table = tabulate(generics.items(), headers=["Parameter", "Value"], tablefmt="grid")
    dut._log.info(f"Running with generics:\n{table}")


def calculate_output_dimensions(generics):
    """
    Calculate the output height and width based on the input dimensions and parameters.
    """
    h_out = w_out = (
        generics["INPUT_SIZE"] + 2 * generics["PADDING"] - generics["KERNEL_SIZE"]
    ) // generics["STRIDE"] + 1
    return h_out, w_out


def forward_conv2d(generics, x, kernels, bias):
    """
    Perform a forward pass of 2D convolution.
    """
    x_torch = torch.tensor(x)
    kernels_torch = torch.tensor(kernels)
    bias_torch = torch.tensor(bias)

    output_torch: torch.Tensor = conv2d(
        x_torch,
        kernels_torch,
        bias_torch,
        stride=generics["STRIDE"],
        padding=generics["PADDING"],
    )

    return output_torch.detach().numpy()


def forward_bn(x, mean, weights, bias):
    """
    Perform a forward pass of 2D batch normalization.
    """
    x_torch = torch.tensor(x)
    mean_torch = torch.tensor(mean)
    weights_torch = torch.tensor(weights)
    bias_torch = torch.tensor(bias)

    output_torch = torch.zeros_like(x_torch)

    for c in range(x_torch.shape[0]):
        output_torch[c] = (x_torch[c] - mean_torch[c]) * weights_torch[c] + bias_torch[
            c
        ]

    return output_torch.detach().numpy()


def convert_output_to_int(output):
    """
    Convert the output tensor to integers based on the bitwidth.
    """
    for i in range(len(output[0])):
        for j in range(len(output[0][0])):
            for k in range(len(output)):
                output[k][i][j] = output[k][i][j].signed_integer


def forward_silu(x, generics):
    """Apply the activation function."""
    return hardswish(x, generics["DATA_SCALE_FACTOR"])


def assert_conv2d_result(dut, generics, expected_output):
    """
    Assert the convolution result from the DUT against the expected output.

    Args:
        dut: The device under test.
        generics: A dictionary containing the generic parameters.
        expected_output: The expected output from the convolution operation.
    """
    s_current_row_win = dut.s_current_row_win.value
    s_current_col_win = dut.s_current_col_win.value

    min_value = -(2 ** (generics["BITWIDTH"] - 1))
    max_value = 2 ** (generics["BITWIDTH"] - 1) - 1

    output = [
        conv2d_layer.conv2d_layer_mac_inst.conv2d_result.value.signed_integer
        for conv2d_layer in dut.GEN_CONV2D_LAYERS
    ][::-1]

    for c, (expected, actual) in enumerate(zip(expected_output, output)):
        expected_value = expected[s_current_row_win][s_current_col_win]

        if min_value <= expected_value <= max_value:
            assert (
                expected_value == actual
            ), f"Mismatch at channel {c}: expected {expected_value}, got {actual}"


def assert_bn_result(dut, generics, expected_output):
    """
    Assert the batch normalization result from the DUT against the expected output.

    Args:
        dut: The device under test.
        generics: A dictionary containing the generic parameters.
        expected_output: The expected output from the batch normalization operation.
    """
    s_current_row_win = dut.s_current_row_win.value
    s_current_col_win = dut.s_current_col_win.value

    min_value = -(2 ** (generics["BITWIDTH"] - 1))
    max_value = 2 ** (generics["BITWIDTH"] - 1) - 1

    output = [
        bn_layer.conv2d_layer_mac_inst.batchnorm2d_layer_inst.r_data_to_silu.value.signed_integer
        for bn_layer in dut.GEN_CONV2D_LAYERS
    ][::-1]

    for c, (expected, actual) in enumerate(zip(expected_output, output)):
        expected_value = expected[s_current_row_win][s_current_col_win]

        if min_value <= expected_value <= max_value:
            assert (
                expected_value == actual
            ), f"Mismatch at channel {c}: expected {expected_value}, got {actual}"


def assert_silu_result(dut, generics, expected_output):
    """
    Assert the SiLU result from the DUT against the expected output

    Args:
        dut: The device under test.
        generics: A dictionary containing the generic parameters.
        expected_output: The expected output from the silu activation operation.
    """

    s_current_row_win = dut.s_current_row_win.value
    s_current_col_win = dut.s_current_col_win.value

    min_value = -(2 ** (generics["BITWIDTH"] - 1))
    max_value = 2 ** (generics["BITWIDTH"] - 1) - 1

    output = [out.value.signed_integer for out in dut.s_result][::-1]

    for c, (expected, actual) in enumerate(zip(expected_output, output)):
        expected_value = expected[s_current_row_win][s_current_col_win]

        if min_value <= expected_value <= max_value:
            assert (
                expected_value == actual
            ), f"Mismatch at channel {c}: expected {expected_value}, got {actual}"


async def initialize_dut(dut, generics):
    """
    Initialize the DUT with default values.
    """
    await setup_clock(dut)
    dut.i_sys_enable.value = 0
    dut.i_data_conv2d.value = volume_init(
        generics["INPUT_CHANNELS"],
        generics["INPUT_SIZE"],
        generics["INPUT_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_data_valid.value = 0
    dut.i_kernel_conv2d.value = tensor_init(
        generics["OUTPUT_CHANNELS"],
        generics["INPUT_CHANNELS"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_bias_conv2d.value = vector_init(generics["OUTPUT_CHANNELS"])
    dut.i_bias_bn.value = vector_init(generics["OUTPUT_CHANNELS"])
    dut.i_mean_bn.value = vector_init(generics["OUTPUT_CHANNELS"])
    dut.i_weight_bn.value = vector_init(generics["OUTPUT_CHANNELS"])


@cocotb.test()
async def async_reset_test(dut):
    """
    Test the DUT's behavior during reset.
    """
    generics = get_generics(dut)
    log_generics(dut)

    # Compute output dimensions
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS"], h_out, w_out)

    await initialize_dut(dut, generics)
    await reset_dut(dut)

    # Check if output is a tensor filled with zeros
    await assert_reset_state(dut, output_zeros)


@cocotb.test()
async def random_test(dut):
    """
    Test the DUT's behavior with random inputs.
    """
    generics = get_generics(dut)

    # Compute output dimensions
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS"], h_out, w_out)

    await initialize_dut(dut, generics)
    await reset_dut(dut)

    # Check if output is a tensor filled with zeros
    await assert_reset_state(dut, output_zeros)

    # Generate random inputs and send them to DUT
    i_data_conv2d = volume_init(
        generics["INPUT_CHANNELS"],
        generics["INPUT_SIZE"],
        generics["INPUT_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    dut.i_data_conv2d.value = i_data_conv2d

    i_kernel_conv2d = tensor_init(
        generics["OUTPUT_CHANNELS"],
        generics["INPUT_CHANNELS"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    dut.i_kernel_conv2d.value = i_kernel_conv2d

    i_bias_conv2d = vector_init(
        generics["OUTPUT_CHANNELS"], bitwidth=generics["BITWIDTH"], use_random=True
    )
    i_bias_bn = dut.i_weight_bn.value = vector_init(
        generics["OUTPUT_CHANNELS"], bitwidth=generics["BITWIDTH"], use_random=True
    )
    i_mean_bn = dut.i_weight_bn.value = vector_init(
        generics["OUTPUT_CHANNELS"], bitwidth=generics["BITWIDTH"], use_random=True
    )
    i_weight_bn = dut.i_weight_bn.value = vector_init(
        generics["OUTPUT_CHANNELS"], bitwidth=generics["BITWIDTH"], use_random=True
    )

    dut.i_bias_conv2d.value = i_bias_conv2d
    dut.i_bias_bn.value = i_bias_bn
    dut.i_mean_bn.value = i_mean_bn
    dut.i_weight_bn.value = i_weight_bn

    # Enable System
    await sys_enable_dut(dut)
    await RisingEdge(dut.clock)

    # Set data valid flag for one clock cycle
    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0
    await RisingEdge(dut.clock)

    # Pre-compute expected output for each layer
    conv2d_expected_output = forward_conv2d(
        generics, i_data_conv2d, i_kernel_conv2d, i_bias_conv2d
    )
    bn_expected_output = forward_bn(
        conv2d_expected_output, i_mean_bn, i_weight_bn, i_bias_bn
    )
    silu_expected_output = forward_silu(bn_expected_output, generics)

    # Wait for the Conv to finish
    while dut.o_data_valid.value != 1:
        
        # Assert current Conv2d output
        if dut.s_valid_bn.value == 1:
            assert_conv2d_result(dut, generics, conv2d_expected_output)

        # Assert current Batchnorm2d and SiLU
        elif dut.s_conv2d_done.value == 1:
            assert_bn_result(dut, generics, bn_expected_output)
            assert_silu_result(dut, generics, silu_expected_output)

        await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)

    # Get the output from the DUT
    expected_output = dut.o_data.value
    convert_output_to_int(expected_output)

    expected_output = np.array(expected_output)
    silu_expected_output = np.array(silu_expected_output)
    assert np.array_equal(
        expected_output, silu_expected_output
    ), "Output mismatch in SiLU phase."
