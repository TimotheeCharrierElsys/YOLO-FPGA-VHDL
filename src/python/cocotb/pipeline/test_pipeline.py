import sys
from random import randint

import cocotb
from cocotb.triggers import RisingEdge
from tabulate import tabulate

sys.path.insert(1, "../")
from utils import reset_dut, setup_clock

# Constants
CLOCK_PERIOD_NS = 10


def get_generics(dut):
    """
    Retrieve the generic parameters from the DUT.
    """
    return {
        "N_STAGES": dut.N_STAGES.value,
    }


def log_generics(dut):
    """
    Log the generic parameters from the DUT in a table format.
    """
    generics = get_generics(dut)
    table = tabulate(generics.items(), headers=["Parameter", "Value"], tablefmt="grid")
    dut._log.info(f"Running with generics:\n{table}")


async def initialize_dut(dut, generics):
    """
    Initialize the DUT with default values.
    """
    await setup_clock(dut, CLOCK_PERIOD_NS)

    # Set initial values
    dut.i_sys_enable.value = 0
    dut.i_data.value = 0


@cocotb.test()
async def async_reset_test(dut):
    """
    Test the DUT's behavior during reset.
    Verifies that the output is correctly reset and remains stable.
    """
    generics = get_generics(dut)
    log_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)  # Assert and deassert reset signal

    # After reset, the output should be zero
    assert dut.o_data.value == 0, "DUT output was not reset correctly"

    # Additional check: output should remain zero for N_STAGES cycles after reset
    for _ in range(generics["N_STAGES"]):
        await RisingEdge(dut.clock)
        assert dut.o_data.value == 0, "Output should be zero immediately after reset"

    dut._log.info("Reset test passed.")


@cocotb.test()
async def test_pipeline_behavior(dut):
    """
    Test the pipeline's normal operation, verifying that data propagates correctly
    through the pipeline stages when enabled.
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)

    # Enable the pipeline
    dut.i_sys_enable.value = 1

    # Generate a random sequence of data and apply it to the DUT
    input_sequence = [randint(0, 1) for _ in range(generics["N_STAGES"] * 2)]
    expected_output_sequence = [0] * generics["N_STAGES"] + input_sequence[
        : len(input_sequence) - generics["N_STAGES"]
    ]

    for i, data in enumerate(input_sequence):
        dut.i_data.value = data
        await RisingEdge(dut.clock)

        # Check that the output matches the expected value
        assert (
            dut.o_data.value == expected_output_sequence[i]
        ), f"Output mismatch at cycle {i}: expected {expected_output_sequence[i]}, got {dut.o_data.value}"

    dut._log.info("Pipeline behavior test passed.")


@cocotb.test()
async def test_pipeline_stability(dut):
    """
    Test the stability of the pipeline's output when the input is held constant.
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)

    # Enable the pipeline
    dut.i_sys_enable.value = 1

    # Apply a constant value to the input
    dut.i_data.value = 1
    await RisingEdge(dut.clock)  # Give it one clock cycle

    # Now hold the input constant and check the output
    for i in range(generics["N_STAGES"] * 2):
        await RisingEdge(dut.clock)

        # Output should stabilize to the input value after N_STAGES cycles
        if i >= generics["N_STAGES"]:
            assert (
                dut.o_data.value == 1
            ), f"Output should have stabilized to 1 at cycle {i}, but got {dut.o_data.value}"

    dut._log.info("Pipeline stability test passed.")


@cocotb.test()
async def test_pulse(dut):
    """
    Test the pipeline output when the input is a pulse.
    Verifies that the pulse propagates correctly through the pipeline.
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)

    # Enable the pipeline
    dut.i_sys_enable.value = 1

    # Generate a pulse with a random pulse length
    pulse_length = randint(1, 5)
    dut._log.info(f"Generated pulse of length {pulse_length}")

    # Apply the pulse to the input
    for i in range(generics["N_STAGES"] + 1):
        if i < pulse_length:
            dut.i_data.value = 1
        else:
            dut.i_data.value = 0
        await RisingEdge(dut.clock)

    # Check that the output reflects the pulse correctly
    for i in range(pulse_length):
        assert (
            dut.o_data.value == 1
        ), f"Output did not match expected pulse at cycle {i + 1} after delay. Expected 1, got {dut.o_data.value}"
        await RisingEdge(dut.clock)

    # After the pulse duration, the output should return to 0
    assert (
        dut.o_data.value == 0
    ), f"Output did not return to 0 after the pulse. Got {dut.o_data.value}"
    dut._log.info("Pulse test passed.")
