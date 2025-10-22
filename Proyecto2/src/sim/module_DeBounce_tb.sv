`timescale 1ns/1ps
module module_DeBounce_tb;
    logic clk;
    logic rst_n;
    logic btn_async;
    logic btn_level;
    logic btn_pulse;

    // usar STABLE_CYCLES pequeño para simular rápido
    localparam integer STABLE_CYCLES_TB = 20;

    module_DeBounce #(
        .STABLE_CYCLES(STABLE_CYCLES_TB)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .btn_async(btn_async),
        .btn_level(btn_level),
        .btn_pulse(btn_pulse)
    );

    initial begin
        $dumpfile("module_DeBounce_tb.vcd");
        $dumpvars(0, module_DeBounce_tb);
    end

    // reloj 10ns (100 MHz) para el TB
    initial clk = 0;
    always #5 clk = ~clk;

    // escenario de pruebas
    initial begin
        // reset
        rst_n = 0;
        btn_async = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        $display("[%0t] START tests", $time);

        // 1) rebote rapido: múltiples transiciones antes de STABLE_CYCLES
        fork
            begin
                // generar rebotes cortos
                repeat(6) begin
                    btn_async = ~btn_async;
                    repeat(2) @(posedge clk); // rápido: 2 ciclos
                end
                btn_async = 0;
            end
        join
        // esperar tiempo suficiente
        repeat(STABLE_CYCLES_TB + 5) @(posedge clk);

        // 2) pulso corto (< debounce): no debe generar btn_level=1
        btn_async = 1;
        repeat(STABLE_CYCLES_TB/2) @(posedge clk); // menor a estable
        btn_async = 0;
        repeat(STABLE_CYCLES_TB + 5) @(posedge clk);

        // 3) pulso largo (> debounce): debe aceptar
        btn_async = 1;
        repeat(STABLE_CYCLES_TB + 2) @(posedge clk);
        btn_async = 0;
        repeat(STABLE_CYCLES_TB + 5) @(posedge clk);

        // 4) secuencia de dos pulsos separados
        btn_async = 1;
        repeat(STABLE_CYCLES_TB + 2) @(posedge clk);
        btn_async = 0;
        repeat(STABLE_CYCLES_TB + 10) @(posedge clk);
        btn_async = 1;
        repeat(STABLE_CYCLES_TB + 2) @(posedge clk);
        btn_async = 0;
        repeat(STABLE_CYCLES_TB + 5) @(posedge clk);

        $display("[%0t] END tests", $time);
        $finish;
    end

    // monitors simples
    always @(posedge clk) begin
        if (btn_pulse) $display("[%0t] btn_pulse asserted", $time);
    end

endmodule