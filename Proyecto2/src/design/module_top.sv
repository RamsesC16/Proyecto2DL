`timescale 1ns/1ps

module module_top(
    input  wire        clk,
    output wire [3:0]  columnas,
    input  wire [3:0]  filas_raw,
    output wire [3:0]  a,
    output wire [6:0]  d
);

    wire [3:0] key_sample;
    wire [3:0] key_code_para_suma;
    wire [13:0] resultado_suma;
    wire result_valid;
    wire result_pulse;
    wire overflow;
    wire [11:0] bin_para_conversor;
    wire [15:0] bcd_para_display;
    wire [6:0] segments;
    wire [3:0] anodos;

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

    // Módulo lecture con mapeo original
    module_lecture u_lecture (
        .clk(clk),
        .n_reset(rst_n),
        .filas_raw(filas_raw),
        .columnas(columnas),
        .sample(key_sample)
    );

    // CONVERSOR CORREGIDO - basado en tu observación
    assign key_code_para_suma = 
        (key_sample == 4'h2) ? 4'h1 : // Tecla física 1 → Dígito 1 (correcto)
        (key_sample == 4'h5) ? 4'h2 : // Tecla física 2 → Dígito 2 (correcto)
        (key_sample == 4'h8) ? 4'h6 : // Tecla física 3 → Dígito 6
        (key_sample == 4'h3) ? 4'h1 : // Tecla física 4 → Dígito 1
        (key_sample == 4'h6) ? 4'h5 : // Tecla física 5 → Dígito 5
        (key_sample == 4'h9) ? 4'h6 : // Tecla física 6 → Dígito 6
        (key_sample == 4'h1) ? 4'h7 : // Tecla física 7 → Dígito 7
        (key_sample == 4'h4) ? 4'h8 : // Tecla física 8 → Dígito 8
        (key_sample == 4'h7) ? 4'h9 : // Tecla física 9 → Dígito 9
        (key_sample == 4'h0) ? 4'h0 : // Tecla física 0 → Dígito 0
        key_sample; // Letras se mantienen igual

    // Módulo suma
    module_suma u_suma (
        .clk(clk),
        .rst_n(rst_n),
        .key_code(key_code_para_suma),
        .key_pulse(1'b1),
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

    // Display controller
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