# Second order correlation calculator

This code handles computing second order correlation function in a FPGA.
The code is written in systemverilog and the synthesized file can be used in labview.
For the purpose, VHDL wrapper function is used.

## Cover range

This code can cover 20 Mcps(mega count per second) per SPCM(single photon counting module) and the scope of the calculation is restricted to 6 us.
More precisely, there exist only 1024 addresses which can record the arrival time, so the scope of time is given as 1/clk * 1024. (for 160 MHz, 6.4 us)
The synthesized module works under the clock frequency 160 MHz with kintex-7 devices.