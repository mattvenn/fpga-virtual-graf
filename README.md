# fpga virtual graffiti

![overview](docs/overview.png)

my first 'proper' FPGA project.

* with the icestick usb board
* icestorm free fpga tools.
* gtkwave for debugging.

# Things to do

* write single pixels, need to OR what is in ram already, and get the right pixel
* write blocks of pixels (2x2?)
* tried clock enable on i2c (on separate branch), but slowed down timing estimate
* default cases for state machines

# SRAM video buffer

Using the SRAM on the back of the board for persistant graffitis. This caused 2
major issues:

* [PLL and SRAM pins collide on the board layout](https://forum.mystorm.uk/t/placement-conflict-between-sb-io-for-ram-and-pll/224/12)
* [switching the SB_IO pins and SRAM pins at the same time](https://forum.mystorm.uk/t/fpga-unreliability-crashing-hanging/252/19) caused instability.

# Wiimote Camera

* (breakout board)[https://github.com/mattvenn/kicad/tree/master/wiimote-fpga)
* 25mhz supplied on clock pin
* reset high to run
* wiimote camera PCB was tested with branch wii-pcb

# I2C reader / writer

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

# DVI output

based on [Hamster's minimal DVI-D
VHDL](http://hamsterworks.co.nz/mediawiki/index.php/Minimal_DVI-D)
