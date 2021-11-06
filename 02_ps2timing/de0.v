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
assign GPIO_0  = 36'hzzzzzzzz;
assign GPIO_1  = 36'hzzzzzzzz;

// Генерация частот
wire locked;
wire clock_25;

de0pll unit_pll
(
    .clkin     (CLOCK_50),
    .m25       (clock_25),
    .locked    (locked)
);

hex7 h0(.i(led[  3:0]), .o(HEX0));
hex7 h1(.i(led[  7:4]), .o(HEX1));
hex7 h2(.i(led[ 11:8]), .o(HEX2));
hex7 h3(.i(led[15:12]), .o(HEX3));
hex7 h4(.i(led[19:16]), .o(HEX4));
hex7 h5(.i(led[23:20]), .o(HEX5));

reg [23:0] led;

wire [7:0] keyb_ready;
wire [7:0] keyb_data;

always @(posedge clock_25) if (keyb_ready) led <= {led[15:0], keyb_data};

// Модуль клавиатуры
keyboard KeyboardPS2
(
    .clock_25   (clock_25),
    .PS2_CLK    (PS2_CLK),
    .PS2_DAT    (PS2_DAT),
    .keyb_ready (keyb_ready),
    .keyb_data  (keyb_data)
);

endmodule

