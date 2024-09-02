import sys
import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from torch.nn.functional import conv2d
import torch
from tabulate import tabulate

# # Adjust the system path to include the parent directory for imports
sys.path.insert(1, "../")
from utils import reset_dut, sys_enable_dut, setup_clock, assert_reset_state, tensor_init, vector_init, volume_init, print_progress_bar

# Constants
CLOCK_PERIOD_NS = 10


def get_generics(dut) -> dict:
    """
    Retrieve the generic parameters from the DUT.
    """
    return {
        "DATA_SCALE_FACTOR": dut.DATA_SCALE_FACTOR.value,
        "USE_MAC_ARCH": dut.USE_MAC_ARCH.value,
        "DO_PIPELINE": dut.DO_PIPELINE.value,
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

def calculate_output_dimensions(generics: dict) -> tuple:
    """
    Calculate the output height and width based on the input dimensions and parameters.
    """
    h_out = w_out = (
        generics["INPUT_SIZE"] + 2 *
        generics["PADDING"] - generics["KERNEL_SIZE"]
    ) // generics["STRIDE"] + 1
    return h_out, w_out


def forward_conv2d(generics: dict, x: np.ndarray, kernels: np.ndarray, bias: np.ndarray) -> np.ndarray:
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


def convert_output_to_int(output: np.ndarray) -> None:
    """
    Convert the output tensor to integers based on the bitwidth.
    """
    for i in range(len(output[0])):
        for j in range(len(output[0][0])):
            for k in range(len(output)):
                output[k][i][j] = output[k][i][j].signed_integer


async def initialize_dut(dut, generics: dict) -> None:
    """
    Initialize the DUT with default values.
    """
    await setup_clock(dut)
    dut.i_sys_enable.value = 0
    dut.i_data.value = volume_init(
        generics["INPUT_CHANNELS"],
        generics["INPUT_SIZE"],
        generics["INPUT_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False
    )
    dut.i_data_valid.value = 0
    dut.i_kernel.value = tensor_init(
        generics["OUTPUT_CHANNELS"],
        generics["INPUT_CHANNELS"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_bias.value = vector_init(generics["OUTPUT_CHANNELS"])


@cocotb.test()
async def async_reset_test(dut) -> None:
    """
    Test the DUT's behavior during reset.
    """
    generics = get_generics(dut)
    log_generics(dut)

    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS"], h_out, w_out)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    await assert_reset_state(dut, output_zeros)
    dut._log.info("Reset test passed.")


@cocotb.test()
async def computation_test(dut) -> None:
    """
    Test the DUT's behavior during normal computation.
    """
    generics = get_generics(dut)
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS"], h_out, w_out)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    await assert_reset_state(dut, output_zeros)

    await sys_enable_dut(dut)
    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0

    while dut.o_data_valid.value != 1:
        await RisingEdge(dut.clock)

    assert dut.o_data.value == output_zeros, "DUT output did not match expected output after computation"

    await reset_dut(dut)
    await assert_reset_state(dut, output_zeros)

    total_iterations = 10000
    for i in range(total_iterations):
        print_progress_bar(
            i + 1, total_iterations, prefix="Progress:", suffix="Complete", length=50
        )

        # Generate random values
        random_input = volume_init(generics["INPUT_CHANNELS"], generics["INPUT_SIZE"],
                                generics["INPUT_SIZE"], bitwidth=generics["BITWIDTH"], use_random=True)
        random_kernels = tensor_init(generics["OUTPUT_CHANNELS"], generics["INPUT_CHANNELS"],
                                    generics["KERNEL_SIZE"], bitwidth=generics["BITWIDTH"], use_random=True)
        random_bias = vector_init(
            generics["OUTPUT_CHANNELS"], bitwidth=generics["BITWIDTH"], use_random=True)
        
        # Compute the expected output
        expected_output = forward_conv2d(
            generics, random_input, random_kernels, random_bias)

        # Send the input data to the DUT
        dut.i_data.value = random_input
        dut.i_kernel.value = random_kernels
        dut.i_bias.value = random_bias

        # Enable the DUT
        dut.i_data_valid.value = 1
        await RisingEdge(dut.clock)
        dut.i_data_valid.value = 0

        # Wait for the DUT to process the data
        while dut.o_data_valid.value != 1:
            await RisingEdge(dut.clock)

        await RisingEdge(dut.clock)
        gotten_output = dut.o_data.value

        convert_output_to_int(gotten_output)
        gotten_output = np.array(gotten_output)
        assert np.allclose(gotten_output, expected_output), "DUT output did not match expected output after computation"

        # Reset the DUT
        await reset_dut(dut, verbose=False)
        await assert_reset_state(dut, output_zeros)