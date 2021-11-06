module adapter
(
    input   wire        CLOCK,
    output  reg  [3:0]  VGA_R,
    output  reg  [3:0]  VGA_G,
    output  reg  [3:0]  VGA_B,
    output  wire        VGA_HS,
    output  wire        VGA_VS,
    input   wire [3:0]  KEY
);

// ---------------------------------------------------------------------
// Тайминги для горизонтальной и вертикальной развертки
//        Visible    Front     Sync      Back      Whole
parameter hzv = 640, hzf = 16, hzs = 96, hzb = 48, hzw = 800,
          vtv = 400, vtf = 12, vts = 2,  vtb = 35, vtw = 449;
// ---------------------------------------------------------------------
assign VGA_HS = X  < (hzb + hzv + hzf); // NEG
assign VGA_VS = Y >= (vtb + vtv + vtf); // POS
// ---------------------------------------------------------------------
// Позиция луча в кадре и максимальные позиции (x,y)
reg  [ 9:0] X = 0; wire xmax = (X == hzw - 1);
reg  [ 9:0] Y = 0; wire ymax = (Y == vtw - 1);
wire [ 9:0] x = (X - hzb); // x=[0..639]
wire [ 9:0] y = (Y - vtb); // y=[0..399]
// ---------------------------------------------------------------------

reg  [9:0]  lf_player = 32;
reg  [9:0]  rt_player = 60;

reg  [1:0]  np; // Следующий ход
reg  [9:0]  x_bullet  = 320;
reg  [9:0]  y_bullet  = 200;
reg         x_dir     = 1'b0;
reg         y_dir     = 1'b0;
reg  [7:0]  lf_life;
reg  [7:0]  rt_life;

// Область рисования игрока
wire is_lf_player = x > 32  && x < 40    && y > lf_player && y < lf_player + 64;
wire is_rt_player = x > 608 && x < 608+8 && y > rt_player && y < rt_player + 64;
// Область рисования бордера
wire is_border  =   ((x == 30 || x == 618) && y >= 10 && y <= 390) ||
                    ((y == 10 || y == 390) && x >= 30 && x <= 618) ||
                     (x == 320 || x == 321);
// Рисование мяча
wire is_bullet  =   (x >= x_bullet - 4) && (x <= x_bullet + 4) &&
                    (y >= y_bullet - 4) && (y <= y_bullet + 4);

// Полоски выигранных матчей
wire is_life =
    (x[1:0] != 3'b00) && (y >= 392) &&
    ( (x < 320 && x > 320 - (lf_life << 2)) ||
      (x > 320 && x < 320 + (rt_life << 2))
    );

always @(posedge CLOCK) begin

    // Кадровая развертка
    X <= xmax ?         0 : X + 1;
    Y <= xmax ? (ymax ? 0 : Y + 1) : Y;

    // Игровая логика 60 кадров
    if (xmax && ymax) begin

        // Направление полета
        x_bullet <= x_dir ? x_bullet + 1'b1 : x_bullet - 1'b1;
        y_bullet <= y_dir ? y_bullet + 1'b1 : y_bullet - 1'b1;

        // Отбит левым игроком
        if      ((x_bullet == 40+4) && (y_bullet > lf_player-4) && (y_bullet < lf_player+64+4))
        begin x_bullet <= 40+4+1; x_dir <= 1'b1; end

        // Отбит правым игроком
        else if ((x_bullet == 607) && (y_bullet > rt_player-4) && (y_bullet < rt_player+64+4))
        begin x_bullet <= 607-1; x_dir <= 1'b0; end

        // Условия выигрыша
        else if (x_bullet == 0 || x_bullet == 640) begin

            x_bullet <= 320;
            y_bullet <= 200;
            x_dir    <= np[0];
            y_dir    <= np[1];

            if (x_bullet) rt_life <= rt_life + 1; // x_bullet=640
            else          lf_life <= lf_life + 1; // x_bullet=0

            np <= ~np;

        end

        // Отбивание
        if      (y_bullet ==  14) begin y_dir <= 1'b1; y_bullet <= 15; end
        else if (y_bullet == 386) begin y_dir <= 1'b0; y_bullet <= 385; end

        // Движение левого игрока
        if (lf_player > 12     && KEY[0] == 1'b0) lf_player <= lf_player - 1;
        if (lf_player < 390-66 && KEY[1] == 1'b0) lf_player <= lf_player + 1;

        // Движение правого игрока
        if (rt_player > 12     && KEY[2] == 1'b0) rt_player <= rt_player - 1;
        if (rt_player < 390-66 && KEY[3] == 1'b0) rt_player <= rt_player + 1;

    end

    // Вывод окна видеоадаптера
    if (X >= hzb && X < hzb + hzv && Y >= vtb && Y < vtb + vtv)
    begin
         {VGA_R, VGA_G, VGA_B} <=
            is_lf_player || is_rt_player ? 12'h0F0 :
            is_life   ? 12'hF00 :
            is_bullet ? 12'hF80 :
            is_border ? 12'h028 :
                        12'h111;
    end
    else {VGA_R, VGA_G, VGA_B} <= 12'b0;

end

endmodule
