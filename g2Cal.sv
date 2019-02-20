`include "MemWrappers.sv"

module SubFlagClk(clk, a, b, y, oFlag, uFlag); 
  parameter iSIZE = 32-1;
  parameter oSIZE = 10-1;
  parameter oMax = (32'b1 << (oSIZE+1))-1;
  parameter oCenter = (32'b1 << (oSIZE))-1;
  input clk;
  input unsigned [iSIZE:0]      a;
  input unsigned [iSIZE:0]      b;
  output reg unsigned [oSIZE:0] y; // y = a - b 
  output reg                    oFlag;
  output reg                    uFlag;

  reg signed [iSIZE:0] subTemp;
  always @ (posedge clk) begin
    subTemp = a - b + oCenter;
    y = subTemp[oSIZE:0];
    oFlag = (subTemp>$signed(oMax)) ? 1'b1 : 1'b0;
    uFlag = (subTemp<$signed(32'b0)) ? 1'b1 : 1'b0;
  end

endmodule

module g2Cal(clk, RST, a1, a1V, a1R, a2, a2V, a2R, g2Dat, g2V, g2R);
  parameter iSIZE = 32-1;
  parameter g2DatBit = 18-1;
  parameter a1MemAddrBit = 8-1;
  parameter a2MemAddrBit = 8-1;
  parameter g2MemAddrBit = 10-1;
  parameter a2UnitMemAddrBit = 3-1;
  parameter cycleBit = 2-1;

  parameter totUnits = (32'b1 << (a2MemAddrBit-a2UnitMemAddrBit))-1;
  input clk;
  input RST;
  input unsigned [iSIZE:0] a1;
  input a1V;
  output a1R;
  input unsigned [iSIZE:0] a2;
  input a2V;
  output a2R;
  output unsigned [iSIZE:0] g2Dat;
  output g2V;
  input g2R;

  reg RstLatch = 1'b0;
  reg unsigned [cycleBit:0] cycle = {(cycleBit+1){1'b0}};
  wire [iSIZE:0] a1Temp;
  wire [iSIZE:0] a2Temp[0:totUnits];
  wire a1TempV, a2TempV;
  wire [totUnits:0] oFlags, uFlags;
  wire [totUnits:0] g2MemWe;
  wire [g2MemAddrBit:0] g2MemWa[0:totUnits];
  wire oFV;

  a1MemWrapper#(
    .datBit(iSIZE),
    .totAddrBit(a1MemAddrBit),
    .cycleBit(cycleBit)
  ) a1Mem(
    .clk(clk), 
    .iD(a1), 
    .iR(a1R), 
    .iV(a1V), 
    .oD(a1Temp), 
    .oV(a1TempV),
    .oFV(oFV));

  a2MemWrapper#(
    .datBit(iSIZE),
    .unitAddrBit(a2UnitMemAddrBit),
    .totAddrBit(a2MemAddrBit),
    .cycleBit(cycleBit)
  ) a2Mem(
    .clk(clk), 
    .iD(a2), 
    .iR(a2R), 
    .iV(a2V), 
    .oD(a2Temp), 
    .oV(a2TempV), 
    .oFlags(oFlags),
    .oFV(oFV));

  generate
    genvar pIdx;
    for(pIdx = 0; pIdx <= totUnits; pIdx = pIdx + 1) begin
      wire unsigned [g2MemAddrBit:0] address;
      wire oFlag;
      wire uFlag;
      
      SubFlagClk#(
        .iSIZE(iSIZE),
        .oSIZE(g2MemAddrBit),
        .oMax((32'b1 << (g2MemAddrBit+1))-1),
        .oCenter((32'b1 << (g2MemAddrBit))-1)
      ) subtract(
        .clk(clk),
        .a(a1Temp),
        .b(a2Temp[pIdx]),
        .y(address),
        .oFlag(oFlag),
        .uFlag(uFlag)
        );
      
      // Save over/underflow Flags
      assign oFlags[pIdx] = oFlag;
      assign uFlags[pIdx] = uFlag;
      assign g2MemWa[pIdx] = address;
    end
  endgenerate

  assign oFV = (a1TempV&&a2TempV) ? 1'b1 : 1'b0;
  assign g2MemWe = (oFV) ? (~oFlags)&(~uFlags) : {(totUnits+1){1'b0}};

  g2MemWrapper#(
    .datBit(g2DatBit),
    .addrBit(g2MemAddrBit),
    .totUnits(totUnits),
    .iSIZE(iSIZE)
  ) g2Mem(
    .clk(clk), 
    .RST(RST), 
    .g2MemWe(g2MemWe), 
    .g2MemWa(g2MemWa), 
    .g2Dat(g2Dat), 
    .g2V(g2V), 
    .g2R(g2R));

endmodule

