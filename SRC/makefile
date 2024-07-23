# Directories
SRC_DIR			:= ./RTL
BENCH_DIR		:= ./BENCH
BUILD_DIR		:= build

# Files
SOURCES			:= $(SRC_DIR)/types_pkg.vhd \
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
					$(SRC_DIR)/conv/conv.vhd \

TESTBENCH		:= $(BENCH_DIR)/conv/conv_tb.vhd
TOPLEVEL		:= conv_tb
WAVE_FILE		:= wave_$(TOPLEVEL).ghw

# GHDL Settings
GHDL_CMD		:= ghdl
GHDL_FLAGS		:= --std=08 --workdir=$(BUILD_DIR) -O2 --work=LIB_RTL -v

# Simulation Settings
S_TIME			:= 800us

# Targets
.PHONY: all compile simulate clean

all: compile simulate

compile: $(BUILD_DIR)
	@echo "Compiling VHDL sources..."
	$(GHDL_CMD) -a $(GHDL_FLAGS)  $(SOURCES) $(TESTBENCH)
	$(GHDL_CMD) -e $(GHDL_FLAGS) $(TOPLEVEL)

simulate: compile
	@echo "Starting simulation..."
	$(GHDL_CMD) -r $(GHDL_FLAGS) $(TOPLEVEL) --wave=$(BUILD_DIR)/$(WAVE_FILE) --stop-time=$(S_TIME) --max-stack-alloc=0

wave: 
	gtkwave $(BUILD_DIR)/$(WAVE_FILE)&

clean:
	@rm -rf $(BUILD_DIR)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR) $(TOPLEVEL)