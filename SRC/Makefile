# Makefile for synthesizing VHDL code with GHDL and Yosys

# Directory containing VHDL source files
SRC_DIR 	:= RTL

TOP_ENTITY  := adder_tree

# VHDL Source Files
SOURCES 	:= $(SRC_DIR)/types_pkg.vhd \
		   	$(SRC_DIR)/common/pipeline.vhd \
		   	$(SRC_DIR)/common/adder_tree.vhd \
		   	$(SRC_DIR)/common/silu_activation.vhd \
		   	$(SRC_DIR)/common/square_root.vhd \
		   	$(SRC_DIR)/mac/mac.vhd \
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
WORK_DIR 	:= work

# Synthesis Script
SYNTH_SCRIPT := $(WORK_DIR)/synth.ys

# Output Files
VERILOG_FILE := $(TOP_ENTITY).v
JSON_FILE 	 := $(TOP_ENTITY).json

# VHDL Standard and Library
STD 		:= 08
LIB 		:= LIB_RTL

# Default target
all: analyze elaborate convert synthesize

# Create work directory if it doesn't exist
$(WORK_DIR):
	mkdir -p $(WORK_DIR)

# Analyze VHDL files
analyze: $(WORK_DIR)
	ghdl -i --std=$(STD) --work=$(LIB) --workdir=$(WORK_DIR) -P$(WORK_DIR) $(SOURCES)

# Elaborate the design
elaborate: analyze
	ghdl -m --std=$(STD) --ieee=synopsys --work=$(LIB) --workdir=$(WORK_DIR) $(TOP_ENTITY)

# Convert VHDL to Verilog using GHDL
convert: elaborate
	ghdl --synth --std=$(STD) --ieee=synopsys --work=$(LIB) --workdir=$(WORK_DIR) -P$(WORK_DIR) --out=verilog $(TOP_ENTITY) > $(VERILOG_FILE)

# Target to synthesize the design and generate JSON and DOT files
synthesize: convert
	@echo "Generating Yosys synthesis script..."
	@echo "read_verilog $(VERILOG_FILE)" > $(SYNTH_SCRIPT)
	@echo "hierarchy -check -top $(TOP_ENTITY)" >> $(SYNTH_SCRIPT)
	@echo "synth -top $(TOP_ENTITY)" >> $(SYNTH_SCRIPT)
	@echo "write_json $(TOP_ENTITY).json" >> $(SYNTH_SCRIPT)
	@echo "write_verilog -noattr $(TOP_ENTITY)_synth.v" >> $(SYNTH_SCRIPT)
	@echo "Executing Yosys synthesis..."
	yosys -s $(SYNTH_SCRIPT)

# Clean up the generated files
clean:
	rm -rf $(WORK_DIR) $(VERILOG_FILE) $(SYNTH_SCRIPT) $(JSON_FILE) $(TOP_ENTITY)_synth.v $(TOP_ENTITY) *.o

.PHONY: all analyze elaborate convert synthesize clean
