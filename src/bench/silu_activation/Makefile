# Makefile for simulating VHDL code with nvc and cocotb

# Directory containing VHDL source files
SRC_DIR				:= ../../rtl

# VHDL Source Files
VHDL_SOURCES		:= $(SRC_DIR)/batchnorm2d/silu_activation.vhd

# Cocotb and nvc flags
SIM					:= nvc
TOPLEVEL_LANG		:= vhdl
TOPLEVEL			:= silu_activation
COCOTB_TEST_MODULES	:= test_silu_activation
MODULE				:= $(COCOTB_TEST_MODULES) # Retrocompatibility
RTL_LIBRARY			:= LIB_RTL

# Generic Parameters
SIM_ARGS			+= -gBITWIDTH=16 -gDATA_SCALE_FACTOR=12

# Calling cocotb
PWD					:= $(shell pwd)
export PYTHONPATH	:= $(PWD)/../model:$(PYTHONPATH)
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf $(LIB) $(WAVE_FILE) results.xml __pycache__ sim_build *.html