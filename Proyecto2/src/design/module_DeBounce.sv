module module_DeBounce (
    input  logic clk,
    input  logic n_reset,
    input  logic button_in,
    input  logic [3:0] columnas,
    output logic DB_out,
    output logic [3:0] columna_presionada
);
    parameter int N = 6;                      // ancho del contador de debounce
    parameter int DEBOUNCE_MAX = (1<<N)-1;   // valor max para considerar estable
    parameter int MAX_COUNT = 15_000_000;    // retención 1s a 27MHz (ajustar si hace falta)

    // sincronizador de dos etapas
    logic sync1, sync2;

    // contador de debounce (pequeño)
    logic [N-1:0] db_cnt;

    // contador de retención (mantener DB_out en 1 por MAX_COUNT ciclos)
    logic [31:0] hold_cnt;
    logic active;

    // señales derivadas
    logic stable_high;

    // combinacional
    assign stable_high = (sync1 && sync2);

    // sincronizador (dos FF) y debounce / hold logic
    always_ff @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            sync1 <= 1'b0;
            sync2 <= 1'b0;
            db_cnt <= '0;
            DB_out <= 1'b0;
            active <= 1'b0;
            hold_cnt <= '0;
            columna_presionada <= 4'b0000;
        end else begin
            // sincronizar la entrada asincrona
            sync1 <= button_in;
            sync2 <= sync1;

            // debounce counter: contar cuando lectura sincronizada = 1
            if (stable_high && !active) begin
                if (db_cnt < DEBOUNCE_MAX)
                    db_cnt <= db_cnt + 1;
            end else begin
                db_cnt <= '0;
            end

            // Si el contador alcanzó el máximo y aún no estamos activos, activamos
            if ((db_cnt == DEBOUNCE_MAX) && !active) begin
                DB_out <= 1'b1;
                active <= 1'b1;
                hold_cnt <= 32'd0;
                columna_presionada <= columnas; // capturar columna cuando se confirma tecla estable
            end
            // Si ya estamos activos, contamos hasta MAX_COUNT para liberar
            else if (active) begin
                if (hold_cnt < MAX_COUNT) begin
                    hold_cnt <= hold_cnt + 1;
                end else begin
                    DB_out <= 1'b0;
                    active <= 1'b0;
                    columna_presionada <= 4'b0000;
                    hold_cnt <= 32'd0;
                    db_cnt <= '0;
                end
            end
        end
    end
endmodule