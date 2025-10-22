`timescale 1ns/1ps

module module_top(
    input  wire        clk,
    output wire [3:0]  columnas,
    input  wire [3:0]  filas_raw,
    output wire [3:0]  a,
    output wire [6:0]  d
);

    wire [3:0] key_sample;
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
    
    // Detección de pulsos de teclas
    reg [3:0] last_key_sample = 0;
    reg key_pulse = 0;
    
    always @(posedge clk) begin
        if (reset_counter < 24'hFFFFFF) begin
            reset_counter <= reset_counter + 1;
            rst_n <= 1'b0;
        end else begin
            rst_n <= 1'b1;
        end
    end

    // Detectar flanco de tecla para generar pulso
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_key_sample <= 0;
            key_pulse <= 0;
        end else begin
            // Detectar cuando cambia la tecla (flanco de subida)
            if (key_sample != 0 && key_sample != last_key_sample) begin
                key_pulse <= 1'b1;
            end else begin
                key_pulse <= 1'b0;
            end
            last_key_sample <= key_sample;
        end
    end

    // Módulo lecture (teclado)
    module_lecture u_lecture (
        .clk(clk),
        .n_reset(rst_n),
        .filas_raw(filas_raw),
        .columnas(columnas),
        .sample(key_sample)
    );

    // CONVERSOR de teclas físicas a códigos del módulo suma
    wire [3:0] key_code_para_suma;
    assign key_code_para_suma = 
        (key_sample == 4'h2) ? 4'h1 : // Tecla 1 física → Dígito 1
        (key_sample == 4'h5) ? 4'h2 : // Tecla 2 física → Dígito 2
        (key_sample == 4'h8) ? 4'h3 : // Tecla 3 física → Dígito 3
        (key_sample == 4'h3) ? 4'h4 : // Tecla 4 física → Dígito 4
        (key_sample == 4'h6) ? 4'h5 : // Tecla 5 física → Dígito 5
        (key_sample == 4'h9) ? 4'h6 : // Tecla 6 física → Dígito 6
        (key_sample == 4'h1) ? 4'h7 : // Tecla 7 física → Dígito 7
        (key_sample == 4'h4) ? 4'h8 : // Tecla 8 física → Dígito 8
        (key_sample == 4'h7) ? 4'h9 : // Tecla 9 física → Dígito 9
        (key_sample == 4'h0) ? 4'h0 : // Tecla 0 física → Dígito 0
        (key_sample == 4'hA) ? 4'd10 : // Tecla A → ADD
        (key_sample == 4'hB) ? 4'd11 : // Tecla B → EQUAL
        (key_sample == 4'hC) ? 4'd12 : // Tecla C → CLEAR
        4'd15; // Otras teclas → ignorar

    // NUEVO módulo suma funcional
    module_suma u_suma (
        .clk(clk),
        .rst_n(rst_n),
        .key_code(key_code_para_suma),
        .key_pulse(key_pulse),  // Usar detección real de pulsos
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