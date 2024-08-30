import sys
import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

# Adjust the system path to include the parent directory for imports
sys.path.insert(1, "../")
from utils import reset_dut, sys_enable_dut, tensor_init, vector_init, volume_init


def get_generics(dut):
    """
    Retrieve the generic parameters from the DUT.
    """
    return {
        "DATA_SCALE_FACTOR": dut.DATA_SCALE_FACTOR.value,
        "USE_MAC_ARCH": dut.USE_MAC_ARCH.value,
        "DO_PIPELINE": dut.DO_PIPELINE.value,
        "BITWIDTH": dut.BITWIDTH.value,
        "INPUT_SIZE": dut.INPUT_SIZE.value,
        "CHANNEL_NUMBER": dut.CHANNEL_NUMBER.value,
        "KERNEL_SIZE": dut.KERNEL_SIZE.value,
        "KERNEL_NUMBER": dut.KERNEL_NUMBER.value,
        "PADDING": dut.PADDING.value,
        "STRIDE": dut.STRIDE.value,
    }


def calculate_output_dimensions(generics):
    """
    Calculate the output height and width based on the input dimensions and parameters.
    """
    h_out = w_out = (
        generics["INPUT_SIZE"] - generics["KERNEL_SIZE"] + 2 * generics["PADDING"]
    ) // generics["STRIDE"] + 1
    return h_out, w_out


def forward_conv2d(generics, x, kernels, bias):
    """
    Perform a forward pass of 2D convolution.

    :param generics: Dictionary containing generic parameters for the convolution.
    :param x: Input tensor of shape (channels, height, width)
    :param kernels: Convolution kernels of shape (num_kernels, channels, kernel_height, kernel_width)
    :param bias: Bias values of shape (num_kernels,)
    :return: Output tensor after convolution
    """
    # Extract generic parameters
    kernel_size = generics["KERNEL_SIZE"]
    padding = generics["PADDING"]
    stride = generics["STRIDE"]
    num_kernels = generics["KERNEL_NUMBER"]
    bitwidth = generics["BITWIDTH"]

    # Calculate output dimensions
    h_out, w_out = calculate_output_dimensions(generics)

    # Initialize the output tensor
    output = volume_init(
        num_kernels, h_out, w_out, bitwidth=2 * bitwidth, use_random=False
    )

    x = np.array(x)
    kernels = np.array(kernels)
    bias = np.array(bias)
    output = np.array(output)

    # Apply padding to the input tensor
    if padding > 0:
        x_padded = np.pad(
            x, ((0, 0), (padding, padding), (padding, padding)), mode="constant"
        )
    else:
        x_padded = x

    # Perform convolution
    for k in range(num_kernels):
        for i in range(h_out):
            for j in range(w_out):
                x_slice = x_padded[
                    :,
                    i * stride : i * stride + kernel_size,
                    j * stride : j * stride + kernel_size,
                ]
                output[k, i, j] = np.sum(x_slice * kernels[k]) + bias[k]

    return output


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


@cocotb.test()
async def async_reset_test(dut):
    """
    Test the DUT's behavior during reset.
    """
    generics = get_generics(dut)
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["KERNEL_NUMBER"], h_out, w_out)

    # Initialize and start the clock
    await setup_clock(dut)

    # Apply reset and check output
    await reset_dut(dut)
    await assert_reset_state(dut, output_zeros)
    dut._log.info("Reset test passed.")


@cocotb.test()
async def computation_test(dut):
    """
    Test the DUT's behavior during normal computation.
    """
    generics = get_generics(dut)
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["KERNEL_NUMBER"], h_out, w_out)

    # Initialize and start the clock
    await setup_clock(dut)

    # Initialize inputs with zeros
    dut.i_sys_enable.value = 0
    dut.i_data.value = volume_init(
        generics["CHANNEL_NUMBER"],
        generics["INPUT_SIZE"],
        generics["INPUT_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_data_valid.value = 0
    dut.i_kernel.value = tensor_init(
        generics["KERNEL_NUMBER"],
        generics["CHANNEL_NUMBER"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_bias.value = vector_init(generics["KERNEL_NUMBER"])

    # Apply reset and check output
    await reset_dut(dut)
    await assert_reset_state(dut, output_zeros)

    # Enable DUT and set input data valid
    await sys_enable_dut(dut)
    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0

    # Wait for the output to be valid
    while dut.o_data_valid.value != 1:
        await RisingEdge(dut.clock)

    assert (
        dut.o_data.value == output_zeros
    ), "DUT output did not match expected output after computation"

    await reset_dut(dut)
    await assert_reset_state(dut, output_zeros)

    random_input = volume_init(
        generics["CHANNEL_NUMBER"],
        generics["INPUT_SIZE"],
        generics["INPUT_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    random_kernels = tensor_init(
        generics["KERNEL_NUMBER"],
        generics["CHANNEL_NUMBER"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )

    random_bias = vector_init(
        generics["KERNEL_NUMBER"], bitwidth=2 * generics["BITWIDTH"], use_random=True
    )

    dut.i_data.value = random_input
    dut.i_kernel.value = random_kernels
    dut.i_bias.value = random_bias
    expected_output = forward_conv2d(
        generics, random_input, random_kernels, random_bias
    )

    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0

    # Wait for the output to be valid
    while dut.o_data_valid.value != 1:
        await RisingEdge(dut.clock)
        gotten_output = dut.o_data.value

    print(gotten_output, expected_output)
