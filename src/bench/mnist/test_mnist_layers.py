import random
import sys

import cocotb
import numpy as np
from cocotb.triggers import RisingEdge
from cocotb.utils import get_sim_time
from lib import (
    calculate_output_dimensions,
    generate_probabilty_plot,
    generate_report_first_layer,
    preprocess_input,
    preprocess_layer,
)
from tabulate import tabulate

sys.path.insert(1, "../")
from model import load_dataset
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
    """
    return {
        "DATA_SCALE_FACTOR": dut.DATA_SCALE_FACTOR.value,
        "BITWIDTH": dut.BITWIDTH.value,
        "INPUT_SIZE": dut.INPUT_SIZE.value,
        "KERNEL_SIZE": dut.KERNEL_SIZE.value,
        "INPUT_CHANNELS_1": dut.INPUT_CHANNELS_1.value,
        "OUTPUT_CHANNELS_1": dut.OUTPUT_CHANNELS_1.value,
        "PADDING": dut.PADDING.value,
        "STRIDE_1": dut.STRIDE_1.value,
        "OUTPUT_CHANNELS_2": dut.OUTPUT_CHANNELS_2.value,
        "STRIDE_2": dut.STRIDE_2.value,
    }


def log_generics(dut):
    """
    Log the generic parameters from the DUT in a table format.
    """
    generics = get_generics(dut)
    table = tabulate(
        generics.items(), headers=["Parameter", "Value"], tablefmt="grid"
    )
    dut._log.info(f"Running with generics:\n{table}")


async def initialize_dut(dut, generics):
    """
    #TODO add docstring
    """
    await setup_clock(dut)
    dut.i_sys_enable.value = 0
    dut.i_data_conv2d.value = volume_init(
        generics["INPUT_CHANNELS_1"],
        generics["INPUT_SIZE"],
        generics["INPUT_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_data_valid.value = 0
    dut.i_kernel_conv2d_1.value = tensor_init(
        generics["OUTPUT_CHANNELS_1"],
        generics["INPUT_CHANNELS_1"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )
    dut.i_bias_conv2d_1.value = vector_init(generics["OUTPUT_CHANNELS_1"])
    dut.i_bias_bn_1.value = vector_init(generics["OUTPUT_CHANNELS_1"])
    dut.i_mean_bn_1.value = vector_init(generics["OUTPUT_CHANNELS_1"])
    dut.i_weight_bn_1.value = vector_init(generics["OUTPUT_CHANNELS_1"])

    dut.i_kernel_conv2d_2.value = tensor_init(
        generics["OUTPUT_CHANNELS_2"],
        generics["OUTPUT_CHANNELS_1"],
        generics["KERNEL_SIZE"],
        bitwidth=generics["BITWIDTH"],
        use_random=False,
    )

    dut.i_bias_conv2d_2.value = vector_init(generics["OUTPUT_CHANNELS_2"])
    dut.i_bias_bn_2.value = vector_init(generics["OUTPUT_CHANNELS_2"])
    dut.i_mean_bn_2.value = vector_init(generics["OUTPUT_CHANNELS_2"])
    dut.i_weight_bn_2.value = vector_init(generics["OUTPUT_CHANNELS_2"])
    await RisingEdge(dut.clock)


@cocotb.test()
async def async_reset_test(dut):
    """
    Test the DUT's behavior during reset.
    """
    generics = get_generics(dut)
    log_generics(dut)

    # Compute output dimensions
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS_2"], h_out, w_out)

    await initialize_dut(dut, generics)
    await reset_dut(dut)

    # Check if output is a tensor filled with zeros
    await assert_reset_state(dut, output_zeros)


@cocotb.test()
async def mnist_prediction(dut):
    """
    Test the MNIST model for a given DUT (Device Under Test).

    This function performs the following steps:
    1. Loads the dataset and model.
    2. Asserts the reset state of the DUT.
    3. Retrieves a random image and target from the dataset.
    4. Preprocesses the CNN layers and input image.
    5. Wait for the first layer to be done.
    6. Generates a report for the first layer.
    7. Waits for the second layer to be done.
    8. Generates a report for the second layer.
    9. Use the VHDL output to generate a probability plot and compare it with the PyTorch model.

    Parameters:
    -----------
        dut: The Device Under Test (DUT) instance.
    """
    generics = get_generics(dut)
    scale_factor = 2 ** generics["DATA_SCALE_FACTOR"]

    # Load Dataset and Model
    model, test_loader = load_dataset(PYTORCH_PATH)

    # Compute output dimensions and initialize
    h_out, w_out = calculate_output_dimensions(generics)
    output_zeros = volume_init(generics["OUTPUT_CHANNELS_2"], h_out, w_out)

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
    random_index = random.randint(0, len(test_loader) - 1)
    image, ground_truth = data[random_index], target[random_index]
    dut._log.info(f"Input Image Label is {ground_truth}")

    # Preprocess Conv2D and BatchNorm layers
    (
        i_kernel_conv2d_1,
        i_bias_conv2d_1,
        i_mean_bn_1,
        i_weight_bn_1,
        i_bias_bn_1,
    ) = preprocess_layer(generics, model.conv1, model.bn1)

    (
        i_kernel_conv2d_2,
        i_bias_conv2d_2,
        i_mean_bn_2,
        i_weight_bn_2,
        i_bias_bn_2,
    ) = preprocess_layer(generics, model.conv2, model.bn2)

    # Preprocess input image
    i_data_conv2d = preprocess_input(generics, image)

    # Set DUT values for Conv2D and BatchNorm
    dut.i_data_conv2d.value = i_data_conv2d
    dut.i_kernel_conv2d_1.value = i_kernel_conv2d_1
    dut.i_bias_conv2d_1.value = i_bias_conv2d_1

    dut.i_bias_bn_1.value = i_bias_bn_1
    dut.i_mean_bn_1.value = i_mean_bn_1
    dut.i_weight_bn_1.value = i_weight_bn_1

    dut.i_kernel_conv2d_2.value = i_kernel_conv2d_2
    dut.i_bias_conv2d_2.value = i_bias_conv2d_2
    dut.i_bias_bn_2.value = i_bias_bn_2
    dut.i_mean_bn_2.value = i_mean_bn_2
    dut.i_weight_bn_2.value = i_weight_bn_2

    # Wait few clock cycles
    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)

    startime = get_sim_time("us")

    # Set i_data_valid
    dut.i_data_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_data_valid.value = 0
    await RisingEdge(dut.clock)

    # Wait until the data is valid in DUT's output
    while dut.r_data_conv2d_1_valid.value != 1:
        await RisingEdge(dut.clock)

    run_time = get_sim_time("us") - startime
    dut._log.info(f"First Layer Done in {run_time:.2f} us")
    await RisingEdge(dut.clock)

    # Retrieve DUT output
    gotten_output_first_layer = dut.r_data_conv2d_1_resized.value

    # Compute expected output for SiLU and HS
    output_first_layer_silu = model.forward_first_layer_silu(image.unsqueeze(0))
    output_first_layer_hs = model.forward_first_layer_hs(image.unsqueeze(0))

    # Generate report for the first layer
    generate_report_first_layer(
        image,
        output_first_layer_hs,
        output_first_layer_silu,
        gotten_output_first_layer,
        scale_factor,
        name="First Layer",
    )

    # Store first layer output from dut for next plot
    temp = dut.r_data_conv2d_1_resized.value

    # Continue with the second layer. Wait for the second layer to be done
    startime = get_sim_time("us")

    while dut.o_data_valid.value != 1:
        await RisingEdge(dut.clock)

    run_time_second_layer = get_sim_time("us") - startime
    dut._log.info(f"Second Layer Done in {run_time_second_layer:.2f} us")
    await RisingEdge(dut.clock)

    # Retrieve DUT output
    gotten_output_second_layer = dut.o_data.value

    # Compute expected output for SiLU and HS
    output_second_layer_silu = model.forward_second_layer_silu(
        image.unsqueeze(0)
    )
    output_second_layer_hs = model.forward_second_layer_hs(image.unsqueeze(0))

    # Generate report for the second layer
    generate_report_first_layer(
        temp,
        output_second_layer_hs,
        output_second_layer_silu,
        gotten_output_second_layer,
        scale_factor,
        name="Second Layer",
    )

    # Generate probabilty plot
    generate_probabilty_plot(
        image,
        ground_truth,
        model,
        dut.o_data.value,
        scale_factor,
    )
