# Makefile for simulating VHDL code with GHDL

# Directory containing VHDL source files
SRC_DIR     := ../RTL
BENCH_DIR   := .

TOP_ENTITY  := conv_tb
STOP_TIME   := 800us

# VHDL Source Files
SOURCES     := $(SRC_DIR)/types_pkg.vhd \
               $(SRC_DIR)/common/pipeline.vhd \
               $(SRC_DIR)/common/adder_tree.vhd \
               $(SRC_DIR)/common/silu_activation.vhd \
               $(SRC_DIR)/common/square_root.vhd \
               $(SRC_DIR)/mac/mac.vhd \
               $(SRC_DIR)/mac/accumulative_mac.vhd \
               $(SRC_DIR)/mac/fc_layer.vhd \
               $(SRC_DIR)/window_slice/volume_slice.vhd \
               $(SRC_DIR)/conv2d/conv2d_layer.vhd \
               $(SRC_DIR)/conv2d/conv2d_layer_mac.vhd \
               $(SRC_DIR)/conv2d/conv2d.vhd \
               $(SRC_DIR)/maxpool2d/maxpool2d_layer.vhd \
               $(SRC_DIR)/maxpool2d/maxpool2d.vhd \
               $(SRC_DIR)/batchnorm2d/batchnorm2d_layer.vhd \
               $(SRC_DIR)/batchnorm2d/batchnorm2d.vhd \
               $(SRC_DIR)/conv/conv.vhd

TESTBENCHES := $(BENCH_DIR)/common/pipeline_tb.vhd \
               $(BENCH_DIR)/common/adder_tree_tb.vhd \
               $(BENCH_DIR)/common/silu_activation_tb.vhd \
               $(BENCH_DIR)/common/square_root_tb.vhd \
               $(BENCH_DIR)/mac/mac_tb.vhd \
               $(BENCH_DIR)/mac/accumulative_mac_tb.vhd \
               $(BENCH_DIR)/mac/fc_layer_tb.vhd \
               $(BENCH_DIR)/window_slice/volume_slice_tb.vhd \
               $(BENCH_DIR)/conv2d/conv2d_layer_fc_tb.vhd \
               $(BENCH_DIR)/conv2d/conv2d_layer_mac_tb.vhd \
               $(BENCH_DIR)/conv2d/conv2d_tb.vhd \
               $(BENCH_DIR)/conv2d/conv2d_small_tb.vhd\
               $(BENCH_DIR)/maxpool2d/maxpool2d_layer_tb.vhd \
               $(BENCH_DIR)/maxpool2d/maxpool2d_tb.vhd \
               $(BENCH_DIR)/batchnorm2d/batchnorm2d_layer_tb.vhd \
               $(BENCH_DIR)/batchnorm2d/batchnorm2d_tb.vhd \
               $(BENCH_DIR)/conv/conv_tb.vhd

# Work Directory
WORK_DIR    := work

# GHDL and Yosys Flags
LIB 		:= LIB_RTL
FLAGS       := --std=08 --ieee=standard --work=$(LIB) --workdir=$(WORK_DIR) -O2
WARNINGS	:= -Wdefault-binding -Wparenthesis -Wothers -Wstatic -Werror
SIM_FLAGS   := --stop-time=$(STOP_TIME) --wave=$(WORK_DIR)/wave_$(TOP_ENTITY).ghw

# Default target
all: simulate

# Create work directory if it doesn't exist
$(WORK_DIR):
	mkdir -p $(WORK_DIR)

# Analyze VHDL files
analyze: $(WORK_DIR)
	ghdl -a $(FLAGS) $(WARNINGS) $(SOURCES) $(TESTBENCHES)

# Elaborate the design
elaborate: analyze
	ghdl -e $(FLAGS) $(WARNINGS) -Wdelayed-checks --syn-binding $(TOP_ENTITY)

simulate: elaborate
	ghdl -r $(GHDL_FLAGS) $(TOP_ENTITY) $(SIM_FLAGS) --max-stack-alloc=0

wave: simulate 
	gtkwave $(WORK_DIR)/wave_$(TOP_ENTITY).ghw &

# Clean up the generated files
clean:
	rm -rf $(WORK_DIR) $(TOP_ENTITY) *.o *.ghw

.PHONY: all analyze elaborate simulate wave clean
