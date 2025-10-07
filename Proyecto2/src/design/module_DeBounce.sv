module module_DeBounce (
    input  logic clk,
    input  logic n_reset,
    input  logic button_in,
    input  logic [3:0] columnas,           // columnas del teclado
    output logic DB_out,                   // salida debounced de 1s
    output logic [3:0] columna_presionada  // columna registrada
);
    parameter N = 6;
    parameter integer MAX_COUNT = 15_000_000; // 1s @ 27MHz

    // Señales internas
    reg [N-1:0] q_reg, q_next;
    reg DFF1, DFF2;
    wire q_reset = (DFF1 ^ DFF2);
    wire q_add   = ~q_reg[N-1];

    logic [31:0] counter;
    logic active;

    // Lógica combinacional del contador de rebote
    always @(*) begin
        case ({q_reset, q_add})
            2'b00: q_next = q_reg;
            2'b01: q_next = q_reg + 1;
            default: q_next = {N{1'b0}};
        endcase
    end

    // Lógica secuencial principal
    always_ff @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            DFF1               <= 0;
            DFF2               <= 0;
            q_reg              <= 0;
            DB_out             <= 0;
            active             <= 0;
            counter            <= 0;
            columna_presionada <= 4'b0000;
        end else begin
            // Antirrebote
            DFF1  <= button_in;
            DFF2  <= DFF1;
            q_reg <= q_next;

            if (q_reg[N-1] && DFF2 && !active) begin
                DB_out             <= 1;
                active             <= 1;
                counter            <= 0;
                columna_presionada <= columnas; // Registramos la columna cuando se activa
            end
            else if (active) begin
                if (counter < MAX_COUNT) begin
                    counter <= counter + 1;
                end else begin
                    DB_out  <= 0;
                    active  <= 0;
                    columna_presionada <= 4'b0000; // Reiniciamos la columna registrada
                end
            end
        end
    end
endmodule