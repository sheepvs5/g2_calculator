`include "ram.sv"

module SubFlag(a, b, y, oFlag, uFlag); 
  parameter iSIZE = 32-1;
  parameter oSIZE = 10-1;
  parameter oMax = (32'b1 << (oSIZE+1))-1;
  parameter oCenter = (32'b1 << (oSIZE))-1;
  input unsigned [iSIZE:0]  a;
  input unsigned [iSIZE:0]  b;
  output unsigned [oSIZE:0] y; // y = a - b 
  output                    oFlag;
  output                    uFlag;

  wire signed [iSIZE:0] subTemp;

  assign subTemp = a - b + oCenter;
  assign y = subTemp[oSIZE:0];
  assign oFlag = (subTemp>$signed(oMax)) ? 1'b1 : 1'b0;
  assign uFlag = (subTemp<$signed(31'b0)) ? 1'b1 : 1'b0;
endmodule


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
    uFlag = (subTemp<$signed(31'b0)) ? 1'b1 : 1'b0;
  end

endmodule


module sumBuf(clk, iD, iR, iV, oD, oR, oV);
  /*
  oD = iD[0]+iD[1]+...+iD[totUnits];
  Buffer saves previous data and export it
  */
  parameter datBit = 18-1;
  parameter totUnits = 32-1;
  parameter bufAddrBit = 3-1;
  parameter iSIZE = 32-1;

  parameter bufWidth = ((32'b1 << (bufAddrBit+1) ) -1);
  input clk;
  input [datBit:0] iD[0:totUnits];
  output iR;
  input iV;
  output [iSIZE:0] oD;
  input oR;
  output reg oV;

  reg [iSIZE:0] sumTemp;
  reg [iSIZE:0] sums[0:bufWidth];
  reg [bufAddrBit:0] ra = 1'b0;
  reg [bufAddrBit:0] valPts = 1'b0;  
  wire [bufAddrBit:0] wa;

  assign iR = (valPts>={{bufAddrBit{1'b1}}, 1'b0}) ? 1'b0 : 1'b1;
  assign oV = (valPts=={(bufAddrBit+1){1'b0}}) ? 1'b0 : 1'b1;
  assign wa = ra + valPts;
  assign oD = sums[ra];

  // data write
  integer i;
  always @ (posedge clk) begin
    if(iV&&iR) begin  // dat write
      sumTemp = 1'b0;
      for(i = 0; i <= totUnits; i = i + 1)
        sumTemp = sumTemp + iD[i];
      sums[wa] = sumTemp;
      valPts = valPts + 1'b1;
    end
    if(oV&&oR) begin // dat read
      valPts = valPts - {{bufAddrBit{1'b0}}, 1'b1};
      ra = ra + {{bufAddrBit{1'b0}}, 1'b1};
    end
  end

endmodule


module g2MemWrapper(clk, RST, g2MemWe, g2MemWa, g2Dat, g2V, g2R);
  parameter datBit = 18-1;
  parameter addrBit = 10-1;
  parameter totUnits = 32-1;
  parameter iSIZE = 32-1;

  input clk;
  input RST;  // Falling edge active
  input [totUnits:0] g2MemWe;
  input [addrBit:0] g2MemWa[0:totUnits];
  output [iSIZE:0] g2Dat;
  output g2V;
  input g2R;

  reg RSTPre, RstLatch = 1'b0, RstLatchPre = 1'b0;
  reg [datBit:0] g2Temp[0:totUnits];
  wire [datBit:0] g2TempAdded[0:totUnits];
  wire [addrBit:0] addr[0:totUnits];
  reg [addrBit:0] addrPre[0:totUnits];
  reg [totUnits:0] g2MemWePre;
  reg [addrBit:0] g2RP;
  wire bufR;
  reg  bufV;

  generate
    genvar pIdx;
    for(pIdx = 0; pIdx <= totUnits; pIdx = pIdx + 1) begin
      assign g2TempAdded[pIdx] = (!RstLatchPre) ? g2Temp[pIdx] + 1'b1 : 1'b0;
      assign addr[pIdx] = (!RstLatch) ? g2MemWa[pIdx] : g2RP;
    end
  endgenerate

  // RST negedge detect and g2RP counter
  always @ (posedge clk) begin
    RSTPre <= RST;
    if(RSTPre && !RST) begin // neg edge
      RstLatch <= 1'b1;
      g2RP <= 1'b0;
    end else if(RstLatch) begin
      if(bufR) begin 
        g2RP <= g2RP + {{addrBit{1'b0}}, 1'b1};
        if(g2RP=={(addrBit+1){1'b1}}) RstLatch <= 1'b0;
      end
    end
  end

  always @ (posedge clk) begin
    RstLatchPre <= RstLatch;
  end

  always @ (posedge clk) begin
    if(RstLatch) bufV <= 1'b1;
    else bufV <= 1'b0;
  end

  always @ (posedge clk) begin
    addrPre <= addr;
    if(RstLatch) begin
      g2MemWePre <= {totUnits{1'b1}};
    end else begin
      g2MemWePre <= g2MemWe;
    end
  end

  sumBuf#(
  .datBit(datBit),
  .totUnits(totUnits),
  .bufAddrBit(2),
  .iSIZE(iSIZE)
  ) Buffer(
    .clk(clk), 
    .iD(g2Temp), 
    .iR(bufR), 
    .iV(bufV), 
    .oD(g2Dat), 
    .oR(g2R), 
    .oV(g2V));

  mimobRAM#(
    .datBit(datBit),
    .addrBit(addrBit),
    .totUnits(totUnits)
  ) g2MemArr(
    .clk(clk),
    .we(g2MemWePre),
    .wa(addrPre),
    .ra(addr),
    .wd(g2TempAdded),
    .rd(g2Temp)); 

endmodule


module a2MemWrapper(clk, iD, iR, iV, oD, oV, oFlags, oFV);
  parameter datBit = 32-1;
  parameter unitAddrBit = 3-1;
  parameter totAddrBit = 8-1;
  parameter cycleBit = 2-1;

  parameter totUnits = (32'b1 << (totAddrBit-unitAddrBit)) - 1;
  input clk;
  input [datBit:0] iD;
  output iR;
  input iV;
  output [datBit:0] oD[0:totUnits];
  output oV;
  input [totUnits:0] oFlags;
  input oFV;

  reg [totAddrBit:0] rp = {(totAddrBit+1){1'b0}};
  reg [totAddrBit:0] valPts = {(totAddrBit+1){1'b0}};
  wire [totAddrBit:0] wp, addRp;
  reg [totUnits:0] oFlagsAt0 = {(totUnits+1){1'b0}};
  reg [totAddrBit:0] oFlowPts = 1'b0;
  reg [cycleBit:0] cycle = {(cycleBit+1){1'b0}};
  integer idx;

  always @ (posedge clk) begin
    if(oFV&&(cycle=={(cycleBit+1){1'b0}})) begin
      oFlagsAt0 <= oFlags;
    end
  end

  always @ (posedge clk) begin
    oFlowPts = 1'b0;
    for (idx = 0; idx<=totUnits; idx = idx + 1)
      oFlowPts = oFlowPts + oFlagsAt0[idx]; // oFlowPts calculated
  end

  always @ (posedge clk) begin
    if(oFV) begin
      if(cycle=={(cycleBit+1){1'b1}}) begin
        valPts = valPts - oFlowPts;
        rp = rp + oFlowPts;
      end
      cycle = cycle + {{cycleBit{1'b0}}, 1'b1}; 
    end

    if(iV&&iR) begin
      valPts = valPts + 1'b1;
    end
  end

  assign iR = (valPts>={{totAddrBit{1'b1}}, 1'b0}) ? 1'b0 : 1'b1;
  assign addRp = rp + cycle*(totUnits+1);
  assign wp = rp + valPts;
  assign oV= (valPts>((totUnits+1)*({{totAddrBit{1'b0}},1'b1} << (cycleBit+1)))) ? 1'b1 : 1'b0;


  simodRAM#(
    .datBit(datBit),
    .unitAddrBit(unitAddrBit),
    .totAddrBit(totAddrBit)
  ) a2Mem(
    .clk(clk), 
    .we(iV), 
    .wa(wp), 
    .ra(addRp), 
    .wd(iD),
    .rd(oD));

endmodule


module a1MemWrapper(clk, iD, iR, iV, oD, oV, oFV);
  parameter datBit = 32-1;
  parameter totAddrBit = 8-1;
  parameter cycleBit = 2-1;

  input clk;
  input [datBit:0] iD;
  output iR;
  input iV;
  output [datBit:0] oD;
  output oV;
  input oFV;

  reg [totAddrBit:0] rp = {(totAddrBit+1){1'b0}};
  reg [totAddrBit:0] valPts = {(totAddrBit+1){1'b0}};
  wire [totAddrBit:0] wp;
  reg [cycleBit:0] cycle = {(cycleBit+1){1'b0}};

  always @ (posedge clk) begin
    if(oFV) begin
      if(cycle=={(cycleBit+1){1'b1}}) begin
        valPts = valPts - {{totAddrBit{1'b0}}, 1'b1};
        rp = rp + {{totAddrBit{1'b0}}, 1'b1};
      end
      cycle = cycle + {{cycleBit{1'b0}}, 1'b1}; 
    end
    if(iV&&iR) begin
      valPts = valPts + 1'b1;
    end
  end

  assign iR = (valPts>={{totAddrBit{1'b1}}, 1'b0}) ? 1'b0 : 1'b1;
  assign wp = rp + valPts;
  assign oV= (valPts>1'b1) ? 1'b1 : 1'b0;

  sDualRAM#(
    .datBit(datBit),
    .addrBit(totAddrBit)
  ) a1Mem(
    .clk(clk), 
    .we(iV), 
    .wa(wp), 
    .ra(rp), 
    .wd(iD),
    .rd(oD));

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
  reg unsigned [cycleBit:0] cycle = 1'b0;
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
      
      // // calculate g2 address
      // SubFlag#(
      //   .iSIZE(iSIZE),
      //   .oSIZE(g2MemAddrBit),
      //   .oMax((32'b1 << (g2MemAddrBit+1))-1),
      //   .oCenter((32'b1 << (g2MemAddrBit))-1)
      // ) subtract(
      //   .a(a1Temp),
      //   .b(a2Temp[pIdx]),
      //   .y(address),
      //   .oFlag(oFlag),
      //   .uFlag(uFlag)
      //   );

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
  assign g2MemWe = (oFV) ? (~oFlags)&(~uFlags) : {totUnits{1'b0}};

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

