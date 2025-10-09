`timescale 1ns/1ps

module module_top_tb;

    // Declaración de entradas
    logic clk;                   // Reloj 27 MHz
    logic [3:0] filas_raw;       // Entradas del teclado

    // Declaración de salidas
    logic [6:0] d;               // Segmentos del display
    logic [3:0] a;               // Control de los segmentos
    logic [3:0] columnas;        // Salida FSM de columnas
    logic [3:0] led;             // Señal de debug

    ////////////////////////////

    // Instanciación del módulo superior
    module_top uut (
        .clk(clk),
        .filas_raw(filas_raw),
        .d(d),
        .a(a),
        .columnas(columnas),
        .led(led)
    );

    ////////////////////////////

    // Generador de reloj
    always begin
        #18.5 clk = ~clk;  // 27 MHz => periodo 37 ns
    end

    initial begin
        clk = 0;
        filas_raw = 4'b0000;

        // Pruebas simples: simular cambios en filas_raw
        $monitor("t=%0t | filas_raw=%b | columnas=%b | display=%b | led=%b",
                 $time, filas_raw, columnas, d, led);

        #100 filas_raw = 4'b0001;
        #100 filas_raw = 4'b0010;
        #100 filas_raw = 4'b0100;
        #100 filas_raw = 4'b1000;

        #5000 $finish;
    end

    // Generación del archivo VCD
    initial begin
        $dumpfile("module_top_tb.vcd");
        $dumpvars(0, module_top_tb);
    end

endmodule