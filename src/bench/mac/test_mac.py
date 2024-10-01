import sys
from random import randint

import cocotb
from cocotb.triggers import RisingEdge
from tabulate import tabulate

sys.path.insert(1, "../")
from utils import (
    print_progress_bar,
    reset_dut,
    setup_clock,
    sys_enable_dut,
)

# Constants
CLOCK_PERIOD_NS = 10


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
        "DO_MULTIPLICATION": dut.DO_MULTIPLICATION.value,
        "INPUT_WIDTH": dut.INPUT_WIDTH.value,
        "OUTPUT_WIDTH": dut.OUTPUT_WIDTH.value,
    }


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


def check_generics(generics):
    """
    Validates the `generics` dictionary based on the `DO_MULTIPLICATION` flag.

    If `DO_MULTIPLICATION` is set to 1:
        - The `OUTPUT_WIDTH` should be twice the `INPUT_WIDTH`.

    If `DO_MULTIPLICATION` is set to 0:
        - The `OUTPUT_WIDTH` should be equal to the `INPUT_WIDTH`.

    Parameters
    ----------
    generics : dict
        A dictionary containing the generics configuration with keys:
        - "DO_MULTIPLICATION": int (0 or 1)
        - "INPUT_WIDTH": int
        - "OUTPUT_WIDTH": int

    Raises
    ------
    ValueError
        If the `OUTPUT_WIDTH` does not match the expected value based on
        the `DO_MULTIPLICATION` setting.
        If `DO_MULTIPLICATION` is not 0 or 1.
    """
    do_multiplication = generics.get("DO_MULTIPLICATION")
    input_width = generics.get("INPUT_WIDTH")
    output_width = generics.get("OUTPUT_WIDTH")

    # Check if multiplication is enabled
    if do_multiplication == 1:
        # Output width should be twice the input width
        expected_output_width = 2 * input_width
        if output_width != expected_output_width:
            raise ValueError(
                f"DO_MULTIPLICATION is set, so OUTPUT_WIDTH should be "
                f"{expected_output_width}, but got {output_width}."
            )
    elif do_multiplication == 0:
        # Output width should be equal to input width
        if output_width != input_width:
            if output_width > input_width:
                raise ValueError(
                    f"DO_MULTIPLICATION is not set, so OUTPUT_WIDTH should be "
                    f"equal to INPUT_WIDTH ({input_width}), but got {output_width}."
                    f"\nIt will work because output > input"
                )
            else:
                assert (
                    output_width > input_width
                ), f"DO_MULTIPLICATION is not set, so OUTPUT_WIDTH should be\nequal to INPUT_WIDTH ({input_width}), but got {output_width}."
    else:
        raise ValueError(
            "Invalid value for DO_MULTIPLICATION. It should be 0 or 1."
        )


def get_random_operands(min_val, max_val):
    """
    Generate a pair of random operands within the specified range.

    Parameters
    ----------
    min_val : int
        The minimum value for the random operands.
    max_val : int
        The maximum value for the random operands.

    Returns
    -------
    tuple
        A tuple containing two random integers within the specified range.
    """
    return randint(min_val, max_val), randint(min_val, max_val)


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
    dut.i_valid.value = 0
    dut.i_clear.value = 0
    dut.i_operand1.value = 0
    dut.i_operand2.value = 0


@cocotb.test()
async def test_generics(dut):
    """
    Test the generic parameters of the DUT.

    Parameters
    ----------
    dut : object
        The device under test (DUT).
    """
    generics = get_generics(dut)
    check_generics(generics)
    log_generics(dut)

    dut._log.info("Generic Check test passed.")


