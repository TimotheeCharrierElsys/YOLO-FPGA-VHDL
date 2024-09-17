# Directory containing VHDL source files
SRC_DIR     := rtl

TOP_ENTITY  := conv

# VHDL Source Files
SOURCES	:= $(SRC_DIR)/types_pkg.vhd \
            $(SRC_DIR)/conv2d/mac.vhd \
			$(SRC_DIR)/batchnorm2d/silu_activation.vhd \
			$(SRC_DIR)/batchnorm2d/batchnorm2d_layer.vhd \
            $(SRC_DIR)/conv2d/conv2d_layer_mac.vhd \
			$(SRC_DIR)/conv/conv_fsm.vhd \
            $(SRC_DIR)/conv/conv.vhd

# Work Directory
WORK_DIR    := work

# Synthesis Script
SYNTH_SCRIPT := $(WORK_DIR)/synth.ys

# Output Files
VERILOG_FILE := $(TOP_ENTITY).v
JSON_FILE    := $(TOP_ENTITY).json
SVG_FILE     := $(TOP_ENTITY).svg

# VHDL Standard and Library
LIB         := LIB_RTL
FLAGS       := --std=08 --ieee=standard --work=$(LIB) --workdir=$(WORK_DIR) --syn-binding
WARNINGS    := -Wall

all: synthesize

# Create work directory if it doesn't exist
$(WORK_DIR):
	@mkdir -p $(WORK_DIR)

# Analyze VHDL files
analyze: $(WORK_DIR)
	@echo "Analyzing VHDL source files..."
	ghdl -a $(FLAGS) $(WARNINGS) $(SOURCES)
	@echo "Analyze done."

# Convert VHDL to Verilog using Yosys
convert: analyze
	@echo "Converting VHDL to Verilog..."
	yosys -m ghdl -p 'ghdl $(FLAGS) $(SOURCES) -e $(TOP_ENTITY); write_verilog $(VERILOG_FILE)' || { echo "Yosys conversion failed"; exit 1; }
	@echo "Convert done."

# Generate High Level Netlist (add, mul,...)
generate_hl_netlist: convert
	@echo "Synthesizing design..."
	yosys -p 'read_verilog $(VERILOG_FILE); hierarchy -check -top $(TOP_ENTITY); proc; opt_expr; opt_clean; check; opt; fsm; opt; proc; opt -fast -mux_undef -undriven -fine; wreduce; peepopt; opt_clean; share; opt_expr; opt_clean; opt_expr; opt_clean; memory; opt_clean; wreduce; peepopt; opt_clean; check; stat; write_json $(JSON_FILE); write_verilog -noattr $(TOP_ENTITY)_synth.v;' || { echo "Yosys synthesis failed"; exit 1; }
	@echo "High-Level Netlist generated."

# Generate a schematic from the synthesized design
schematic: generate_hl_netlist
	@echo "Generating schematic..."
	netlistsvg ${JSON_FILE} -o $(SVG_FILE) --skin ../docs/source/_static/skin.svg
	@echo "Schematic done."

# Synthesize the design
synthesize: convert
	@echo "Synthesizing design..."
	yosys -p 'read_verilog $(VERILOG_FILE); hierarchy -check -top $(TOP_ENTITY); proc; opt; fsm; opt; memory; opt; abc -dff; opt; synth; opt; write_json $(JSON_FILE); write_verilog -noattr -noattr $(WORK_DIR)/$(TOP_ENTITY)_synth.v; stat' || { echo "Yosys synthesis failed"; exit 1; }
	@echo "Synthesize done."

# Clean up the generated files
clean:
	rm -rf $(WORK_DIR) $(VERILOG_FILE) $(SYNTH_SCRIPT) $(JSON_FILE) $(TOP_ENTITY)_synth.v $(TOP_ENTITY) *.o $(SVG_FILE) *.dot $(TOP_ENTITY)_report.txt

.PHONY: all analyze convert generate_hl_netlist synthesize schematic clean
