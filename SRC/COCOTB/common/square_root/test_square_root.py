import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import matplotlib.pyplot as plt


async def reset_dut(dut):
    """Reset the DUT."""
    dut.reset_n.value = 0
    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)
    dut.reset_n.value = 1
    await RisingEdge(dut.clock)
    dut._log.info("DUT reset complete.")


async def enable_dut(dut):
    """Enable the DUT."""
    dut.i_sys_enable.value = 1
    await RisingEdge(dut.clock)
    dut._log.info("DUT enabled.")


@cocotb.test()
async def reset_test(dut):
    # Start the clock
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.start_soon(clock.start(start_high=False))

    # Input data
    dut.i_sys_enable.value = 0
    dut.i_data.value = 0

    # Apply reset and check output
    await reset_dut(dut)
    assert dut.o_data.value == 0, "Output was not reset correctly"
    dut._log.info("Reset test passed.")


@cocotb.test()
async def computation_test(dut):

    # Start the clock
    clock = Clock(dut.clock, 10, units="ns")
    cocotb.start_soon(clock.start(start_high=False))

    # Apply reset and check output
    await reset_dut(dut)
    assert dut.o_data.value == 0, "Output was not reset correctly"

    # Enable the system
    dut.i_sys_enable.value = 1

    # Test for x > 1
    X = np.arange(0, 65534)
    expected_output = np.sqrt(X)
    gotten_output = []

    for i in X:
        dut.i_data.value = int(i)
        await RisingEdge(dut.clock)

        output_value = dut.o_data.value.integer
        gotten_output.append(output_value)

    # Plot the results
    plt.figure()
    plt.plot(X, expected_output, label='Expected')
    plt.plot(X, gotten_output, label='Gotten')
    plt.legend()
    plt.show()

    # Plot absolute error
    abs_error = np.abs(expected_output - gotten_output)
    plt.figure()
    plt.plot(X, abs_error, label='Absolute Error')
    plt.legend()
    plt.show()


def test_scale_factor():
    X = np.linspace(0, 65535, 100000)
    expected_output = np.sqrt(X)
    gotten_output = np.sqrt(X * 1e6) / 1024

    plt.plot(X, expected_output, label='Expected')
    plt.plot(X, gotten_output, label='gotten')
    plt.legend()
    plt.show()