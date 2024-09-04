# Makefile for simulating VHDL code with nvc and cocotb

# Directory containing VHDL source files
SRC_DIR			:= ../../../rtl

# VHDL Source Files
VHDL_SOURCES  := $(SRC_DIR)/types_pkg.vhd \
				$(SRC_DIR)/common/pipeline.vhd \
				$(SRC_DIR)/common/adder_tree.vhd \
				$(SRC_DIR)/common/silu_activation.vhd \
				$(SRC_DIR)/mac/mac.vhd \
				$(SRC_DIR)/mac/fc_layer.vhd \
				$(SRC_DIR)/window_slice/volume_slice.vhd \
				$(SRC_DIR)/conv2d/conv2d_layer.vhd \
				$(SRC_DIR)/conv2d/conv2d_layer_mac.vhd \
				$(SRC_DIR)/conv2d/conv2d.vhd \

# COCOTB Flags
SIM					:= nvc
TOPLEVEL_LANG		:= vhdl
TOPLEVEL			:= conv2d
COCOTB_TEST_MODULES	:= test_conv2d
MODULE				:= $(COCOTB_TEST_MODULES) # Retrocompatibility
RTL_LIBRARY			:= LIB_RTL

# Generic Parameters (unfortunately, I was not able to set std_logic as generic in the Makefile,
# so to use different architectures, you need to change the VHDL code)
SIM_ARGS			+= -gDATA_SCALE_FACTOR=0 -gBITWIDTH=16 
SIM_ARGS			+= -gOUTPUT_CHANNELS=3 -gINPUT_CHANNELS=3 -gINPUT_SIZE=64
SIM_ARGS			+= -gKERNEL_SIZE=3 -gPADDING=1 -gSTRIDE=1

# COCOTB Log Level
PWD 					:= $(shell pwd)
export PYTHONPATH	:= $(PWD)/../model:$(PYTHONPATH)
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf $(LIB) $(WAVE_FILE) results.xml __pycache__ sim_build