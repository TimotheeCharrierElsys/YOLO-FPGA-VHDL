TOPLEVEL            := pipeline
MODULE              := test_pipeline
WAVE_FILE           := $(MODULE)_wave.vcd

COCOTB_LOG_LEVEL    := DEBUG
TOPLEVEL_LANG       ?= vhdl
SIM                 := ghdl
SIM_BUILD           := build

COMPILE_ARGS        := --std=08
COMPILE_ARGS        += -Wno-error
COMPILE_ARGS        += -g
SIM_ARGS            += --vcd=$(WAVE_FILE)
SIM_ARGS            += -gN_STAGES=4

PWD=$(shell pwd)

export PYTHONPATH   := $(PWD)/../model:$(PYTHONPATH)

ifeq ($(TOPLEVEL_LANG),vhdl)
    VHDL_SOURCES    = /home/tim/YOLO-FPGA-VHDL/SRC/RTL/common/pipeline.vhd
else
    $(error A valid value (verilog or vhdl) was not provided for TOPLEVEL_LANG=$(TOPLEVEL_LANG))
endif

# Remove default GHDL options set by cocotb-config Makefile
GHDL_ARGS := $(COMPILE_ARGS)

include $(shell cocotb-config --makefiles)/Makefile.sim

# Add custom GHDL compile options
GHDL_ARGS += $(COMPILE_ARGS)

.PHONY: clean
clean::
	rm -rf *.o __pycache__ $(SIM_BUILD) results.xml $(WAVE_FILE)
