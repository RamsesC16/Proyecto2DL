`timescale 1ns/1ps

module module_top_tb();
    // Parámetros de simulación reducidos para acelerar la rotación
    localparam int SIM_FREQ_HZ = 1_000_000; // 1 MHz clock en sim
    localparam int SIM_REF_HZ  = 10;        // refresco muy bajo -> MAX_COUNT = 100000
    localparam real CLK_PERIOD = 1e9 / SIM_FREQ_HZ;

    reg clk = 0;
    reg reset = 1;
    wire [3:0] a;

    // Clock
    always #(CLK_PERIOD/2.0) clk = ~clk;

    // DUT: instancia con parámetros pequeños para ver la rotación rápido
    module_disp_controller #(
        .FREQ_HZ(27_000_000),
        .REFRESH_HZ(10_0000),
        .INVERT_AN(1) // ajusta si tu placa usa activo-alto
    ) dut (
        .clk(clk),
        .reset(reset),
        .a(a)
    );

    integer i;
    initial begin
        $display("TB disp controller isolated start");
        // Reset pulse (activo-alto)
        reset = 1;
        repeat(5) @(posedge clk);
        reset = 0;
        repeat(2) @(posedge clk);

        $display("time(ns)    a");
        // Monitorea durante suficientes ciclos para ver varios cambios
        for (i = 0; i < 200000; i = i + 1) begin
            @(posedge clk);
            if ((i % 500) == 0) $display("%0t    %b", $time, a);
        end

        $display("Fin TB");
        $finish;
    end
endmodule