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
    print_progress_bar,
    reset_dut,
    setup_clock,
    sys_enable_dut,
    tensor_init,
    vector_init,
    volume_init,
)

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

def forward_bn(output, mean, weights, bias ):
    return (output - mean) * weights + bias

def convert_output_to_int(output):
    """
    Convert the output tensor to integers based on the bitwidth.
    """
    for i in range(len(output[0])):
        for j in range(len(output[0][0])):
            for k in range(len(output)):
                output[k][i][j] = output[k][i][j].signed_integer


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

    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS"], h_out, w_out)

    await initialize_dut(dut, generics)
    await reset_dut(dut)

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

    await sys_enable_dut(dut)
    await RisingEdge(dut.clock)

    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0
    await RisingEdge(dut.clock)

    while dut.o_data_valid.value != 1:
        await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)

    expected_output = forward_conv2d(generics, i_data_conv2d, i_kernel_conv2d, i_bias_conv2d)
    print(np.array(expected_output))
    expected_output = forward_bn(expected_output, i_mean_bn, i_weight_bn, i_bias_bn)
    print(np.array(expected_output))
