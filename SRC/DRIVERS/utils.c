#include "utils.h"

void toggle_reg0(int32_t base_addr, int32_t value)
{
    CONV2D_mWriteReg(base_addr, REG0_OFFSET, value);
}

void write_matrix(int32_t base_addr, int32_t channel_value, int32_t row, int32_t col,
                  int32_t value)
{
    // Write Channel Index
    CONV2D_mWriteReg(base_addr, REG4_OFFSET, channel_value);

    // Write Row and Col Index
    int32_t row_col_combined = (col << 16) | (row & 0xFFFF);
    CONV2D_mWriteReg(base_addr, REG3_OFFSET, row_col_combined);

    // Set the value of the matrix[n][row][col]
    CONV2D_mWriteReg(base_addr, REG1_OFFSET, value);
}

void initialize_matrix(
    int32_t base_addr, int32_t input_volume[CHANNEL_NUMBER][INPUT_SIZE][INPUT_SIZE])
{
    // Reset Input Matrix
    for (int32_t n = 0; n < CHANNEL_NUMBER; n++)
    {
        for (int32_t row = 0; row < INPUT_SIZE; row++)
        {
            for (int32_t col = 0; col < INPUT_SIZE; col++)
            {
                // Write the Current Value
                write_matrix(base_addr, n, row, col, input_volume[n][row][col]);

                // Toggle Input Valid to valid
                toggle_reg0(base_addr, I_SYS_ENABLE | INPUT_VALID_CHANGE);

                // Sleep for few us
                usleep(USLEEP_TIME);

                // Toggle Input Valid to invalid
                toggle_reg0(base_addr, I_SYS_ENABLE);

                int32_t output_value = CONV2D_mReadReg(base_addr, REG1_OFFSET);
                xil_printf("%d ", output_value);
            }
            xil_printf("\r\n");
        }
        xil_printf("\r\n");
    }
}

void write_kernel(int32_t base_addr, int32_t kernel_number, int32_t channel_number, int32_t row, int32_t col,
                  int32_t value)
{
    // Write Kernel Number
    int32_t kernel_channel_combined = (kernel_number << 16) | (channel_number & 0xFFFF);
    CONV2D_mWriteReg(base_addr, REG4_OFFSET, kernel_channel_combined);

    // Write Row and Col Index
    int32_t row_col_combined = (col << 16) | (row & 0xFFFF);
    CONV2D_mWriteReg(base_addr, REG3_OFFSET, row_col_combined);

    // Set the value of the kernel[n][row][col]
    CONV2D_mWriteReg(base_addr, REG1_OFFSET, (value << 16));
}

void initialize_kernel(int32_t base_addr,
                       int32_t kernel_volume[KERNEL_NUMBER][CHANNEL_NUMBER]
                                            [KERNEL_SIZE][KERNEL_SIZE])
{
    // Reset Input Kernels
    for (int32_t n = 0; n < KERNEL_NUMBER; n++)
    {
        for (int32_t c = 0; c < CHANNEL_NUMBER; c++)
        {
            for (int32_t row = 0; row < KERNEL_SIZE; row++)
            {
                for (int32_t col = 0; col < KERNEL_SIZE; col++)
                {
                    // Toggle Input Valid to invalid
                    toggle_reg0(base_addr, I_SYS_ENABLE);

                    // Write the Current Value
                    write_kernel(base_addr, n, c, row, col, kernel_volume[n][c][row][col]);

                    // Toggle Input Valid to valid
                    toggle_reg0(base_addr, I_SYS_ENABLE | INPUT_VALID_CHANGE);

                    // Sleep for few us
                    usleep(USLEEP_TIME);
                }
            }
        }
    }
}

void write_bias(int32_t base_addr, int32_t value)
{
    // Set the value of the bias
    CONV2D_mWriteReg(base_addr, REG2_OFFSET, value);
}

void initialize_bias(int32_t base_addr, int32_t bias_value)
{
    // Toggle Input Valid to invalid
    toggle_reg0(base_addr, I_SYS_ENABLE);

    // Write the Current Value
    write_bias(base_addr, bias_value);

    // Toggle Input Valid to valid
    toggle_reg0(base_addr, I_SYS_ENABLE | INPUT_VALID_CHANGE);

    // Toggle Input Valid to invalid
    toggle_reg0(base_addr, I_SYS_ENABLE);
}

int32_t read_output(int32_t base_addr, int32_t channel_value, int32_t row, int32_t col)
{
    // Write Channel Index
    CONV2D_mWriteReg(base_addr, REG4_OFFSET, 0x00000000);
    CONV2D_mWriteReg(base_addr, REG4_OFFSET, channel_value);

    // Write Row and Col Index
    int32_t row_col_combined = (col << 16) | (row & 0xFFFF);
    CONV2D_mWriteReg(base_addr, REG3_OFFSET, 0x00000000);
    CONV2D_mWriteReg(base_addr, REG3_OFFSET, row_col_combined);

    // Toggle Input Valid to valid
    toggle_reg0(base_addr, I_SYS_ENABLE | OUTPUT_VALID_CHANGE);

    // Read the value of the output matrix[n][row][col]
    int32_t output_value = CONV2D_mReadReg(base_addr, REG6_OFFSET);

    // Toggle Input Valid to invalid
    toggle_reg0(base_addr, I_SYS_ENABLE);

    return output_value;
}

void read_output_matrix(
    int32_t base_addr, int32_t output_volume[KERNEL_NUMBER][OUTPUT_SIZE][OUTPUT_SIZE])
{
    // Iterate Over the Output Matrix Shape
    for (int32_t n = 0; n < KERNEL_NUMBER; n++)
    {
        for (int32_t row = 0; row < OUTPUT_SIZE; row++)
        {
            for (int32_t col = 0; col < OUTPUT_SIZE; col++)
            {
                // Write the Current Value
                int32_t out = read_output(base_addr, n, row, col);

                output_volume[n][row][col] = out;
                xil_printf("%d ", out);
            }
            xil_printf("\r\n");
        }
        xil_printf("\r\n");
    }
}

void print_matrix(int32_t output_volume[KERNEL_NUMBER][OUTPUT_SIZE][OUTPUT_SIZE])
{
    for (int32_t n = 0; n < KERNEL_NUMBER; n++)
    {
        xil_printf("Output Matrix %lu:\r\n", n);
        for (int32_t row = 0; row < OUTPUT_SIZE; row++)
        {
            for (int32_t col = 0; col < OUTPUT_SIZE; col++)
            {
                xil_printf("%08lx ", output_volume[n][row][col]);
            }
            xil_printf("\r\n");
        }
        xil_printf("\r\n");
    }
}
