`timescale 1ns/1ps

module module_lecture #(
    parameter SCAN_CYCLES       = 50,   // REDUCIDO para escaneo más rápido
    parameter DEBOUNCE_CYCLES   = 100   // REDUCIDO para menos debounce
)(
    input         clk,
    input         rst_n,
    input  [3:0]  cols_in,   // entradas de columnas (pull-ups en HW, activo 0)
    output [3:0]  rows_out,  // filas a manejar (activas low)
    output [3:0]  key_code,  // código de tecla (0..15)
    output        key_valid, // nivel debounced (alguna tecla presionada)
    output        key_pulse  // one-shot al detectarse 0->1 (prioritario)
);

    // sincronizador 2 etapas para las columnas
    reg [3:0] col_sync0, col_sync1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_sync0 <= 4'hF;
            col_sync1 <= 4'hF;
        end else begin
            col_sync0 <= cols_in;
            col_sync1 <= col_sync0;
        end
    end

    // escaneo de filas - MÁS RÁPIDO
    reg [15:0] scan_cnt;
    reg [1:0] row_idx;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_cnt <= 0;
            row_idx  <= 0;
        end else begin
            if (scan_cnt >= SCAN_CYCLES - 1) begin
                scan_cnt <= 0;
                row_idx  <= row_idx + 1;
            end else begin
                scan_cnt <= scan_cnt + 1;
            end
        end
    end

    // filas activas (one-hot, active low)
    reg [3:0] rows_out_reg;
    always @(*) begin
        case (row_idx)
            2'd0: rows_out_reg = 4'b1110;
            2'd1: rows_out_reg = 4'b1101;
            2'd2: rows_out_reg = 4'b1011;
            2'd3: rows_out_reg = 4'b0111;
            default: rows_out_reg = 4'b1111;
        endcase
    end
    
    assign rows_out = rows_out_reg;

    // Detección de tecla actual - MÁS SIMPLE
    reg [3:0] current_key;
    reg key_detected;
    
    always @(*) begin
        if (col_sync1 != 4'hF) begin
            casez (col_sync1)
                4'b???0: current_key = {row_idx, 2'd0};
                4'b??0?: current_key = {row_idx, 2'd1};
                4'b?0??: current_key = {row_idx, 2'd2};
                4'b0???: current_key = {row_idx, 2'd3};
                default: current_key = 4'd0;
            endcase
            key_detected = 1'b1;
        end else begin
            current_key = 4'd0;
            key_detected = 1'b0;
        end
    end

    // Debounce simple - MÁS RÁPIDO
    reg [DEBOUNCE_CYCLES-1:0] debounce_shift;
    reg key_pulse_reg;
    reg [3:0] last_key;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_shift <= 0;
            last_key <= 0;
            key_pulse_reg <= 0;
        end else begin
            key_pulse_reg <= 0;
            
            // Shift register para debounce
            debounce_shift <= {debounce_shift[DEBOUNCE_CYCLES-2:0], key_detected};
            
            // Detección inmediata para pruebas
            if (key_detected && (current_key != last_key)) begin
                last_key <= current_key;
                key_pulse_reg <= 1'b1;
            end
        end
    end

    // Salidas
    assign key_pulse = key_pulse_reg;
    assign key_valid = |debounce_shift; // Cualquier tecla detectada
    assign key_code = last_key;

endmodule