PROJ = i2c
PIN_DEF = blackice.pcf
DEVICE = hx8k

SRC = i2c_master.v camera.v xy_leds.v dvid.v vga.v clockdiv.v sram.v

all: $(PROJ).bin $(PROJ).rpt 

%.blif: %.v $(SRC)
	yosys -p "synth_ice40 -top top -blif $@" $^

#%.blif: %.v $(SRC)
#	yosys -p 'synth_ice40 -top top -blif $@' $<  i2c_master.v camera.v button.v xy_leds.v

%.asc: $(PIN_DEF) %.blif
	#arachne-pnr -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^
	arachne-pnr --device 8k --package tq144:4k -o $@ -p $^

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

debug-i2c:
	iverilog -o i2c i2c_tb.v camera.v i2c_master.v button.v xy_leds.v
	vvp i2c -fst
	gtkwave test.vcd gtk-i2c.gtkw

debug-leds:
	iverilog -o leds xy_leds_tb.v xy_leds.v
	vvp leds -fst
	gtkwave test.vcd gtk-leds.gtkw

debug-master:
	iverilog -o i2c i2c_master_tb.v i2c_master.v 
	vvp i2c -fst
	gtkwave test.vcd gtk-master.gtkw

debug-camera:
	iverilog -o camera camera_tb.v camera.v i2c_master.v 
	vvp camera -fst
	gtkwave test.vcd gtk-camera.gtkw

#prog: $(PROJ).bin
#	iceprog $<

prog: $(PROJ).bin
	bash -c "cat $< > /dev/ttyUSB1"

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean
