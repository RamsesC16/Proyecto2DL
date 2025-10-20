`timescale 1ns/1ps
module module_top_tb;

    // ==============================
    // Declaración de señales
    // ==============================
    logic clk;                    // reloj de 27 MHz
    logic [3:0] filas_raw;        // entradas del teclado
    logic [6:0] d;                // segmentos del display
    logic [3:0] a;                // control de dígitos del display
    logic [3:0] columnas;         // salidas hacia las columnas del teclado
    logic [3:0] led;              // leds de depuración

    // ==============================
    // Instanciación del módulo top
    // ==============================
    module_top uut (
        .clk(clk),
        .filas_raw(filas_raw),
        .d(d),
        .a(a),
        .columnas(columnas),
        .led(led)
    );

    // ==============================
    // Generador de reloj
    // ==============================
    always #18.5 clk = ~clk; // 27 MHz → periodo de 37 ns

    // ==============================
    // Bloque inicial
    // ==============================
    initial begin
        // Valores iniciales
        clk = 0;
        filas_raw = 4'b0000;

        // Mensaje de cabecera
        $display("Tiempo(ns) | filas_raw | columnas | display | a | led");

        // Monitoreo continuo
        $monitor("%0t | %b | %b | %b | %b | %b", $time, filas_raw, columnas, d, a, led);

        // ==============================
        // Estímulos de prueba
        // ==============================
        #100_000; filas_raw = 4'b0001;  // Presiona fila 0
        #100_000; filas_raw = 4'b0010;  // Presiona fila 1
        #100_000; filas_raw = 4'b0100;  // Presiona fila 2
        #100_000; filas_raw = 4'b1000;  // Presiona fila 3
        #100_000; filas_raw = 4'b0000;  // Suelta todas
        #200_000; filas_raw = 4'b0101;  // combinación aleatoria
        #100_000; filas_raw = 4'b0000;  // vuelve a reposo

        // ==============================
        // Fin de simulación
        // ==============================
        #100_000;
        $finish;
    end

    // ==============================
    // Dumpfile para GTKWave
    // ==============================
    initial begin
        $dumpfile("module_top_tb.vcd");
        $dumpvars(0, module_top_tb);
    end

endmodule