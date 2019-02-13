module sDualRAM(clk, we, wa, ra, wd, rd); 
parameter datBit = 32-1;
parameter addrBit = 3-1;

parameter datWidth = (32'b1 << (addrBit+1))-1;
input clk;   
input we;   
input  [addrBit:0] wa;
input  [addrBit:0] ra;
input  [datBit:0] wd;
output [datBit:0] rd;
reg    [datBit:0] ram[0:datWidth]; 
 
always @(posedge clk) begin   
    if (we) ram[wa] <= wd;
end
assign rd = ram[ra];
endmodule 



module bRAM(clk, we, wa, ra, wd, rd); 
parameter datBit = 18-1;
parameter addrBit = 10-1;

parameter datWidth = (32'b1 << (addrBit+1))-1;
input clk;   
input we;   
input  [addrBit:0] wa;
input  [addrBit:0] ra;   
input  [datBit:0] wd;   
output reg [datBit:0] rd;
reg    [datBit:0] ram[0:datWidth] = '{(datWidth+1){1'b0}}; 
 
always @(posedge clk) begin   
    if (we) ram[wa] <= wd;
    rd <= ram[ra];
end
endmodule 



module simodRAM(clk, we, wa, ra, wd, rd); 
parameter datBit = 32-1;
parameter unitAddrBit = 3-1;
parameter totAddrBit = 8-1;

parameter totUnits = (32'b1 << (totAddrBit-unitAddrBit)) - 1;
input clk;
input we;
input  [totAddrBit:0] wa;
input  [totAddrBit:0] ra;
input  [datBit:0] wd;   
output [datBit:0] rd[0:totUnits];

genvar pIdx;
generate
    for(pIdx=0;pIdx<=totUnits;pIdx=pIdx+1) begin : simosRAMs
        wire [unitAddrBit:0] iURAd;   // in unit read address
        wire [(totAddrBit-unitAddrBit-1):0] uRAd; // unit read address
        wire [unitAddrBit:0] iUWAd;   // in unit write address
        wire [(totAddrBit-unitAddrBit-1):0] uWAd; // unit write address
        wire weU;
        assign {iURAd, uRAd} = ra + pIdx[totAddrBit:0];
        assign {iUWAd, uWAd} = wa;        
        assign  weU = (uWAd == ~pIdx[(totAddrBit-unitAddrBit-1):0]) ? we : 1'b0;

        sDualRAM#(
            .datBit(datBit),
            .addrBit(unitAddrBit)
        ) RAMs(.clk(clk), 
            .we(weU), 
            .wa(iUWAd), 
            .ra(iURAd), 
            .wd(wd), 
            .rd(rd[pIdx]));

    end
endgenerate
endmodule



module mimobRAM(clk, we, wa, ra, wd, rd); 
parameter datBit = 18-1;
parameter addrBit = 10-1;
parameter totUnits = 32-1;

input  clk;
input  [totUnits:0] we;
input  [addrBit:0] wa[0:totUnits];
input  [addrBit:0] ra[0:totUnits];
input  [datBit:0] wd[0:totUnits];
output [datBit:0] rd[0:totUnits];

genvar pIdx;
generate
    for(pIdx=0;pIdx<=totUnits;pIdx=pIdx+1) begin : mimobRAMs
        bRAM#(
            .datBit(datBit),
            .addrBit(addrBit)
        ) parallelbRAMs(.clk(clk),
            .we(we[pIdx]),
            .wa(wa[pIdx]),
            .ra(ra[pIdx]),
            .wd(wd[pIdx]), 
            .rd(rd[pIdx]));
    end
endgenerate
endmodule
