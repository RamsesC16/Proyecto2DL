// ...existing code...
`timescale 1ns/1ps
module module_lecture_tb;
    logic clk;
    logic rst_n;
    logic [3:0] cols_in;
    logic [3:0] rows_out;
    logic [3:0] key_code;
    logic key_valid;
    logic key_pulse;
    integer pcount;

    // parámetros TB (muestras por fila)
    localparam integer SCAN_CYCLES_TB   = 20; // clocks por fila
    localparam integer SAMPLE_DELAY_TB  = 1;  // clocks desde drive hasta muestreo
    localparam integer DEBOUNCE_TB      = 6;  // muestras consecutivas necesarias

    module_lecture #(
        .SCAN_CYCLES      (SCAN_CYCLES_TB),
        .SAMPLE_DELAY     (SAMPLE_DELAY_TB),
        .DEBOUNCE_SAMPLES (DEBOUNCE_TB)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .cols_in(cols_in),
        .rows_out(rows_out),
        .key_code(key_code),
        .key_valid(key_valid),
        .key_pulse(key_pulse)
    );

    initial begin
        $dumpfile("module_lecture_tb.vcd");
        $dumpvars(0, module_lecture_tb);
    end

    // reloj 10ns
    initial clk = 0;
    always #5 clk = ~clk;

    // press_key: hold_samples = número de muestras (no clocks)
    task automatic press_key(input int row, input int col, input int hold_samples);
        integer timeout;
        integer hold_cycles;
        begin
            // esperar fila activa
            timeout = 1000;
            while (rows_out[row] !== 1'b0 && timeout > 0) begin
                @(posedge clk);
                timeout = timeout - 1;
            end
            if (timeout == 0) $display("WARN: timeout esperando fila %0d", row);

            // aplicar columna activa-low
            cols_in = 4'hF;
            cols_in[col] = 1'b0;

            // mantener durante hold_samples muestras => hold_samples * SCAN_CYCLES_TB clocks
            hold_cycles = hold_samples * SCAN_CYCLES_TB;
            repeat (hold_cycles) @(posedge clk);

            // soltar
            cols_in = 4'hF;
            // dejar unos clocks para estabilizar
            repeat (2) @(posedge clk);
        end
    endtask

    // escenario de pruebas
    initial begin
        rst_n   = 0;
        cols_in = 4'hF;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (10) @(posedge clk);

        $display("TB: rebote rapido (no debe generar key_valid)");
        // rebote: varias pulsaciones muy cortas (1 muestra)
        repeat (6) begin
            press_key(0, 0, 1);
            repeat (2) @(posedge clk);
        end
        repeat (SCAN_CYCLES_TB * 3) @(posedge clk);
        if (key_valid) $error("FAIL: rebote rapido produjo key_valid");

        $display("TB: pulso corto (< debounce) (no debe aceptar)");
        press_key(0, 0, DEBOUNCE_TB/2);
        repeat (SCAN_CYCLES_TB * 3) @(posedge clk);
        if (key_valid) $error("FAIL: pulso corto aceptado");

        $display("TB: pulso largo (> debounce) (debe aceptar una vez)");
        pcount = 0;
        // monitor concurrente: vigila key_pulse durante la pulsación y un margen posterior
        fork
            begin
                // duración de monitor: hold_samples*SCAN_CYCLES_TB + margen de espera
                integer monitor_cycles;
                monitor_cycles = (DEBOUNCE_TB + 2) * SCAN_CYCLES_TB + 50;
                repeat (monitor_cycles) begin
                    @(posedge clk);
                    if (key_pulse) pcount = pcount + 1;
                end
            end
            begin
                // ejecutar la pulsación (hold_samples = DEBOUNCE_TB+2 muestras)
                press_key(0, 0, DEBOUNCE_TB + 2);
            end
        join

        // comprobaciones
        if (!key_valid) $error("FAIL: pulso largo no produjo key_valid");
        if (pcount < 1) $error("FAIL: pulso largo produjo %0d key_pulse (esperado >=1)", pcount);
        else $display("PASS: pulso largo OK");

        $display("TB: dos pulsos separados (deben detectarse ambos)");
        // primer pulso (col1)
        press_key(0, 1, DEBOUNCE_TB + 2);
        repeat (DEBOUNCE_TB + SCAN_CYCLES_TB + 5) @(posedge clk);
        // segundo pulso (col2)
        press_key(0, 2, DEBOUNCE_TB + 2);
        repeat (DEBOUNCE_TB + SCAN_CYCLES_TB + 5) @(posedge clk);

        $display("END TB");
        $finish;
    end

    // monitor simple
    always @(posedge clk) begin
        if (key_pulse) $display("[%0t] key_pulse, code=%0d", $time, key_code);
    end

endmodule
// ...existing code...