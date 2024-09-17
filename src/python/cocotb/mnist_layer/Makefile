# Makefile for simulating VHDL code with nvc and cocotb

# Directory containing VHDL source files
SRC_DIR			:= ../../../rtl

# VHDL Source Files
VHDL_SOURCES	:= $(SRC_DIR)/types_pkg.vhd \
				$(SRC_DIR)/common/pipeline.vhd \
				$(SRC_DIR)/common/silu_activation.vhd \
				$(SRC_DIR)/conv2d/mac.vhd \
				$(SRC_DIR)/batchnorm2d/batchnorm2d_layer.vhd \
				$(SRC_DIR)/conv2d/conv2d_control.vhd \
				$(SRC_DIR)/conv2d/conv2d_layer_mac.vhd \
				$(SRC_DIR)/conv/conv.vhd \
				$(SRC_DIR)/conv/mnist_layers.vhd \


# Cocotb and nvc flags
SIM					:= nvc
TOPLEVEL_LANG		:= vhdl
TOPLEVEL			:= mnist_layers
COCOTB_TEST_MODULES	:= test_mnist_layers
MODULE				:= $(COCOTB_TEST_MODULES) # Retrocompatibility
RTL_LIBRARY			:= LIB_RTL
EXTRA_ARGS		:= -M 64m

# Calling cocotb
PWD 				:= $(shell pwd)
export PYTHONPATH	:= $(PWD)/../model:$(PYTHONPATH)
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf $(LIB) $(WAVE_FILE) results.xml __pycache__ sim_build