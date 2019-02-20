`include "ram.sv"

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

  reg unsigned [datBit:0] iDBuf[0:(totUnits+1)/2];
  reg iVBuf;
  reg unsigned [iSIZE:0] iDBuf2[0:(totUnits+1)/8];
  reg iVBuf2;
  reg unsigned [iSIZE:0] sumTemp;
  reg unsigned [iSIZE:0] sums[0:bufWidth];
  reg [bufAddrBit:0] ra = 1'b0;
  reg [bufAddrBit:0] valPts = 1'b0;  
  wire [bufAddrBit:0] wa;

  assign iR = (valPts>={{bufAddrBit{1'b1}}, 1'b0}) ? 1'b0 : 1'b1;
  assign oV = (valPts=={(bufAddrBit+1){1'b0}}) ? 1'b0 : 1'b1;
  assign wa = ra + valPts;
  assign oD = sums[ra];

  generate
  genvar pIdx;
    for(pIdx=0;pIdx<(totUnits+1)/2;pIdx=pIdx+1) begin
      always @ (posedge clk) begin
        if(iR)
          iDBuf[pIdx] <= iD[pIdx*2]+iD[pIdx*2+1];
      end
    end
  endgenerate

  generate
  genvar pIdx2;
    for(pIdx2=0;pIdx2<(totUnits+1)/8;pIdx2=pIdx2+1) begin
      always @ (posedge clk) begin
        if(iR)
          iDBuf2[pIdx2] <= iDBuf[pIdx2*4]+iDBuf[pIdx2*4+1]+iDBuf[pIdx2*4+2]+iDBuf[pIdx2*4+3];
      end
    end
  endgenerate

  always @ (posedge clk) begin
    if(iR) begin
      iVBuf <= iV;
      iVBuf2 <= iVBuf;
    end
  end

  // data write
  integer i;
  always @ (posedge clk) begin
    if(iVBuf2&&iR) begin  // dat write
      sumTemp = 1'b0;
      for(i = 0; i < (totUnits+1)/2; i = i + 1)
        sumTemp = sumTemp + iDBuf2[i];
      sums[wa] = sumTemp;
      valPts = valPts + 1;
    end
    if(oV&&oR) begin // dat read
      valPts = valPts - 1;
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
  output unsigned [iSIZE:0] g2Dat;
  output g2V;
  input g2R;

  reg RSTPre, RstLatch = 1'b0, RstLatchPre = 1'b0;
  reg [datBit:0] g2Temp[0:totUnits];
  wire unsigned [datBit:0] g2TempAdded[0:totUnits];
  wire [addrBit:0] addr[0:totUnits];
  reg [addrBit:0] addrPre[0:totUnits];
  reg [totUnits:0] g2MemWePre;
  reg unsigned [addrBit:0] g2RP;
  wire bufR;
  reg  bufV;

  generate
    genvar pIdx;
    for(pIdx = 0; pIdx <= totUnits; pIdx = pIdx + 1) begin
      assign g2TempAdded[pIdx] = (!RstLatchPre) ? g2Temp[pIdx] + {{datBit{1'b0}}, 1'b1} : {(datBit+1){1'b0}};
      assign addr[pIdx] = (!RstLatch) ? g2MemWa[pIdx] : g2RP;
    end
  endgenerate

  // RST negedge detect and g2RP counter
  always @ (posedge clk) begin
    RSTPre <= RST;
    if(RSTPre && !RST) begin // neg edge
      RstLatch <= 1'b1;
      g2RP <= {(addrBit+1){1'b0}};
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
      g2MemWePre <= {(totUnits+1){1'b1}};
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
  reg [totAddrBit:0] oFlowPts = {(totAddrBit+1){1'b0}};
  reg [cycleBit:0] cycle = {(cycleBit+1){1'b0}};
  integer idx;

  always @ (posedge clk) begin
    if(oFV&&(cycle=={(cycleBit+1){1'b0}})) begin
      oFlagsAt0 <= oFlags;
    end
  end

  always @ (posedge clk) begin
    oFlowPts = {(totAddrBit+1){1'b0}};
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
      valPts = valPts + 1;
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