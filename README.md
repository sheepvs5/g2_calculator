
# Second order correlation calculator

This code handles computing second order correlation function(<img src="https://latex.codecogs.com/gif.latex?g^2(\tau)" title="g^2(\tau)" /></a>) in a FPGA.
The code is written in systemverilog and the synthesized file can be used in labview.

## Cover range

This code can cover 20 Mcps(mega count per second) per SPCM(single photon counting module) and the scope of the calculation is restricted to 6 us.
More precisely, there exist only 1024 addresses which can record the arrival time, so the scope of time is given as 1/clk * 1024(for 160 MHz, 6.4 us).
If you need more addresses(or scope of time), you can increase the number of addresses in sake of decreasing bits of individual memories.
The fastest clock for the synthesized module is 160 MHz with kintex-7 devices.

## Algorithm overview

The module has two inputs: one input receives arrival times from "start" detector and the other one receives arrival times from "stop" detector.



## Labview integration

component level ip
