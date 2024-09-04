# Makefile for simulating VHDL code with nvc and cocotb

# Directory containing VHDL source files
SRC_DIR     := ../../../rtl
BENCH_DIR   := ../../../bench

# VHDL Source Files
VHDL_SOURCES  := $(SRC_DIR)/common/pipeline.vhd
			   
# COCOTB Flags
SIM          		:= nvc
TOPLEVEL_LANG   	:= vhdl
TOPLEVEL 	 		:= pipeline
COCOTB_TEST_MODULES	:= test_pipeline
MODULE				:= $(COCOTB_TEST_MODULES) # Retrocompatibility
RTL_LIBRARY			:= LIB_RTL

# Generic Parameters (unfortunately, I was not able to set std_logic as generic in the Makefile,
# so to set DO_MULTIPLCIATION to '0' or '1', you need to change the VHDL code)
SIM_ARGS            += -gN_STAGES=8 --wave=wave.fst

# COCOTB Log Level
PWD 		   		:= $(shell pwd)
export PYTHONPATH   := $(PWD)/../model:$(PYTHONPATH)
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf $(LIB) $(WAVE_FILE) results.xml __pycache__ sim_build