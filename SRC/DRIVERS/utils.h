#ifndef UTILS_H_ /* Include guard */
#define UTILS_H_

//
// INCLUDES
//

#include "stdint.h"
#include "conv2d.h"
#include "xparameters.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "sleep.h"

//
// DEFINES
//

#define CLEAR_TERMINAL "\e[1;1H\e[2J"
#define USLEEP_TIME 5

#define INPUT_SIZE 5
#define CHANNEL_NUMBER 3
#define KERNEL_SIZE 3
#define KERNEL_NUMBER 3
#define STRIDE 1
#define PADDING 1
#define OUTPUT_SIZE (INPUT_SIZE + 2 * PADDING - KERNEL_SIZE) / STRIDE + 1

#define INVALID_CHANGE 0x0
#define I_SYS_ENABLE 0x1
#define I_DATA_VALID 0x2
#define INPUT_VALID_CHANGE 0x4
#define OUTPUT_VALID_CHANGE 0x8
#define OUTPUT_VALID 0x1

// Register offsets
#define REG0_OFFSET CONV2D_S00_AXI_SLV_REG0_OFFSET
#define REG1_OFFSET CONV2D_S00_AXI_SLV_REG1_OFFSET
#define REG2_OFFSET CONV2D_S00_AXI_SLV_REG2_OFFSET
#define REG3_OFFSET CONV2D_S00_AXI_SLV_REG3_OFFSET
#define REG4_OFFSET CONV2D_S00_AXI_SLV_REG4_OFFSET
#define REG5_OFFSET CONV2D_S00_AXI_SLV_REG5_OFFSET
#define REG6_OFFSET CONV2D_S00_AXI_SLV_REG6_OFFSET
#define REG7_OFFSET CONV2D_S00_AXI_SLV_REG7_OFFSET

//
// PROTOTYPES
//

void toggle_reg0(int32_t base_addr, int32_t value);
void write_matrix(int32_t base_addr, int32_t channel_value, int32_t row, int32_t col, int32_t value);
void initialize_matrix(int32_t base_addr, int32_t input_volume[CHANNEL_NUMBER][INPUT_SIZE][INPUT_SIZE]);
void write_kernel(int32_t base_addr, int32_t kernel_number, int32_t channel_number, int32_t row, int32_t col, int32_t value);
void initialize_kernel(int32_t base_addr, int32_t kernel_volume[KERNEL_NUMBER][CHANNEL_NUMBER][KERNEL_SIZE][KERNEL_SIZE]);
void write_bias(int32_t base_addr, int32_t value);
void initialize_bias(int32_t base_addr, int32_t bias_value);
int32_t read_output(int32_t base_addr, int32_t channel_value, int32_t row, int32_t col);
void read_output_matrix(int32_t base_addr, int32_t output_volume[KERNEL_NUMBER][OUTPUT_SIZE][OUTPUT_SIZE]);

#endif // UTILS_H_
