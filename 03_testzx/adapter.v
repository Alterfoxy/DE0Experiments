module adapter
(
    input  wire        clock_25,
    output wire        vga_hs,
    output wire        vga_vs,
    output wire [ 3:0] vga_r,
    output wire [ 3:0] vga_g,
    output wire [ 3:0] vga_b,
    input  wire [ 3:0] bgcolor,
    output wire [15:0] address,
    input  wire [ 7:0] data_in
);

// -----------------------------------------------------------------------------
reg [9:0] X;         // Положение луча рисования VGA по X=0..799
reg [9:0] Y;         // Y=0..524
reg [5:0] fcnt;      // 0..49
reg [7:0] masktmp;   // Временное значение Mask
reg [7:0] mask;      // Постоянное значение mask
reg [7:0] attr;      // Постоянное значение attr

// -----------------------------------------------------------------------------
// Вычисление положения луча
// -----------------------------------------------------------------------------
assign vga_hs  = X < 10'h2C0; // 0..2BF => 1; 2C0..31F => 0
assign vga_vs  = Y > 10'h20A; // 0..20A => 0; 20B..20C => 1

// Выбор адреса (либо CHAR, либо ATTR)
// В конце сигнала `xon_e` будет записан в TMPMASK
assign address = xon_e ? address_char : address_attr;

wire   xmax   = X == 10'h31f;
wire   ymax   = Y == 10'h20c;
wire   fmax   = fcnt == 49;

// Разрешение на выход
wire visible = (X > 10'h02F) && (X < 10'h2B0) && (Y > 10'h020) && (Y < 10'h201);
wire vspaper = (X > 10'h06F) && (X < 10'h270) && (Y > 10'h04F) && (Y < 10'h1D0);

// Получение (x,y) положения луча в области рисования PAPER
wire [8:0] x = (X - 10'h070 + 10'h10);
wire [8:0] y = (Y - 10'h050);

// -----------------------------------------------------------------------------
// ZX-спектрум экран
// -----------------------------------------------------------------------------

// Пиксель от 7 до 0
wire [ 2:0] bitn  = ~x[3:1];

// Если активирован FLASH бит и сейчас находится во втором периоде
wire        flash = attr[7] & (fcnt > 24);

// Вычислители запроса
wire xon_e = x[3:0] == 4'hE; // Запись в TMPMASK, запрос ATTR по ADDRESS_ATTR
wire xon_f = x[3:0] == 4'hF; // Запись в MASK, ATTR

// Вычисленный адрес
wire [15:0] address_char = {3'b010,    y[8:7], y[3:1], y[6:4], x[8:4]};
wire [15:0] address_attr = {6'b010110, y[8:4], x[8:4]};

// Текущий цвет бумаги: если пиксель есть, то выбирается [2:0] иначе [5:3]
wire [ 3:0] paper = {attr[6], mask[bitn] ^ flash ? attr[2:0] : attr[5:3]};

// Выбрать цвет
wire [ 3:0] color = visible ? (vspaper ? paper : bgcolor) : 4'b0000;

// Дешифрование спектрум-цвета
// -----------------------------------------------------------------------------
assign vga_r = {color[1] & color[3], {3{color[1]}}};
assign vga_g = {color[2] & color[3], {3{color[2]}}};
assign vga_b = {color[0] & color[3], {3{color[0]}}};
// -----------------------------------------------------------------------------

always @(posedge clock_25) begin

    X <= xmax ? 0 : (X + 1);
    Y <= xmax ? (ymax ? 0 : Y + 1) : Y;

    // Счетчик мерцаний
    fcnt    <= (xmax && ymax) ? (fmax ? 0 : fcnt + 1) : fcnt;

    // Запись маски во временный регистр
    masktmp <= xon_e ? data_in : masktmp;

    // Запись итогового результата
    mask    <= xon_f ? masktmp : mask;
    attr    <= xon_f ? data_in : attr;

end

endmodule
