`timescale 1ns/1ns

module module_freq_div_tb;

    // Señales del testbench
    logic clk;
    logic a1, a2, a3;

    // Instancia del módulo a probar
    module_freq_div dut (
        .clk(clk),
        .a1(a1),
        .a2(a2),
        .a3(a3)
    );

    // Generador de reloj (27 MHz)
    always #18.52ns clk = ~clk; // Periodo = 37.04 ns → Half-period = 18.52 ns

    // Bloque inicial
    initial begin
        // Inicialización
        clk = 0;

        // Extiende la simulación a 10 ms para asegurar suficientes cambios de estado
        #100_000_000; 

        // Termina la simulación
        $stop;
    end

    // Monitoreo de las salidas
    initial begin
        $monitor("Time = %t ns, 7segOn = %b,%b,%b", 
                 $time, a1, a2, a3);
    end

    initial begin
        $dumpfile("module_freq_div_tb.vcd"); // Archivo de volcado
        $dumpvars(0, module_freq_div_tb); // Volcado de todas las variables del testbench
    end

endmodule