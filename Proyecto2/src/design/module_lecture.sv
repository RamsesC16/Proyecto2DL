`timescale 1ns/1ns
module module_lecture (
    input  logic clk,
    input  logic n_reset,
    input  logic [3:0] filas_raw,   // entradas del keypad
    output logic [3:0] columnas,    // salidas que escanean columnas (one-hot)
    output logic [3:0] sample       // tecla codificada (4 bits) o cero
);

    // Scanning parameters
    parameter int CLK_HZ = 27_000_000;
    parameter int COL_SCAN_HZ = 1000; // cuantas columnas por segundo (ajusta)
    localparam int CYCLES_PER_STEP = CLK_HZ / (COL_SCAN_HZ * 4);

    logic [$clog2(CYCLES_PER_STEP+1)-1:0] cnt;
    logic [1:0] cur_col;
    logic [3:0] filas_db;       // suponiendo que ya tienes un debouncer que genera esto
    // (si tu DeBounce.sv produce filas_db por columna, integra esa lógica aquí)

    // simple contador para cambiar la columna activa
    always_ff @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            cnt <= 0;
            cur_col <= 0;
        end else begin
            if (cnt >= CYCLES_PER_STEP-1) begin
                cnt <= 0;
                cur_col <= cur_col + 1;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

    // generar señales one-hot para columnas (activo alto)
    always_comb begin
        case (cur_col)
            2'd0: columnas = 4'b0001;
            2'd1: columnas = 4'b0010;
            2'd2: columnas = 4'b0100;
            2'd3: columnas = 4'b1000;
            default: columnas = 4'b0001;
        endcase
    end

    // Debounce: si ya tienes un DeBounce por fila/columna integra aquí
    // Para ejemplo simple, usamos directamente filas_raw (no ideal)
    assign filas_db = filas_raw; // reemplaza por la salida de tu debouncer

    // Mapear {columna_activa, filas_db} a un valor 'sample'
    // IMPORTANTE: ajustar los bits si tus niveles son activos bajos
    always_ff @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            sample <= 4'b0000;
        end else begin
            unique case ({columnas, filas_db})
                // columna 0 (0001):
                8'b0001_0001: sample <= 4'h7; // ejemplo: fila0 en columna0 => '7' (ajusta)
                8'b0001_0010: sample <= 4'h4;
                8'b0001_0100: sample <= 4'h1;
                8'b0001_1000: sample <= 4'hE; // '*' por ejemplo

                // columna 1 (0010):
                8'b0010_0001: sample <= 4'h8;
                8'b0010_0010: sample <= 4'h5;
                8'b0010_0100: sample <= 4'h2;
                8'b0010_1000: sample <= 4'h0;

                // columna 2 (0100):
                8'b0100_0001: sample <= 4'h9;
                8'b0100_0010: sample <= 4'h6;
                8'b0100_0100: sample <= 4'h3;
                8'b0100_1000: sample <= 4'hF; // '#'

                // columna 3 (1000):
                8'b1000_0001: sample <= 4'hA; // A,B,C,D u otro mapeo
                8'b1000_0010: sample <= 4'hB;
                8'b1000_0100: sample <= 4'hC;
                8'b1000_1000: sample <= 4'hD;

                default: sample <= 4'b0000;
            endcase
        end
    end

endmodule