# Makefile for simulating VHDL code with nvc and cocotb

# Directory containing VHDL source files
SRC_DIR				:= ../../rtl

# VHDL Source Files
VHDL_SOURCES		:= $(SRC_DIR)/conv/conv_fsm.vhd

# Cocotb and nvc flags
SIM					:= nvc
TOPLEVEL_LANG		:= vhdl
TOPLEVEL			:= conv_fsm
COCOTB_TEST_MODULES	:= test_conv_fsm
MODULE				:= $(COCOTB_TEST_MODULES) # Retrocompatibility
RTL_LIBRARY			:= LIB_RTL

# Generic Parameters
SIM_ARGS			+= -gINPUT_CHANNELS=3 -gKERNEL_SIZE=3 -gOUTPUT_SIZE=3 --wave=wave.fst

# Calling cocotb
PWD 				:= $(shell pwd)
export PYTHONPATH	:= $(PWD)/../model:$(PYTHONPATH)
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf $(LIB) $(WAVE_FILE) results.xml __pycache__ sim_build *.fst