DEVICE = hx8k
SRC_DIR = src
TEST_DIR = tests
SVG_DIR = docs/svg
BUILD_DIR = build
PROJ = $(BUILD_DIR)/vgraf
PIN_DEF = $(SRC_DIR)/blackice.pcf

VERILOG = top.v i2c_master.v camera.v xy_leds.v dvid.v vga.v clockdiv.v sram.v pixel_buffer.v write_buffer.v bresenham.v map_cam.v pulse.v
SRC = $(addprefix $(SRC_DIR)/, $(VERILOG))

all: $(PROJ).bin $(PROJ).rpt 
svg: $(patsubst %.v,%.svg,$(SRC))

# $@ The file name of the target of the rule.rule
# $< first pre requisite
# $^ names of all preerquisites

# rule for building svg graphs of the modules
%.svg: %.v
	yosys -p "read_verilog $<; proc; opt; show -colors 2 -width -signed -format svg -prefix $(basename $@)"
	mv $@ $(SVG_DIR)
	rm $(basename $@).dot

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
debug-sram-vga-line:
	iverilog -o $(DBG_DIR)/sram_vga_line sram_vga_line_tb.v sram.v vga.v bresenham.v pixel_buffer.v write_buffer.v
	vvp $(DBG_DIR)/sram_vga_line -fst
	mv test.vcd $(DBG_DIR)
	gtkwave $(DBG_DIR)/test.vcd $(DBG_DIR)/gtk-sram_vga_line.gtkw

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

debug-camera:
	iverilog -o camera camera_tb.v camera.v i2c_master.v 
	vvp camera -fst
	gtkwave test.vcd gtk-camera.gtkw

prog: $(PROJ).bin
	bash -c "cat $< > /dev/ttyUSB1"

clean:
	rm -f $(BUILD_DIR)/*

.SECONDARY:
.PHONY: all prog clean svg
