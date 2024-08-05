# Makefile for synthesizing VHDL code with GHDL and Yosys

# Directory containing VHDL source files
SRC_DIR 	:= RTL

TOP_ENTITY  := conv2d

# VHDL Source Files
SOURCES		:= $(SRC_DIR)/types_pkg.vhd \
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
			# $(SRC_DIR)/conv/conv.vhd

# Work Directory
WORK_DIR 	:= work

# Synthesis Script
SYNTH_SCRIPT := $(WORK_DIR)/synth.ys

# Output Files
VERILOG_FILE := $(TOP_ENTITY).v
JSON_FILE 	 := $(TOP_ENTITY).json
SVG_FILE	 := $(TOP_ENTITY).svg

# VHDL Standard and Library
LIB 		:= LIB_RTL
FLAGS       := --std=08 --ieee=standard --work=$(LIB) --workdir=$(WORK_DIR)
WARNINGS	:= -Wdefault-binding -Wparenthesis -Wothers -Wstatic -Werror

# Default target
all: analyze elaborate convert synthesize

# Create work directory if it doesn't exist
$(WORK_DIR):
	@mkdir -p $(WORK_DIR)

# Analyze VHDL files
analyze: $(WORK_DIR)
	@echo "Analyzing VHDL source files..."
	ghdl -a $(FLAGS) $(WARNINGS) $(SOURCES)
	@echo "Analyze done."

# Elaborate the design
elaborate: analyze
	@echo "Elaborating $(TOP_ENTITY)..."
	ghdl -e $(FLAGS) $(WARNINGS) -Wdelayed-checks --syn-binding $(TOP_ENTITY)
	@echo "Elaborate done."

# Convert VHDL to Verilog using GHDL
convert: elaborate
	@echo "Converting $(TOP_ENTITY)..."
	ghdl --synth $(FLAGS) --out=verilog $(TOP_ENTITY) > $(VERILOG_FILE)
	@echo "Convert done."

# Target to synthesize the design and generate JSON and DOT files
synthesize: convert
	@echo "Generating Yosys synthesis script..."
	@echo "read_verilog $(VERILOG_FILE)" > $(SYNTH_SCRIPT)
	@echo "hierarchy -check -top $(TOP_ENTITY)" >> $(SYNTH_SCRIPT)
	@echo "synth -top $(TOP_ENTITY)" >> $(SYNTH_SCRIPT)
	@echo "write_json $(TOP_ENTITY).json" >> $(SYNTH_SCRIPT)
	@echo "write_verilog -noattr $(TOP_ENTITY)_synth.v" >> $(SYNTH_SCRIPT)
	@echo "stat" >> $(SYNTH_SCRIPT)
	@echo "Executing Yosys synthesis..."
	yosys -s $(SYNTH_SCRIPT)

schematic: synthesize
	@echo "Generating Yosys schematic script..."
	@echo "proc" >> $(SYNTH_SCRIPT)
	@echo "write_json $(JSON_FILE)" >> $(SYNTH_SCRIPT)
	@echo "stat" >> $(SYNTH_SCRIPT)
	@echo "Executing Yosys for schematic generation..."
	yosys -m ghdl -p "script $(SYNTH_SCRIPT)"
	netlistsvg $(JSON_FILE) -o $(SVG_FILE)

# Clean up the generated files
clean:
	rm -rf $(WORK_DIR) $(VERILOG_FILE) $(SYNTH_SCRIPT) $(JSON_FILE) $(TOP_ENTITY)_synth.v $(TOP_ENTITY) *.o $(SVG_FILE)

.PHONY: all analyze elaborate convert synthesize schematic clean
