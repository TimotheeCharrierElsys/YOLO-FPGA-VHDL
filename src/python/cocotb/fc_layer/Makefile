# Makefile for simulating VHDL code with nvc and cocotb

# Directory containing VHDL source files
SRC_DIR			:= ../../../rtl

# VHDL Source Files
VHDL_SOURCES	:= $(SRC_DIR)/types_pkg.vhd \
				$(SRC_DIR)/common/pipeline.vhd \
				$(SRC_DIR)/common/adder_tree.vhd \
				$(SRC_DIR)/mac/fc_layer.vhd \

# COCOTB Flags
SIM					:= nvc
TOPLEVEL_LANG		:= vhdl
TOPLEVEL			:= fc_layer
COCOTB_TEST_MODULES	:= test_fc_layer
MODULE				:= $(COCOTB_TEST_MODULES) # Retrocompatibility
RTL_LIBRARY			:= LIB_RTL
WAVE_FILE			:= wave_$(COCOTB_TEST_MODULES).fst
SIM_ARGS			+= -gMATRIX_SIZE=3 -gBITWIDTH=8 --wave=$(WAVE_FILE) --dump-arrays

# COCOTB Log Level
PWD 				:= $(shell pwd)
export PYTHONPATH	:= $(PWD)/../model:$(PYTHONPATH)
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf $(LIB) $(WAVE_FILE) results.xml __pycache__ sim_build