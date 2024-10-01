from random import randint
from sys import path
from lib import (
    assert_bn_result,
    assert_conv2d_result,
    calculate_output_dimensions,
    convert_output_to_int,
    forward_bn,
    forward_conv2d,
    forward_silu,
    generate_report,
    preprocess_input,
    preprocess_layer,
)

import cocotb
import numpy as np
from cocotb.triggers import RisingEdge
from tabulate import tabulate
import torch

path.insert(1, "../")
from model import ExtractedNetConv, load_dataset
from utils import (
    assert_reset_state,
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
PYTORCH_PATH = r"../mnist_cnn.pt"


def get_generics(dut):
    """
    Retrieve the generic parameters from the DUT.

    Parameters
    ----------
    dut : object
        The device under test (DUT).

    Returns
    -------
    dict
        A dictionary containing the generic parameters.
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


def check_generics(generics):
    """
    Validates the values in the `generics` dictionary for a neural network configuration.

    The function checks that the input size, input channels, output channels, kernel size,
    stride, and padding match the expected values. The expected values are:
        - INPUT_SIZE: 28
        - INPUT_CHANNELS: 1
        - OUTPUT_CHANNELS: 32
        - KERNEL_SIZE: 3
        - STRIDE: 2
        - PADDING: 1

    Parameters:
    ----------
    generics : dict
        A dictionary containing the generics configuration with the following keys:
        - "INPUT_SIZE" : int
            Expected value: 28
        - "INPUT_CHANNELS" : int
            Expected value: 1
        - "OUTPUT_CHANNELS" : int
            Expected value: 32
        - "KERNEL_SIZE" : int
            Expected value: 3
        - "STRIDE" : int
            Expected value: 2
        - "PADDING" : int
            Expected value: 1

    Raises:
    ------
    ValueError:
        If any of the values in `generics` do not match the expected values. The specific
        error message will indicate which key has the invalid value and what the current
        value is.
    """
    input_width = generics["INPUT_SIZE"]
    input_channels = generics["INPUT_CHANNELS"]
    output_channels = generics["OUTPUT_CHANNELS"]
    kernel_size = generics["KERNEL_SIZE"]
    stride = generics["STRIDE"]
    padding = generics["PADDING"]

    if input_width != 28:
        raise ValueError(
            f"Invalid value for INPUT_SIZE. It should be 28, currently {input_width}"
        )
    elif input_channels != 1:
        raise ValueError(
            f"Invalid value for INPUT_CHANNELS. It should be 1, currently {input_channels}"
        )
    elif output_channels != 32:
        raise ValueError(
            f"Invalid value for OUTPUT_CHANNELS. It should be 32, currently {output_channels}"
        )
    elif kernel_size != 3:
        raise ValueError(
            f"Invalid value for KERNEL_SIZE. It should be 3, currently {kernel_size}"
        )
    elif stride != 2:
        raise ValueError(
            f"Invalid value for STRIDE. It should be 2, currently {stride}"
        )
    elif padding != 1:
        raise ValueError(
            f"Invalid value for PADDING. It should be 1, currently {padding}"
        )


def log_generics(dut):
    """
    Log the generic parameters from the DUT in a table format.

    Parameters
    ----------
    dut : object
        The device under test (DUT).
    """
    generics = get_generics(dut)
    table = tabulate(
        generics.items(), headers=["Parameter", "Value"], tablefmt="grid"
    )
    dut._log.info(f"Running with generics:\n{table}")


def generics_to_string(generics: dict):
    """
    Converts the generics dictionary to a string formatted for easy display.

    Parameters:
    ----------
        generics (dict): Configuration dictionary.

    Returns:
    -------
        str: Generics string.
    """
    generics_str = f"DATA_SCALE_FACTOR: {generics['DATA_SCALE_FACTOR']}, BITWIDTH: {generics['BITWIDTH']}, INPUT_SIZE: {generics['INPUT_SIZE']} INPUT_CHANNELS: {generics['INPUT_CHANNELS']}<br>"
    generics_str += f"OUTPUT_CHANNELS: {generics['OUTPUT_CHANNELS']}, KERNEL_SIZE: {generics['KERNEL_SIZE']}, STRIDE: {generics['STRIDE']}, PADDING: {generics['PADDING']}"

    return generics_str


async def initialize_dut(dut, generics):
    """
    Initialize the DUT with default values.

    Parameters
    ----------
    dut : object
        The device under test (DUT).
    generics : dict
        A dictionary containing the generic parameters.
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

    Verifies that the output is correctly reset and remains stable.

    Parameters
    ----------
    dut : object
        The device under test (DUT).
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


# @cocotb.test() WIP
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
        generics["OUTPUT_CHANNELS"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    i_bias_bn = dut.i_weight_bn.value = vector_init(
        generics["OUTPUT_CHANNELS"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    i_mean_bn = dut.i_weight_bn.value = vector_init(
        generics["OUTPUT_CHANNELS"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
    )
    i_weight_bn = dut.i_weight_bn.value = vector_init(
        generics["OUTPUT_CHANNELS"],
        bitwidth=generics["BITWIDTH"],
        use_random=True,
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


@cocotb.test()
async def mnist_test_first_layer(dut):
    """
    Test the DUT's first Conv layer behavior with random inputs from the MNIST dataset.
    """
    generics = get_generics(dut)
    check_generics(generics)

    # Load Dataset and Model
    model, test_loader = load_dataset(PYTORCH_PATH)

    # Compute output dimensions and initialize
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS"], h_out, w_out)

    # Initialize DUT and perform reset
    await initialize_dut(dut, generics)
    await reset_dut(dut)

    # Assert reset state
    await assert_reset_state(dut, output_zeros)

    # Enable System
    await sys_enable_dut(dut)
    await RisingEdge(dut.clock)

    # Get random image and target from dataset
    data, target = next(iter(test_loader))
    random_index = randint(0, len(test_loader) - 1)
    image, _ = data[random_index], target[random_index]

    # Extract the first layer's and forward it
    extracted_model = ExtractedNetConv(
        model, 2 ** generics["DATA_SCALE_FACTOR"]
    )
    output_first_layer_silu = extracted_model.forward_first_layer(
        image.unsqueeze(0)
    ).int()[0]
    output_first_layer_hs = extracted_model.forward_first_layer_approximate(
        image.unsqueeze(0)
    ).int()[0]

    # Preprocess Conv2D and BatchNorm layers
    i_kernel_conv2d, i_bias_conv2d, i_mean_bn, i_weight_bn, i_bias_bn = (
        preprocess_layer(generics, extracted_model.conv1, extracted_model.bn1)
    )

    # Preprocess input image
    i_data_conv2d = preprocess_input(generics, image)

    # Set DUT values for Conv2D and BatchNorm
    dut.i_data_conv2d.value = i_data_conv2d
    dut.i_kernel_conv2d.value = i_kernel_conv2d
    dut.i_bias_conv2d.value = i_bias_conv2d

    dut.i_bias_bn.value = i_bias_bn
    dut.i_mean_bn.value = i_mean_bn
    dut.i_weight_bn.value = i_weight_bn

    # Wait few clock cycles
    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)

    # Set i_data_valid
    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0
    await RisingEdge(dut.clock)

    # Wait until the data is valid in DUT's output
    while dut.o_data_valid.value != 1:
        await RisingEdge(dut.clock)

    await RisingEdge(dut.clock)

    # Retrieve and process DUT output
    gotten_output = dut.o_data.value
    gotten_output = torch.tensor(
        np.array(convert_output_to_int(gotten_output)), dtype=torch.int32
    )

    # Generate report for the first layer
    generate_report(
        generics,
        image,
        output_first_layer_silu,
        output_first_layer_hs,
        gotten_output,
    )
