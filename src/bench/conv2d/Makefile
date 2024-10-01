# Makefile for simulating VHDL code with nvc and cocotb

# Directory containing VHDL source files
SRC_DIR			:= ../../../rtl

# VHDL Source Files
VHDL_SOURCES	:= $(SRC_DIR)/types_pkg.vhd \
				$(SRC_DIR)/common/silu_activation.vhd \
				$(SRC_DIR)/mac/mac.vhd \
				$(SRC_DIR)/window_slice/volume_slice.vhd \
				$(SRC_DIR)/conv2d/conv2d_layer.vhd \
				$(SRC_DIR)/conv2d/conv2d_layer.vhd \
				$(SRC_DIR)/conv2d/conv2d.vhd \

# Cocotb and nvc flags
SIM					:= nvc
TOPLEVEL_LANG		:= vhdl
TOPLEVEL			:= conv2d
COCOTB_TEST_MODULES	:= test_conv2d
MODULE				:= $(COCOTB_TEST_MODULES) # Retrocompatibility
RTL_LIBRARY			:= LIB_RTL

# Generic Parameters
SIM_ARGS			+= -gDATA_SCALE_FACTOR=0 -gBITWIDTH=8 
SIM_ARGS			+= -gOUTPUT_CHANNELS=3 -gINPUT_CHANNELS=3 -gINPUT_SIZE=64
SIM_ARGS			+= -gKERNEL_SIZE=3 -gPADDING=1 -gSTRIDE=1

# Calling cocotb
PWD 				:= $(shell pwd)
export PYTHONPATH	:= $(PWD)/../model:$(PYTHONPATH)
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf $(LIB) $(WAVE_FILE) results.xml __pycache__ sim_build