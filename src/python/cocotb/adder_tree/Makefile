# Makefile for simulating VHDL code with nvc and cocotb

# Directory containing VHDL source files
SRC_DIR     := ../../../rtl
BENCH_DIR   := ../../../bench

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
			   $(SRC_DIR)/maxpool2d/maxpool2d_layer.vhd \
			   $(SRC_DIR)/maxpool2d/maxpool2d.vhd \
			   $(SRC_DIR)/batchnorm2d/batchnorm2d_layer.vhd \
			   $(SRC_DIR)/batchnorm2d/batchnorm2d.vhd \
			   $(SRC_DIR)/conv/conv.vhd

# COCOTB Flags
SIM          		:= nvc
TOPLEVEL_LANG   	:= vhdl
TOPLEVEL 	 		:= adder_tree
COCOTB_TEST_MODULES	:= test_adder_tree
MODULE				:= $(COCOTB_TEST_MODULES) # Retrocompatibility
RTL_LIBRARY			:= LIB_RTL
WAVE_FILE   		:= $(COCOTB_TEST_MODULES)_wave.fst
SIM_ARGS            += -gNUM_OPERANDS=8 -gBITWIDTH=8 --wave=$(WAVE_FILE) --dump-arrays

# COCOTB Log Level
PWD 		   		:= $(shell pwd)
export PYTHONPATH   := $(PWD)/../model:$(PYTHONPATH)
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf $(LIB) $(WAVE_FILE) results.xml __pycache__ sim_build