# Directory containing VHDL source files
SRC_DIR     := RTL

TOP_ENTITY  := silu_activation

# VHDL Source Files
SOURCES     := $(SRC_DIR)/types_pkg.vhd \
               $(SRC_DIR)/common/pipeline.vhd \
               $(SRC_DIR)/common/adder_tree.vhd \
               $(SRC_DIR)/common/silu_activation.vhd \
               $(SRC_DIR)/common/square_root.vhd \
               $(SRC_DIR)/mac/accumulative_mac.vhd \
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
FLAGS       := --std=08 --ieee=standard --work=$(LIB) --workdir=$(WORK_DIR)
WARNINGS    := -Wdefault-binding -Wparenthesis -Wothers -Wstatic -Werror

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
	yosys -p 'read_verilog $(VERILOG_FILE); hierarchy -check -top $(TOP_ENTITY); proc; opt; wreduce; peepopt; share; opt_clean; write_json $(JSON_FILE); write_verilog -noattr $(TOP_ENTITY)_synth.v; stat' || { echo "Yosys synthesis failed"; exit 1; }
	@echo "High-Level Netlist generated."

# Generate a schematic from the synthesized design
schematic: generate_hl_netlist
	@echo "Generating schematic..."
	netlistsvg ${JSON_FILE} -o $(SVG_FILE) --skin ../docs/source/fig/skin.svg
	@echo "Schematic done."

# Synthesize the design
synthesize: convert
	@echo "Synthesizing design..."
	yosys -p 'read_verilog $(VERILOG_FILE); hierarchy -check -top $(TOP_ENTITY); proc; opt; fsm; opt; memory; opt; abc -dff; opt; write_json $(JSON_FILE); write_verilog -noattr $(WORK_DIR)/$(TOP_ENTITY)_synth.v; stat' || { echo "Yosys synthesis failed"; exit 1; }
	@echo "Synthesize done."

# Generate detailed synthesis reports
report: synthesize
	@echo "Generating detailed synthesis report..."
	yosys -p 'read_json $(JSON_FILE); stat -top $(TOP_ENTITY); check -assert' || { echo "Report generation failed"; exit 1; }
	@echo "Report done."

# Clean up the generated files
clean:
	rm -rf $(WORK_DIR) $(VERILOG_FILE) $(SYNTH_SCRIPT) $(JSON_FILE) $(TOP_ENTITY)_synth.v $(TOP_ENTITY) *.o $(SVG_FILE) *.dot $(TOP_ENTITY)_stat.txt $(TOP_ENTITY)_report.txt

.PHONY: all analyze convert generate_hl_netlist synthesize schematic report clean
