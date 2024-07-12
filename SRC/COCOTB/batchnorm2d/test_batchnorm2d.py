import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import matplotlib.pyplot as plt
from random import randrange
import torch


def batchnorm2d(data, mean, var, weight, bias, epsilon=0):
    return (data-mean)/(np.sqrt(var+epsilon))*weight + bias


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
    dut.i_mean.value = 0
    dut.i_var.value = 0
    dut.i_weight.value = 0
    dut.i_bias.value = 0
    dut.i_valid.value = 0

    # Apply reset and check output
    await reset_dut(dut)
    assert dut.o_data.value == 0, "Output was not reset correctly"

    assert dut.o_data_valid.value == 0, "Output valid was not reset correctly"
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
    await RisingEdge(dut.clock)
    assert dut.o_data.value == 0, "Output was not reset correctly"

    shape = (1, 4, 32, 32)
    low = -100
    high = 100

    # Generate the random integer tensor
    input_tensor = torch.randint(low, high, shape).float()
    torch_channel_mean = torch.mean(input_tensor, dim=(2, 3))
    # torch_channel_var = torch.var(input_tensor, dim=(2, 3), unbiased=False)
    torch_channel_var = torch.tensor([[1,1,1,1]])

    shape_w_b = (1, 4, 32, 32)
    low_w_b = -10
    high_w_b = 10
    w_tensor = torch.randint(low_w_b, high_w_b, shape_w_b).float()
    b_tensor = torch.randint(1, high_w_b, shape_w_b).float()

    print(f"Mean = {torch_channel_mean}")
    print(f"Var  = {torch_channel_var}")

    output_expected = []
    output_gotten = []

    for C in range(shape[1]):
        for row in range(shape[2]):
            for col in range(shape[3]):
                dut.i_valid.value = 1
                dut.i_data.value = int(input_tensor[0][C][row][col].item())
                dut.i_mean.value = int(torch_channel_mean[0][C].item())
                dut.i_var.value = int(torch_channel_var[0][C].item())
                dut.i_weight.value = int(w_tensor[0][C][row][col].item())
                dut.i_bias.value = int(b_tensor[0][C][row][col].item())
                await RisingEdge(dut.clock)
                dut.i_valid.value = 0

                output_expected.append(batchnorm2d(input_tensor[0][C][row][col].item(),
                                                   torch_channel_mean[0][C].item(),
                                                   torch_channel_var[0][C].item(),
                                                   w_tensor[0][C][row][col].item(),
                                                   b_tensor[0][C][row][col].item()))

                # Wait a few clock cycles to allow the DUT to process
                for _ in range(6):
                    await RisingEdge(dut.clock)
                output_gotten.append(dut.o_data.value.signed_integer)
                print(f"Expected={output_expected[-1]}, Gotten = {output_gotten[-1]}")
                
    # Plot the results
    plot_results(output_expected, output_gotten)

def plot_results(output_expected, output_gotten):
    plt.figure(figsize=(12, 6))

    # Plot expected vs gotten outputs
    plt.subplot(1, 2, 1)
    plt.plot(output_expected, label='Expected')
    plt.plot(output_gotten, label='Gotten', linestyle='--')
    plt.xlabel('Sample Index')
    plt.ylabel('Output Value')
    plt.title('Expected vs Gotten Outputs')
    plt.legend()

    # Plot difference
    differences = [expected - gotten for expected, gotten in zip(output_expected, output_gotten)]
    plt.subplot(1, 2, 2)
    plt.plot(differences, label='Difference')
    plt.xlabel('Sample Index')
    plt.ylabel('Difference Value')
    plt.title('Difference between Expected and Gotten Outputs')
    plt.legend()

    plt.tight_layout()
    plt.show()
    
