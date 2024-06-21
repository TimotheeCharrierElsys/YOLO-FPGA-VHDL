# Directories
SRC_DIR             := /home/tim/YOLO-FPGA-VHDL/SRC/RTL
BENCH_DIR           := /home/tim/YOLO-FPGA-VHDL/SRC/BENCH
BUILD_DIR           := build

# Files
SOURCES             := $(SRC_DIR)/types_pkg.vhd \
					   $(SRC_DIR)/common/pipeline.vhd \
					   $(SRC_DIR)/common/adder_tree.vhd \
					   $(SRC_DIR)/common/silu_activation.vhd \
					   $(SRC_DIR)/mac/mac.vhd \
					   $(SRC_DIR)/mac/accumulative_mac.vhd \
					   $(SRC_DIR)/mac/fc_layer.vhd \
					   $(SRC_DIR)/window_slice/volume_slice.vhd \
					   $(SRC_DIR)/conv/conv2d_layer.vhd \
					   $(SRC_DIR)/conv/conv2d.vhd \
					   $(SRC_DIR)/maxpool/maxpool2d_layer.vhd \

TESTBENCH           := $(BENCH_DIR)/maxpool/maxpool2d_layer_tb.vhd
TOPLEVEL            := maxpool2d_layer_tb
WAVE_FILE           := wave_$(TOPLEVEL).vcd

# GHDL Settings
GHDL_CMD            := ghdl
GHDL_FLAGS          := --std=08 -Wno-error -v --work=LIB_RTL

# Simulation Settings
S_TIME              := 100ns

# Targets
.PHONY: all compile simulate clean

all: compile simulate

compile:
	@mkdir -p $(BUILD_DIR)
	$(GHDL_CMD) -a $(GHDL_FLAGS) $(SOURCES) $(TESTBENCH)
	$(GHDL_CMD) -e $(GHDL_FLAGS) $(TOPLEVEL)

simulate: compile
	$(GHDL_CMD) -r $(GHDL_FLAGS) $(TOPLEVEL) --vcd=$(BUILD_DIR)/$(WAVE_FILE) --wave=$(BUILD_DIR)/$(TOPLEVEL).ghw --stop-time=$(S_TIME) --max-stack-alloc=1024000

clean:
	@rm -rf $(BUILD_DIR) lib_rtl-obj08.cf
