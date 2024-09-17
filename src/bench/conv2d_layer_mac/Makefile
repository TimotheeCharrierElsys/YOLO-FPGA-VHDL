# Makefile for simulating VHDL code with nvc and cocotb

# Directory containing VHDL source files
SRC_DIR			:= ../../rtl

# VHDL Source Files
VHDL_SOURCES	:= $(SRC_DIR)/types_pkg.vhd \
				$(SRC_DIR)/batchnorm2d/silu_activation.vhd \
				$(SRC_DIR)/batchnorm2d/batchnorm2d_layer.vhd \
				$(SRC_DIR)/conv2d/mac.vhd \
				$(SRC_DIR)/conv2d/conv2d_layer.vhd

# Cocotb and nvc flags
SIM					:= nvc
TOPLEVEL_LANG		:= vhdl
TOPLEVEL			:= conv2d_layer.vhd
COCOTB_TEST_MODULES	:= test_conv2d_layer.vhd
MODULE				:= $(COCOTB_TEST_MODULES) # Retrocompatibility
RTL_LIBRARY			:= LIB_RTL

# Generic Parameters (unfortunately, I was not able to set std_logic as generic in the Makefile,
# so to use different architectures, you need to change the VHDL code)
SIM_ARGS			+= -gDATA_SCALE_FACTOR=0 -gBITWIDTH=8 
SIM_ARGS			+= -gINPUT_CHANNELS=3 -gKERNEL_SIZE=3

# Calling cocotb
PWD 				:= $(shell pwd)
export PYTHONPATH	:= $(PWD)/../model:$(PYTHONPATH)
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf $(LIB) $(WAVE_FILE) results.xml __pycache__ sim_build