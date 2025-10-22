`timescale 1ns/1ps

module module_top(
    input  wire        clk,
    input  wire [3:0]  columnas,
    output wire [3:0]  filas_raw,  
    output wire [3:0]  a,
    output wire [6:0]  d
);

    // ==================================================
    // CALCULADORA COMPLETA - VERSIÓN CORREGIDA
    // ==================================================
    
    wire        key_valid;
    wire        key_pulse;
    wire [3:0]  key_code;
    wire [13:0] resultado_suma;
    wire        result_valid;
    wire        result_pulse;
    wire        overflow;
    wire [11:0] bin_para_conversor;
    wire [15:0] bcd_para_display;
    wire [6:0]  segments;
    wire [3:0]  anodos;

    // Reset interno
    reg rst_n;
    reg [23:0] reset_counter = 0;
    
    always @(posedge clk) begin
        if (reset_counter < 24'hFFFFFF) begin
            reset_counter <= reset_counter + 1;
            rst_n <= 1'b0;
        end else begin
            rst_n <= 1'b1;
        end
    end

    // Módulo lecture (teclado)
    module_lecture u_lecture (
        .clk(clk),
        .rst_n(rst_n),
        .cols_in(columnas),
        .rows_out(filas_raw),
        .key_code(key_code),
        .key_valid(key_valid),
        .key_pulse(key_pulse)
    );

    // Módulo suma
    module_suma u_suma (
        .clk(clk),
        .rst_n(rst_n),
        .key_code(key_code),
        .key_pulse(key_pulse),
        .result(resultado_suma),
        .result_valid(result_valid),
        .result_pulse(result_pulse),
        .overflow(overflow)
    );

    // Conversión a BCD
    assign bin_para_conversor = resultado_suma[11:0];
    
    module_bin_to_bcd u_bin_to_bcd (
        .i_bin(bin_para_conversor),
        .o_bcd(bcd_para_display)
    );

    // Display controller con orden invertido
    module_disp_controller u_display (
        .clk(clk),
        .rst(~rst_n),
        .data(bcd_para_display),
        .seg(segments),
        .an(anodos)
    );

    // Asignar salidas
    assign a = anodos;
    assign d = segments;

endmodule