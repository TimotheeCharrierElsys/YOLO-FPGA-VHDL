#include "utils.h"

int main()
{
    int32_t base_addr = XPAR_CONV2D_0_S00_AXI_BASEADDR;

    int32_t input_volume[CHANNEL_NUMBER][INPUT_SIZE][INPUT_SIZE] = {
        {{1, 1, 1, 1, 1},
         {1, 1, 1, 1, 1},
         {1, 1, 1, 1, 1},
         {1, 1, 1, 1, 1},
         {1, 1, 1, 1, 1}},
        {{1, 1, 1, 1, 1},
         {1, 1, 1, 1, 1},
         {1, 1, 1, 1, 1},
         {1, 1, 1, 1, 1},
         {1, 1, 1, 1, 1}},
        {{1, 1, 1, 1, 1},
         {1, 1, 1, 1, 1},
         {1, 1, 1, 1, 1},
         {1, 1, 1, 1, 1},
         {1, 1, 1, 1, 1}}};

    int32_t kernel_volume[KERNEL_NUMBER][CHANNEL_NUMBER][KERNEL_SIZE][KERNEL_SIZE] = {
        // First Kernel is Filter Emboss
        {{{-1, -1, -1},
          {-1, 8, -1},
          {-1, -1, -1}},
         {{-1, -1, -1},
          {-1, 8, -1},
          {-1, -1, -1}},
         {{-1, -1, -1},
          {-1, 8, -1},
          {-1, -1, -1}}},

        // Second Kernel is Filter Identity
        {{{1, 0, 0},
          {0, 1, 0},
          {0, 0, 1}},
         {{1, 0, 0},
          {0, 1, 0},
          {0, 0, 1}},
         {{1, 0, 0},
          {0, 1, 0},
          {0, 0, 1}}},

        // Third Kernel is Filter Sharp
        {{{0, -1, 0},
          {-1, 5, -1},
          {0, -1, 0}},
         {{0, -1, 0},
          {-1, 5, -1},
          {0, -1, 0}},
         {{0, -1, 0},
          {-1, 5, -1},
          {0, -1, 0}}}};

    int32_t bias_value = 0x0;
    int32_t output_volume[KERNEL_NUMBER][OUTPUT_SIZE][OUTPUT_SIZE] = {{{0}}};

    // Reset Terminal
    xil_printf(CLEAR_TERMINAL);

    xil_printf("Initializing Matrix\r\n");
    initialize_matrix(base_addr, input_volume);

    xil_printf("Initializing Kernels\r\n");
    initialize_kernel(base_addr, kernel_volume);

    xil_printf("Initializing Biases\r\n");
    initialize_bias(base_addr, bias_value);

    //
    // Set i_data_valid bit to 1
    //

    toggle_reg0(base_addr, I_SYS_ENABLE | I_DATA_VALID);
    toggle_reg0(base_addr, I_SYS_ENABLE);

    while (CONV2D_mReadReg(base_addr, REG7_OFFSET) != OUTPUT_VALID)
    {
    }

    xil_printf("Reading Output Matrix\r\n");
    read_output_matrix(base_addr, output_volume);

    print_matrix(output_volume);
    xil_printf("Done\r\n");

    xil_printf("Entering Blocking Loop\r\n");
    while (1)
    {
    }

    return 0;
}
