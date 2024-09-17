# Makefile for simulating VHDL code with nvc and cocotb

# Directory containing VHDL source files
SRC_DIR			:= ../../../rtl

# VHDL Source Files
VHDL_SOURCES	:= $(SRC_DIR)/types_pkg.vhd \
				$(SRC_DIR)/common/pipeline.vhd \
				$(SRC_DIR)/common/silu_activation.vhd \
				$(SRC_DIR)/conv2d/mac.vhd \
				$(SRC_DIR)/batchnorm2d/batchnorm2d_layer.vhd \
				$(SRC_DIR)/conv2d/conv2d_layer_mac.vhd \
				$(SRC_DIR)/conv/conv_fsm.vhd \
				$(SRC_DIR)/conv/conv.vhd

# Cocotb and nvc flags
SIM					:= nvc
TOPLEVEL_LANG		:= vhdl
TOPLEVEL			:= conv
COCOTB_TEST_MODULES	:= test_conv
MODULE				:= $(COCOTB_TEST_MODULES) # Retrocompatibility
RTL_LIBRARY			:= LIB_RTL

# Generic Parameters (unfortunately, I was not able to set std_logic as generic in the Makefile,
# so to use different architectures, you need to change the VHDL code)
SIM_ARGS			+= -gDATA_SCALE_FACTOR=12 -gBITWIDTH=16
SIM_ARGS			+= -gOUTPUT_CHANNELS=32 -gINPUT_CHANNELS=1 -gINPUT_SIZE=28
SIM_ARGS			+= -gKERNEL_SIZE=3 -gPADDING=1 -gSTRIDE=2

# Calling cocotb
PWD 				:= $(shell pwd)
export PYTHONPATH	:= $(PWD)/../model:$(PYTHONPATH)
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf $(LIB) $(WAVE_FILE) results.xml __pycache__ sim_build