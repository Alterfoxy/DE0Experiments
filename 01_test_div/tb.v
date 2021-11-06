`timescale 10ns / 1ns
module tb;

reg clock;
reg clock_25;
reg clock_50;

// ---------------------------------------------------------------------
always #0.5 clock    = ~clock;
always #1.0 clock_50 = ~clock_50;
always #2.0 clock_25 = ~clock_25;

// ---------------------------------------------------------------------
initial begin clock = 0; clock_25 = 0; clock_50 = 0; #2000 $finish; end
initial begin $dumpfile("tb.vcd"); $dumpvars(0, tb); end
// ---------------------------------------------------------------------

localparam depth = 4;
localparam width = 8;

wire [(width-1):0] ro[depth];
wire [(width-1):0] qo[depth];

wire [(width-1):0] q    = 4'hF;
wire [(width-1):0] b    = 4'h2;
wire [(width-1):0] zero = 1'b0;

divmod #(.WIDTH( width )) UnitDivMod
(
    .b  (b),
    .q  (q),     .r  (zero),
    .qo (qo[0]), .ro (ro[0])
);

genvar i;
generate

for (i = 0; i < depth-1; i=i+1) begin : DivModX
divmod #(.WIDTH(width)) UnitDivMod
(
    .b  (b),
    .q  (qo[i  ]), .r  (ro[i  ]),
    .qo (qo[i+1]), .ro (ro[i+1])
);
end

endgenerate

endmodule

`include "divmod.v"
