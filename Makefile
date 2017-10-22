DEVICE = hx8k
SRC_DIR = src
TEST_DIR = tests
DOCS_DIR = docs
SVG_DIR = $(DOCS_DIR)/svg
SVG_PORT_DIR = $(DOCS_DIR)/module_port_svg
BUILD_DIR = build
PROJ = $(BUILD_DIR)/vgraf
PIN_DEF = $(SRC_DIR)/blackice.pcf
SHELL := /bin/bash # Use bash syntax

MODULES = i2c_master.v camera.v xy_leds.v dvid.v vga.v clockdiv.v sram.v pixel_buffer.v write_buffer.v bresenham.v map_cam.v pulse.v
VERILOG = top.v $(MODULES)
SRC = $(addprefix $(SRC_DIR)/, $(VERILOG))

all: $(PROJ).bin $(PROJ).rpt 
svg: $(patsubst %.v,%.svg,$(SRC))
port_svg: $(patsubst %.v,$(SVG_PORT_DIR)/%.svg,$(MODULES))

# $@ The file name of the target of the rule.rule
# $< first pre requisite
# $^ names of all preerquisites

# rule for building svg graphs of the modules
%.svg: %.v
	yosys -p "read_verilog $<; proc; opt; show -colors 2 -width -signed -format svg -prefix $(basename $@)"
	mv $@ $(SVG_DIR)
	rm $(basename $@).dot

# rule for building svg version of module ports
$(SVG_PORT_DIR)/%.svg: $(SRC_DIR)/%.v
	python $(DOCS_DIR)/ports_to_svg.py $^
	dot -Tsvg out.dot -o $@
#	rm out.dot

# rules for building the blif file
$(BUILD_DIR)/%.blif: $(SRC)
	yosys -p "synth_ice40 -top top -blif $@" $^

# asc
$(BUILD_DIR)/%.asc: $(PIN_DEF) $(BUILD_DIR)/%.blif
	arachne-pnr --device 8k --package tq144:4k -o $@ -p $^

# bin, for programming
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.asc
	icepack $< $@

# timing
$(BUILD_DIR)/%.rpt: $(BUILD_DIR)/%.asc
	icetime -d $(DEVICE) -mtr $@ $<

# rules for simple tests with one verilog module per test bench
$(BUILD_DIR)/%.out: $(TEST_DIR)/%_tb.v $(SRC_DIR)/%.v
	iverilog -o $(basename $@).out $^

$(BUILD_DIR)/%.vcd: $(BUILD_DIR)/%.out 
	vvp $< -fst
	mv test.vcd $@

debug-%: $(BUILD_DIR)/%.vcd $(TEST_DIR)/gtk-%.gtkw
	gtkwave $^

# more complicated tests that need multiple modules per test
$(BUILD_DIR)/camera.out: $(TEST_DIR)/camera_tb.v $(SRC_DIR)/camera.v $(SRC_DIR)/i2c_master.v
	iverilog -o $(basename $@).out $^

$(BUILD_DIR)/sram_vga_line.out: $(TEST_DIR)/sram_vga_line_tb.v $(SRC_DIR)/sram.v $(SRC_DIR)/vga.v $(SRC_DIR)/bresenham.v $(SRC_DIR)/pixel_buffer.v $(SRC_DIR)/write_buffer.v
	iverilog -o $(basename $@).out $^

debug-sram-vga:
	iverilog -o vga-sram sram_vga_tb.v sram.v vga.v pixel_buffer.v
	vvp vga-sram -fst
	gtkwave test.vcd gtk-vga-sram.gtkw

debug-i2c:
	iverilog -o i2c i2c_tb.v camera.v i2c_master.v button.v xy_leds.v
	vvp i2c -fst
	gtkwave test.vcd gtk-i2c.gtkw

debug-master:
	iverilog -o i2c i2c_master_tb.v i2c_master.v 
	vvp i2c -fst
	gtkwave test.vcd gtk-master.gtkw


$(PROJ).size: $(PROJ).bin
	du -b $< | cut -f1 > $@

$(PROJ)-even.bin: $(PROJ).size $(PROJ).bin
	cp $(PROJ).bin $(PROJ)-even.bin
	size=`cat $(PROJ).size`; truncate -s $$(echo $$size + 4 - $$size % 4 | bc) $(PROJ)-even.bin

perma-prog: $(PROJ)-even.bin
	read -p "plug central USB, remove link between 14&16, press reset on board, then press enter"	
	sudo dfu-util -d 0483:df11 -s 0x0801F000 -D $(PROJ)-even.bin --alt 0 -t 1024
	read -p "replace link and reset"

prog: $(PROJ).bin
	bash -c "cat $< > /dev/ttyUSB1"

clean:
	rm -f $(BUILD_DIR)/*
	rm -f $(SVG_DIR)/*svg
	rm -f $(SVG_PORT_DIR)/*svg

.SECONDARY:
.PHONY: all prog clean svg
