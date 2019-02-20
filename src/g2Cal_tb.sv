`timescale 1ns/100ps
`include "g2Cal.sv"

module g2Cal_tb;
   parameter iSIZE = 32-1;
   parameter g2Bit = 32-1;
   parameter g2SIZE = 1024-1; 
   reg clk, RST, a1V,  a2V, g2R;
   reg [31:0] clk_counter=0;
   wire a1R, a2R, g2V;

   reg unsigned [iSIZE:0] a1, a2;
   wire unsigned [iSIZE:0]   g2Dat;
   reg unsigned [g2Bit:0] g2RP = 1'b0;
   reg unsigned [g2Bit:0] g2Save[g2SIZE:0];

   integer k;

   g2Cal the_circuit(clk, RST, a1, a1V, a1R, a2, a2V, a2R, g2Dat, g2V, g2R);

   initial begin
      clk = 1'b0;
      RST = 1'b1;
      clk_counter = 0;
      g2R = 1'b1;
      
      $dumpfile("g2Cal_tb.vcd");
      $dumpvars(0, g2Cal_tb);

      #6      RST = 1'b0;
      #6      RST = 1'b1;
      #15000   RST = 1'b0;
      #10     RST = 1'b1;
      #15000   RST = 1'b0;
      #10     RST = 1'b1;
      #15000   RST = 1'b0;
      #10     RST = 1'b1;      
      #10000   RST = 1'b0;
      #10     RST = 1'b1;            
      #15000   RST = 1'b0;
      #10     RST = 1'b1;      
            
      $finish;

   end

   // Clock
   always
      #1 clk =  ! clk;

   // a1 input
   always @ (posedge clk) begin
      if(a1R&&(clk_counter%16==0)) begin
         a1 <= clk_counter;
         a1V <= 1;
      end else  a1V <= 0;
   end

   // a2 input
   always @ (posedge clk) begin
      if(a2R&&(clk_counter%16==0)) begin
         a2 <= clk_counter;
         a2V <= 1;
      end else  a2V <= 0;
   end
   always @ (posedge clk) begin
      if(!RST) g2RP = 1'b0;
      if(g2V) begin
         g2Save[g2RP[9:0]] = g2Dat;
         g2RP = g2RP + 1;
      end
   end

   always @ (posedge clk) begin
      clk_counter = clk_counter + 1; 
   end
endmodule


module a2Mem_tb;
   parameter datBit = 32-1;
   parameter unitAddrBit = 3-1;
   parameter totAddrBit = 8-1;
   parameter cycleBit = 2-1;   
   parameter totUnits = (32'b1 << (totAddrBit-unitAddrBit)) - 1;
   reg clk;
   reg [datBit:0] iD;
   reg iR, iV, oV, oFV;
   reg [datBit:0] oD[0:totUnits];
   reg [totUnits:0] oFlags = {(totUnits+1){1'b0}};
   reg [31:0] clk_counter;

   a2MemWrapper the_circuit(clk, iD, iR, iV, oD, oV, oFlags, oFV);

   initial begin
      clk = 1'b0;
      clk_counter = 1'b0;
      oFV = 1'b0;

      #280 oFlags = 31'b11;
      #10 oFV = 1'b1;
      #10

      #10 oFV = 1'b0;
            
      $finish;

   end

   // Clock
   always
      #1 clk =  ! clk;

   // a2 input
   always @ (posedge clk) begin
      if(iR&&(clk_counter%5==0)) begin
         iD <= clk_counter;
         iV <= 1;
      end else  iV <= 0;
   end

   always @ (posedge clk) begin
      clk_counter = clk_counter + 1; 
   end
endmodule



module g2Mem_tb;
   parameter datBit = 18-1;
   parameter addrBit = 10-1;
   parameter totUnits = 32-1;
   parameter iSIZE = 32-1;

   reg clk, RST;
   reg [totUnits:0] g2MemWe;
   reg [addrBit:0] g2MemWa[0:totUnits];
   reg [iSIZE:0] g2Dat;
   reg g2V;
   reg g2R;

   integer clk_counter,i,j;

   g2MemWrapper the_circuit(clk, RST, g2MemWe, g2MemWa, g2Dat, g2V, g2R);

   initial begin
      clk = 1'b0;
      clk_counter = 1'b0;
      RST = 1'b1;
      g2R = 1'b1;

      for(j=0;j<=100;j=j+1) begin
         #2
         for(i=0;i<=totUnits;i=i+1) begin
            g2MemWe[i] = 1'b1;
            g2MemWa[i] = clk_counter[addrBit:0];
         end
         #2
         for(i=0;i<=totUnits;i=i+1) begin
            g2MemWe[i] = 1'b0;
            g2MemWa[i] = clk_counter[addrBit:0];
         end
      end
      #2 RST = 1'b0;
      #2 RST = 1'b1;
      #2000

      for(j=0;j<=100;j=j+1) begin
         #2
         for(i=0;i<=totUnits;i=i+1) begin
            g2MemWe[i] = 1'b1;
            g2MemWa[i] = clk_counter[addrBit:0];
         end
      end

      $finish;

   end

   // Clock
   always
      #1 clk =  ! clk;

   always @ (posedge clk) begin
      clk_counter = clk_counter + 1; 
   end

endmodule