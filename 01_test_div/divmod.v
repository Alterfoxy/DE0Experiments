// Одна стадия деления */
module divmod
#(parameter WIDTH = 32)
(
    input   wire    [(WIDTH-1):0]  q,           // Делимое
    input   wire    [(WIDTH-1):0]  b,           // Делитель
    input   wire    [(WIDTH-1):0]  r,           // Остаток
    // ----
    // ----
    output  wire    [(WIDTH-1):0]  ro,          // Остаток
    output  wire    [(WIDTH-1):0]  qo           // Ответ
);

/*_____ _____
 |  r  |  q  | a - исходное делимое
 +-----+-----+ b - делитель
 |  b  |  qo | r - входящий остаток
 +-----+-----+
 |  ro |
 +----*/

// Сдвиг на один влево и вычитание
wire [(WIDTH-1):0] next = {r[(WIDTH-2):0], q[WIDTH-1]};
wire [ WIDTH   :0] subt = next - b;

// Мультиплексор, который определяет новый остаток
assign ro = subt[WIDTH] ? next : subt[(WIDTH-1):0];

// Сдвиг делимого влево и заполнение битом результата
assign qo = {q[(WIDTH-2):0], ~subt[WIDTH]};

endmodule
