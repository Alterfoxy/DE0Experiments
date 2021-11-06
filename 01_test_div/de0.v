module de0(

    // Reset
    input              RESET_N,

    // Clocks
    input              CLOCK_50,
    input              CLOCK2_50,
    input              CLOCK3_50,
    inout              CLOCK4_50,

    // DRAM
    output             DRAM_CKE,
    output             DRAM_CLK,
    output      [1:0]  DRAM_BA,
    output      [12:0] DRAM_ADDR,
    inout       [15:0] DRAM_DQ,
    output             DRAM_CAS_N,
    output             DRAM_RAS_N,
    output             DRAM_WE_N,
    output             DRAM_CS_N,
    output             DRAM_LDQM,
    output             DRAM_UDQM,

    // GPIO
    inout       [35:0] GPIO_0,
    inout       [35:0] GPIO_1,

    // 7-Segment LED
    output      [6:0]  HEX0,
    output      [6:0]  HEX1,
    output      [6:0]  HEX2,
    output      [6:0]  HEX3,
    output      [6:0]  HEX4,
    output      [6:0]  HEX5,

    // Keys
    input       [3:0]  KEY,

    // LED
    output      [9:0]  LEDR,

    // PS/2
    inout              PS2_CLK,
    inout              PS2_DAT,
    inout              PS2_CLK2,
    inout              PS2_DAT2,

    // SD-Card
    output             SD_CLK,
    inout              SD_CMD,
    inout       [3:0]  SD_DATA,

    // Switch
    input       [9:0]  SW,

    // VGA
    output      [3:0]  VGA_R,
    output      [3:0]  VGA_G,
    output      [3:0]  VGA_B,
    output             VGA_HS,
    output             VGA_VS
);

// Z-state
assign DRAM_DQ = 16'hzzzz;
assign GPIO_0  = lock_r; // 36'hzzzzzzzz;
assign GPIO_1  = lock_q; // 36'hzzzzzzzz;

// LED OFF
assign HEX0 = 7'b1111111;
assign HEX1 = 7'b1111111;
assign HEX2 = 7'b1111111;
assign HEX3 = 7'b1111111;
assign HEX4 = 7'b1111111;
assign HEX5 = 7'b1111111;

// Генерация частот
wire locked;
wire clock_25;

de0pll unit_pll
(
    .clkin     (CLOCK_50),
    .m25       (clock_25),
    .locked    (locked)
);

// ---------------------------------------------------------------------

localparam depth = 8;
localparam width = 32;

wire [(width-1):0] ro[depth];
wire [(width-1):0] qo[depth];

reg  [(width-1):0] q    = 32'h12345532;
reg  [(width-1):0] b    = 32'h46474552;
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

// ---------------------------------------------------------------------

reg [31:0] lock_r;
reg [31:0] lock_q;

always @(posedge clock_25) begin

    lock_q  <= qo[depth-1];
    lock_r  <= ro[depth-1];

    q <= q + b;
    b <= b + 1;

end

// ---------------------------------------------------------------------

endmodule
