# Makefile for simulating VHDL code with nvc and cocotb

# Directory containing VHDL source files
SRC_DIR     := ../../../../rtl
BENCH_DIR   := ../../../../bench

# VHDL Source Files
VHDL_SOURCES  := $(SRC_DIR)/types_pkg.vhd \
				$(SRC_DIR)/common/pipeline.vhd \
			   	$(SRC_DIR)/common/silu_activation.vhd \
			   	$(SRC_DIR)/batchnorm2d/batchnorm2d_layer.vhd

# COCOTB Flags
SIM          		:= nvc
TOPLEVEL_LANG   	:= vhdl
TOPLEVEL 	 		:= batchnorm2d_layer
COCOTB_TEST_MODULES	:= test_batchnorm2d_layer
MODULE				:= $(COCOTB_TEST_MODULES) # Retrocompatibility
RTL_LIBRARY			:= LIB_RTL

# Generic Parameters
SIM_ARGS            += -gDATA_SCALE_FACTOR=10 -gBITWIDTH=16

# COCOTB Log Level
PWD 		   		:= $(shell pwd)
export PYTHONPATH   := $(PWD)/../model:$(PYTHONPATH)
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf $(LIB) $(WAVE_FILE) results.xml __pycache__ sim_build