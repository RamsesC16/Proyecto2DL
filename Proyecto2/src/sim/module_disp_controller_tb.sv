`timescale 1ns/1ps

module module_disp_controller_tb();
    // Simulación con reloj reducido para ver la rotación rápidamente
    localparam int SIM_FREQ_HZ = 1_000_000; // 1 MHz
    localparam real CLK_PERIOD = 1e9 / SIM_FREQ_HZ;

    // Señales
    reg clk = 0;
    wire [3:0] a;

    // Clock generator
    always #(CLK_PERIOD/2.0) clk = ~clk;

    // Instancia DUT con parámetros de simulación coherentes (override)
    // fijamos max_count pequeño para ver cambios rápidos en sim
    module_disp_controller #(
        .frequency(1000000), // frecuencia para cálculo interno
        .max_count(100)     // fuerza un count pequeño para acelerar la rotación
    ) dut (
        .clk(clk),
        .a(a)
    );

    integer i;
    initial begin
        $display("TB disp controller (fixed) start");
        $display("time(ns)\ta");
        // Dejar arrancar reloj
        repeat (10) @(posedge clk);

        // Monitorea algunos instantes y muestra 'a' periódicamente
        for (i = 0; i < 2000; i = i + 1) begin
            @(posedge clk);
            if ((i % 10) == 0) $display("%0t\t%b", $time, a);
        end

        $display("Fin TB");
        $finish;
    end
endmodule