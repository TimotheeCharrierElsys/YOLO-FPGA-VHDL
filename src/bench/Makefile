# Makefile for simulating VHDL code with GHDL or nvc

# Directory containing VHDL source files
SRC_DIR     := ../rtl
BENCH_DIR   := .

TOP_ENTITY  := conv_mnist_2_layers
STOP_TIME   := 100us

# VHDL Source Files
SOURCES     := $(SRC_DIR)/types_pkg.vhd \
			   $(SRC_DIR)/common/pipeline.vhd \
			   $(SRC_DIR)/common/adder_tree.vhd \
			   $(SRC_DIR)/common/silu_activation.vhd \
			   $(SRC_DIR)/mac/mac.vhd \
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
			   $(BENCH_DIR)/mac/mac_tb.vhd \
			   $(BENCH_DIR)/mac/fc_layer_tb.vhd \
			   $(BENCH_DIR)/window_slice/volume_slice_tb.vhd \
			   $(BENCH_DIR)/conv2d/conv2d_layer_fc_tb.vhd \
			   $(BENCH_DIR)/conv2d/conv2d_layer_mac_tb.vhd \
			   $(BENCH_DIR)/conv2d/conv2d_tb.vhd \
			   $(BENCH_DIR)/conv2d/conv2d_small_tb.vhd \
			   $(BENCH_DIR)/maxpool2d/maxpool2d_layer_tb.vhd \
			   $(BENCH_DIR)/maxpool2d/maxpool2d_tb.vhd \
			   $(BENCH_DIR)/batchnorm2d/batchnorm2d_layer_tb.vhd \
			   $(BENCH_DIR)/batchnorm2d/batchnorm2d_tb.vhd \
			   $(BENCH_DIR)/conv/conv_tb.vhd \
			   $(BENCH_DIR)/conv/conv_mnist_2_layers.vhd \
			   $(BENCH_DIR)/conv/conv_mnist.vhd

NVC_TESTBENCH := $(BENCH_DIR)/conv/conv_mnist_2_layers.vhd

# Work Directory
WORK_DIR    := work

# GHDL Flags
LIB             := LIB_RTL
GHDL_COMMON_FLAGS := --std=08 --ieee=standard --work=$(LIB) --workdir=$(WORK_DIR) -O2
GHDL_WARNINGS   := -Wall -Wdelayed-checks --syn-binding
GHDL_SIM_FLAGS  := --stop-time=$(STOP_TIME) #--wave=$(WORK_DIR)/wave_$(TOP_ENTITY).ghw

# NVC Flags
NVC_FLAGS       := --work=$(LIB) -M128m
NVC_SIM_FLAGS   := --stop-time=$(STOP_TIME) --wave --dump-array

# Default target
all: simulate_ghdl

# Create work directory if it doesn't exist
$(WORK_DIR):
	@echo "Creating work directory..."
	mkdir -p $(WORK_DIR)

# GHDL Targets
analyze_ghdl: $(WORK_DIR)
	@echo "Analyzing with GHDL..."
	@ghdl -i $(GHDL_COMMON_FLAGS) $(GHDL_WARNINGS) $(SOURCES) $(TESTBENCHES) || exit 1

elaborate_ghdl: analyze_ghdl
	@echo "Elaborating with GHDL..."
	@ghdl -m $(GHDL_COMMON_FLAGS) $(GHDL_WARNINGS) $(TOP_ENTITY) || exit 1

simulate_ghdl: elaborate_ghdl
	@echo "Simulating with GHDL..."
	@ghdl -r $(GHDL_COMMON_FLAGS) $(TOP_ENTITY) $(GHDL_SIM_FLAGS) --max-stack-alloc=0 || exit 1

wave_ghdl: simulate_ghdl
	@echo "Launching GTKWave for GHDL..."
	@gtkwave $(WORK_DIR)/wave_$(TOP_ENTITY).ghw &

# NVC Targets
analyze_nvc: $(WORK_DIR)
	@echo "Analyzing with NVC..."
	@nvc $(NVC_FLAGS) -a $(SOURCES) $(NVC_TESTBENCH) || exit 1

elaborate_nvc: analyze_nvc
	@echo "Elaborating with NVC..."
	@nvc $(NVC_FLAGS) -e $(TOP_ENTITY) || exit 1

simulate_nvc: elaborate_nvc
	@echo "Simulating with NVC..."
	@nvc $(NVC_FLAGS) -r $(NVC_SIM_FLAGS) $(TOP_ENTITY) || exit 1

wave_nvc: simulate_nvc
	@echo "Launching GTKWave for NVC..."
	@gtkwave $(TOP_ENTITY).fst

# Clean up the generated files
clean:
	@echo "Cleaning up..."
	rm -rf $(WORK_DIR) $(LIB) $(TOP_ENTITY) *.o *.ghw *.fst

# Phony targets
.PHONY: all analyze_ghdl elaborate_ghdl simulate_ghdl wave_ghdl \
        analyze_nvc elaborate_nvc simulate_nvc wave_nvc clean
