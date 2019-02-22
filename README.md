
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
Each input is accepted through ready-valid handshake protocol.
After accumulating enough arrival times in the memory, 1 element from "start" is sent to the comparator and N elements from "stop" are sent to the comparator.
Each compared value is used as an address and the value at the address of "g2 Mem" is increased by 1.
Below image shows the algorithm.
<img src="https://github.com/sheepvs5/g2_calculator/blob/master/img/algorithm.PNG"/></a>

## Labview integration

component level ip
