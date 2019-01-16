# FPGA Virtual Graffiti

![overview](docs/overview.png)

[videos and construction photos](https://photos.app.goo.gl/kivlfcmlp4oecVpu1)

# Tools used

* [icestorm](http://www.clifford.at/icestorm/) opensource FPGA tools.
* [mystorm](https://mystorm.uk/) open hardware FPGA development board
* [gtkwave](http://gtkwave.sourceforge.net/) for debugging.

# Top resource tips

* [Obijuan's FPGA tutorial](https://github.com/Obijuan/open-fpga-verilog-tutorial/wiki)
* [FPGAwars forum](https://groups.google.com/forum/#!forum/fpga-wars-explorando-el-lado-libre)
* [Dan's FPGA blog](http://www.zipcpu.com/)

# Documentation

* [system overview diagram](docs/module_overview.svg)
* Yosys can generate output graphs of the verilog with the [show](http://www.clifford.at/yosys/cmd_show.html) command.
* [schematic for mystorm](https://gitlab.com/Folknology/mystorm/blob/BlackIce/BlackIce-schematic.pdf)
* [ICEfloorplan](https://knielsen.github.io/ice40_viewer/ice40_viewer.html) can be used to show how the design is laid out on the FPGA
* [All Verilog source](src) and [tests](tests)

# Build notes

## Synthesis

    make

To program the mystorm board, first start a terminal listening on /dev/ttyUSBX
at 115200 baud, and reset the board. Then type:

    make prog

## Tests

many test benches are in [tests](tests). They can be simulated and outputs
viewed with gtkwave:

    make debug-[name of verilog file]

eg

    make debug-bresenham
    
## Storing configuration on the board

[Instructions
here](https://forum.mystorm.uk/t/config-from-non-voltatile-memory/242/2)

## SRAM video buffer

Using the SRAM on the back of the board for persistant graffitis. This caused 2
major issues:

* [PLL and SRAM pins collide on the board layout](https://forum.mystorm.uk/t/placement-conflict-between-sb-io-for-ram-and-pll/224/12)
* [switching the SB_IO pins and SRAM pins at the same time](https://forum.mystorm.uk/t/fpga-unreliability-crashing-hanging/252/19) caused instability.

## Wiimote Camera

* (breakout board)[https://github.com/mattvenn/kicad/tree/master/wiimote-fpga)
* 25mhz supplied on clock pin
* reset high to run
* wiimote camera PCB was tested with branch wii-pcb

## I2C reader / writer

![fpga read](docs/fpga-i2c-read.png)

Started off with this youtube series:https://www.youtube.com/watch?v=rWzB5hZlqBA
by Tom Briggs.

In Tom's design, the I2C clock is assigned to the state machine's !clk.

Writing and requesting data was easy, but reading the data was difficult to
synchronize the clock. I then tried 2 different approaches:

* separating the I2C clock and state machine clock to give more time for reading
 data (4 state machine clocks for 1 I2C clock)
* generating the clock within the state machine itself.

Option 2 proved much easier to write. I also found this [brief Q&A on reddit on
the same topic](https://m.reddit.com/r/FPGA/comments/4oltue/when_writing_communication_protocols_spi_i2c_etc/)

## DVI output

based on [Hamster's minimal DVI-D
VHDL](http://hamsterworks.co.nz/mediawiki/index.php/Minimal_DVI-D)
