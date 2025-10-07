`timescale 1ns/1ps

module module_disp_controller_tb;

    // Señales del testbench
    logic clk;
    logic [2:0] a;

    // Instancia del módulo a probar
    module_disp_controller dut (.clk(clk), .a(a));

    // Generador de reloj (27 MHz)
    always #18.52 clk = ~clk; // Periodo = 37.04 ns → Half-period = 18.52 ns

    // Bloque inicial
    initial begin
        // Inicialización
        clk = 0;

        // Extiende la simulación a 10 ms para asegurar suficientes cambios de estado
        #10_000_000; 
        $stop;
    end

    // Monitoreo de las salidas
    initial begin
        $monitor("Time = %t ns, 7segOn = %b,%b,%b", 
                 $time, a[2], a[1], a[0]);
    end

    initial begin
        $dumpfile("module_disp_controller_tb.vcd"); // Archivo de volcado
        $dumpvars(0, module_disp_controller_tb); // Volcado de todas las variables del testbench
    end

endmodule