PROJ = i2c
PIN_DEF = icestick.pcf
DEVICE = hx1k

all: $(PROJ).rpt $(PROJ).bin

%.blif: %.v
	yosys -p 'synth_ice40 -top top -blif $@' $< button.v i2c_init.v i2c_master.v

%.asc: $(PIN_DEF) %.blif
	arachne-pnr -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

debug:
	iverilog -o i2c i2c_tb.v i2c_master.v 
	vvp i2c -fst
	gtkwave test.vcd gtk.gtkw

debug2:
	iverilog -o i2c i2c_init_tb.v i2c_init.v i2c_master.v 
	vvp i2c -fst
	gtkwave test.vcd gtk2.gtkw

prog: $(PROJ).bin
	iceprog $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean
