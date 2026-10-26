# Usage:
#   make sim    - compile and run the testbench (Icarus Verilog)
#   make wave   - open the waveform in GTKWave
#   make clean  - remove generated files
SRC = rtl/alu_8bit.v
TB  = tb/tb_alu_8bit.v

sim:
	@mkdir -p sim
	iverilog -g2005 -Wall -o sim/tb.out $(SRC) $(TB)
	vvp sim/tb.out

wave: sim
	gtkwave sim/alu.vcd &

clean:
	rm -rf sim