@cocotb.test()
async def async_reset_test(dut):
    """
    Test the DUT's behavior during reset.

    Parameters
    ----------
    dut : object
        The device under test (DUT).
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"
    dut._log.info("Reset test passed.")


@cocotb.test()
async def computation_test(dut):
    """
    Test the DUT's behavior during normal computation.

    Parameters
    ----------
    dut : object
        The device under test (DUT).
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"

    await sys_enable_dut(dut)
    dut.i_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_valid.value = 0

    await RisingEdge(dut.clock)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"
    await reset_dut(dut)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"

    total_iterations = 100000
    min_val = -(2 ** (generics["INPUT_WIDTH"] - 1))
    max_val = 2 ** (generics["INPUT_WIDTH"] - 1) - 1

    dut._log.info(
        f"\n--- Running {total_iterations} Iterations testing one multiplication and then clear ---"
    )

    for i in range(total_iterations):
        # Update Progress Bar
        print_progress_bar(
            i + 1,
            total_iterations,
            prefix="Progress:",
            suffix="Complete",
            length=50,
        )

        # Generate Random Inputs and set them to DUT
        random_operand1, random_operand2 = get_random_operands(min_val, max_val)
        dut.i_operand1.value = random_operand1
        dut.i_operand2.value = random_operand2

        # Compute Expected Accumulated Output
        if generics["DO_MULTIPLICATION"] == 1:
            expected_output = random_operand1 * random_operand2
        else:
            expected_output = random_operand1 + random_operand2

        # Enable the DUT
        dut.i_valid.value = 1
        await RisingEdge(dut.clock)
        dut.i_valid.value = 0

        # Wait one clock cycle
        await RisingEdge(dut.clock)

        # Output Check
        gotten_output = dut.o_result.value.signed_integer
        assert (
            expected_output == gotten_output
        ), f"DUT output incorrect, Expected: {expected_output}, Gotten {gotten_output} at iteration {i}"

        # Clear the DUT
        dut.i_clear.value = 1
        await RisingEdge(dut.clock)
        dut.i_clear.value = 0
        await RisingEdge(dut.clock)
        assert dut.o_result.value == 0, "DUT output was not reset correctly"

    dut._log.info("\nRandom Multiplication without accumulation test passed.")


@cocotb.test()
async def accumulation_test(dut):
    """
    Test the DUT's behavior during accumulation.

    Parameters
    ----------
    dut : object
        The device under test (DUT).
    """
    generics = get_generics(dut)

    await initialize_dut(dut, generics)
    await reset_dut(dut)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"

    await sys_enable_dut(dut)
    dut.i_valid.value = 1
    await RisingEdge(dut.clock)
    dut.i_valid.value = 0

    await RisingEdge(dut.clock)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"
    await reset_dut(dut)
    assert dut.o_result.value == 0, "DUT output was not reset correctly"

    total_iterations = 25000
    min_val = -(2 ** (generics["INPUT_WIDTH"] - 2))
    max_val = 2 ** (generics["INPUT_WIDTH"] - 2) - 1

    dut._log.info(
        f"\n--- Running {total_iterations} Iterations testing accumulation with random lengths ---"
    )

    for i in range(total_iterations):
        # Update Progress Bar
        print_progress_bar(
            i + 1,
            total_iterations,
            prefix="Progress:",
            suffix="Complete",
            length=50,
        )

        # Determine the number of accumulations (random between 1 and 20)
        num_accumulations = randint(1, 20)

        # Initialize the accumulated expected output for this cycle
        accumulated_output = 0

        for _ in range(num_accumulations):
            # Generate Random Inputs and set them to DUT
            random_operand1, random_operand2 = get_random_operands(
                min_val, max_val
            )
            dut.i_operand1.value = random_operand1
            dut.i_operand2.value = random_operand2

            # Compute Expected Accumulated Output
            if generics["DO_MULTIPLICATION"] == 1:
                accumulated_output += random_operand1 * random_operand2
            else:
                accumulated_output += random_operand1 + random_operand2

            # Ensure accumulated output fits within the output width
            max_accumulated_value = 2 ** (generics["OUTPUT_WIDTH"] - 1) - 1
            min_accumulated_value = -(2 ** (generics["OUTPUT_WIDTH"] - 1))
            if accumulated_output > max_accumulated_value:
                accumulated_output -= 2 ** generics["OUTPUT_WIDTH"]
            elif accumulated_output < min_accumulated_value:
                accumulated_output += 2 ** generics["OUTPUT_WIDTH"]

            # Enable the DUT
            dut.i_valid.value = 1
            await RisingEdge(dut.clock)
            dut.i_valid.value = 0

            # Wait one clock cycle
            await RisingEdge(dut.clock)

            # Output Check after accumulation
            gotten_output = dut.o_result.value.signed_integer
            assert (
                accumulated_output == gotten_output
            ), f"DUT output incorrect, Expected: {accumulated_output}, Gotten {gotten_output} at iteration {i}"

        # Clear the DUT
        dut.i_clear.value = 1
        await RisingEdge(dut.clock)
        dut.i_clear.value = 0
        await RisingEdge(dut.clock)
        assert dut.o_result.value == 0, "DUT output was not reset correctly"

        # Reset the accumulated output and start again
        accumulated_output = 0

    dut._log.info("\nRandom Accumulation test with varying lengths passed.")
