/*
 * Модуль приема данных от клавиатуры PS/2
 * При keyb_ready=1, на позитивном фронте clock_25 будут доступен keyb_data
 */

module keyboard
(
    input   wire        clock_25,
    inout   wire        PS2_CLK,
    inout   wire        PS2_DAT,
    output  reg         keyb_ready,
    output  reg [7:0]   keyb_data
);

// ---------------------------------------------------------------------
// ОБЪЯВЛЕНИЯ
// ---------------------------------------------------------------------

reg         state;
reg [ 9:0]  data;
reg [ 3:0]  cnt;
reg [ 1:0]  k;

// ---------------------------------------------------------------------
// ОСНОВНАЯ ЛОГИКА
// ---------------------------------------------------------------------

always @(negedge clock_25) begin

    keyb_ready <= 1'b0;

    case (state)

    // Статус ожидания старта
    0: if (k == 2'b10) begin state <= 1'b1; cnt <= 0; end

    // На позитивном фронте CLK
    1: if (k == 2'b01) begin

        //     1   9..2    10       11
        // Start | 8 bit | Parity | Stop
        if (cnt == 10) begin

            // В data[9] => Parity (проверить четность)
            // В data[0] => Start (равен 0)

            state       <= 1'b0;
            keyb_ready  <= (PS2_DAT == 1'b1) && (data[0] == 1'b0);
            keyb_data   <= data[8:1];

        end

        // LSB первым идет
        data  <= {PS2_DAT, data[9:1]};
        cnt   <= cnt + 1;

    end

    endcase

    k <= {k[0], PS2_CLK};

end

endmodule

