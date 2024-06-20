import random
import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
from sklearn.metrics import mean_absolute_error, mean_squared_error, root_mean_squared_error, r2_score
import os

plt.rcParams['text.usetex'] = True
plt.rcParams["font.family"] = "Arial"


def relu6(x):
    return np.minimum(np.maximum(x, 0), 6 * 1024)


def hardswish(x_prime):
    return x_prime * relu6(x_prime + 3 * 1024) / (6 * 1024)


def hs(x):
    if x <= -3:
        return 0
    elif x > -3 and x < 3:
        return x * (x+3)/6
    else:
        return x


def silu(x):
    return x/(1 + np.exp(-x))*1024


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

    X = np.arange(-7 * 1024, 7 * 1024)
    Y = []
    gotten_output = []

    tolerance = 0.1  # Set your tolerance level here
    tolerance_limit = tolerance * (2**(dut.o_data.value.n_bits - 1))

    dut._log.info(
        f"DUT computation test starting with tolerance set to {(1-tolerance) * 100}%")

    abs_error_list = []

    for i in X:
        dut.i_data.value = int(i)
        await RisingEdge(dut.clock)

        # Convert the output data to signed integer
        output_value = dut.o_data.value.signed_integer

        gotten_output.append(output_value)

        # Calculate expected output
        expected_value = silu(i/1024)
        Y.append(expected_value)

        # Calculate absolute error
        abs_error = abs(output_value - expected_value)
        abs_error_list.append(abs_error)

        # Assertion with tolerance check
        assert abs_error <= tolerance_limit, \
            f"Output mismatch: Expected {expected_value}, Got {output_value} for input {i}"

    # Save absolute error list to a file
    abs_error_file = os.path.join(
        os.path.dirname(__file__), "absolute_errors8.txt")
    with open(abs_error_file, "w") as file:
        for error in abs_error_list:
            file.write(f"{error}\n")

    MAE = mean_absolute_error(Y, gotten_output, multioutput='raw_values')
    MSE = mean_squared_error(Y, gotten_output, multioutput='raw_values')
    RMSE = root_mean_squared_error(
        Y, gotten_output, multioutput='raw_values')
    R2 = r2_score(Y, gotten_output, multioutput='raw_values')

    dut._log.info(f"MSE={MSE}, MAE={MAE}, RMSE={RMSE}, R-Squared={R2}")

    # Plotting results
    plt.figure(figsize=(4, 4))

    plt.plot(X, Y, label='Expected', color='blue')
    plt.plot(X, gotten_output, label='Gotten', color='red')
    plt.grid(True)
    plt.legend()
    plt.xlabel('Input')
    plt.ylabel('Output')
    plt.title('Y = f(X)')
    plt.grid(True)
    plt.legend()

    plt.tight_layout()
    plt.show()


def read_and_plot_errors(file_path):
    # Read the absolute error values from the file
    with open(file_path, "r") as file:
        abs_error_list = [float(line.strip()) for line in file]

    return abs_error_list


def plot_silu():
    X = np.linspace(-7, 7, 5000)
    Y = [silu(x)/1024 for x in X]
    Z = [hs(x) for x in X]

    plt.plot(X, Y, linewidth=2, label='SiLU')
    plt.plot(X, Z, linewidth=2, label='Hard-swish')
    plt.grid(True)
    plt.xlabel('x', fontsize=12)
    plt.ylabel('y', fontsize=12)
    plt.title('y = SiLU(x)', fontsize=12)
    plt.legend()
    plt.tight_layout()
    plt.savefig("silu_hardswish_plot.svg", format="svg")
    plt.show()


def plot_compare_error():
    X = np.linspace(-7, 7, 5000)
    Y = [silu(x)/1024 for x in X]
    Z = [hs(x) for x in X]

    # Create a figure and a set of subplots
    fig, ax = plt.subplots()
    ax.plot(X, Y, linewidth=2, label='SiLU')
    ax.plot(X, Z, linewidth=2, label='Hard-swish')
    # Set the grid
    ax.grid(True, linestyle='--', alpha=0.6)
    ax.set_xlabel('x', fontsize=14)
    ax.set_ylabel('y', fontsize=14)
    ax.set_title('y = SiLU(x)', fontsize=16)
    ax.legend()
    ax.ticklabel_format(style='sci', axis='both', scilimits=(0, 0))
    plt.tight_layout()
    plt.savefig("silu_hardswish_plot.svg", format="svg")
    plt.show()


def plot_error():
    X = np.arange(-7 * 1024, 7 * 1024)

    error10 = read_and_plot_errors(
        r"/home/tim/YOLO-FPGA-VHDL/SRC/COCOTB/common/silu_activation/absolute_errors10.txt")
    error11 = read_and_plot_errors(
        r"/home/tim/YOLO-FPGA-VHDL/SRC/COCOTB/common/silu_activation/absolute_errors11.txt")
    error12 = read_and_plot_errors(
        r"/home/tim/YOLO-FPGA-VHDL/SRC/COCOTB/common/silu_activation/absolute_errors12.txt")
    error13 = read_and_plot_errors(
        r"/home/tim/YOLO-FPGA-VHDL/SRC/COCOTB/common/silu_activation/absolute_errors13.txt")
    error9 = read_and_plot_errors(
        r"/home/tim/YOLO-FPGA-VHDL/SRC/COCOTB/common/silu_activation/absolute_errors9.txt")
    error8 = read_and_plot_errors(
        r"/home/tim/YOLO-FPGA-VHDL/SRC/COCOTB/common/silu_activation/absolute_errors8.txt")

    # Create a figure and a set of subplots
    fig, ax = plt.subplots()

    # Plot the data
    ax.plot(X, error8, label="N=8")
    ax.plot(X, error9, label="N=9")
    ax.plot(X, error10, label="N=10")
    ax.plot(X, error11, label="N=11")
    ax.plot(X, error12, label="N=12")
    ax.plot(X, error13, label="N=13")

    # Set the grid
    ax.grid(True, linestyle='--', alpha=0.6)

    # Set the legend
    ax.legend(loc='best', fontsize='large', title='Scale Factors')

    # Set labels and title with increased font size
    ax.set_xlabel('Input Value', fontsize=14)
    ax.set_ylabel('Absolute Error Value', fontsize=14)
    ax.set_title(
        'Comparison of Absolute Error with Different Division Scale Factors', fontsize=16)

    # Use scientific notation for large numbers on axes
    ax.ticklabel_format(style='sci', axis='both', scilimits=(0, 0))

    # Improve layout
    plt.tight_layout()
    plt.savefig("absolute_error.svg", format='svg')
    # Show the plot
    plt.show()


if __name__ == "__main__":
    plot_error()
