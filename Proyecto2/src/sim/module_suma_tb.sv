// ...existing code...
`timescale 1ns/1ps
module module_suma_tb;
    // señales TB
    logic clk;
    logic rst_n;
    logic [3:0] key_code;
    logic key_pulse;
    integer seen; // <- moved here (was declared inside initial)

    // salidas DUT
    logic [13:0] result;
    logic result_valid;
    logic result_pulse;
    logic overflow;

    // parámetros de comprobación
    localparam int RESULT_MAX = 10000;

    // instancia DUT
    module_suma #(
        .RESULT_WIDTH(14),
        .RESULT_MAX(RESULT_MAX)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .key_code(key_code),
        .key_pulse(key_pulse),
        .result(result),
        .result_valid(result_valid),
        .result_pulse(result_pulse),
        .overflow(overflow)
    );

    // VCD
    initial begin
        $dumpfile("module_suma_tb.vcd");
        $dumpvars(0, module_suma_tb);
    end

    // reloj 10ns
    initial clk = 0;
    always #5 clk = ~clk;

    task automatic send_key(input [3:0] code);
        begin
            // mantener key_code y activar key_pulse en el posedge siguiente
            key_code  = code;
            key_pulse = 1;        // set BEFORE posedge so DUT samples it at the next clock
            @(posedge clk);       // DUT will see key_pulse == 1 at this posedge
            key_pulse = 0;        // one-cycle pulse
            key_code  = 4'd0;
            // margen
            repeat (2) @(posedge clk);
        end
    endtask

    // reemplazo: task que espera result_pulse hasta max_cycles y devuelve seen
    task automatic wait_for_pulse(output int seen, input int max_cycles);
        integer i;
        begin
            seen = 0;
            for (i = 0; i < max_cycles; i = i + 1) begin
                @(posedge clk);
                if (result_pulse) begin
                    seen = 1;
                    i = max_cycles; // salir del for
                end
            end
        end
    endtask

    // nueva: monitor concurrente que cuenta pulses durante N ciclos
    task automatic monitor_pulse(output int seen, input int cycles);
        integer i;
        integer cnt;
        begin
            cnt = 0;
            for (i = 0; i < cycles; i = i + 1) begin
                @(posedge clk);
                if (result_pulse) cnt = cnt + 1;
            end
            seen = (cnt > 0);
        end
    endtask

    // secuencia de pruebas
    initial begin
        // init
        rst_n = 0;
        key_code = 0;
        key_pulse = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);

        // TEST 1: ingresar 1,2 and ADD -> result == 12, pulse once
    $display("TB: TEST1 - 12 + (ADD)");
    send_key(4'd12); // CLEAR
    send_key(4'd1);
    send_key(4'd2);
    // ejecutar send_key(ADD) y monitor concurrente
    fork
        begin monitor_pulse(seen, 10); end
        begin send_key(4'd10); end
    join
    if (!seen) $error("FAIL TEST1: result_pulse not seen");
    if (result != 14'd12) $error("FAIL TEST1: expected result 12, got %0d", result);
    if (!result_valid) $error("FAIL TEST1: result_valid not asserted after ADD");
    else $display("PASS TEST1: result=%0d", result);

    // TEST 2: build 9999 and ADD
    $display("TB: TEST2 - build 9999 and ADD");
    send_key(4'd12); // CLEAR
    send_key(4'd9);
    send_key(4'd9);
    send_key(4'd9);
    send_key(4'd9);
    fork
        begin monitor_pulse(seen, 12); end
        begin send_key(4'd10); end
    join
    if (!seen) $error("FAIL TEST2: result_pulse not seen");
    if (result != RESULT_MAX - 1) $error("FAIL TEST2: expected %0d, got %0d", RESULT_MAX-1, result);
    else $display("PASS TEST2: result=%0d", result);

    // TEST 3: add 1 -> overflow expected
    $display("TB: TEST3 - cause overflow (add 1)");
    send_key(4'd1);
    fork
        begin monitor_pulse(seen, 12); end
        begin send_key(4'd10); end
    join
    if (!seen) $error("FAIL TEST3: result_pulse not seen");
    if (!overflow) $error("FAIL TEST3: overflow not asserted");
    if (result != RESULT_MAX - 1) $error("FAIL TEST3: expected saturated %0d, got %0d", RESULT_MAX-1, result);
    else $display("PASS TEST3: overflow asserted, result saturated=%0d", result);

    // TEST 4: EQUAL behaves like ADD
    $display("TB: TEST4 - EQUAL behavior");
    send_key(4'd12); // CLEAR
    send_key(4'd3);
    send_key(4'd4);
    fork
        begin monitor_pulse(seen, 10); end
        begin send_key(4'd11); end
    join
    if (!seen) $error("FAIL TEST4: result_pulse not seen");
    if (result != 14'd34) $error("FAIL TEST4: expected 34, got %0d", result);
    else $display("PASS TEST4: EQUAL produced result=%0d", result);

        // TEST 5: ensure CLEAR resets flags/state
        $display("TB: TEST5 - CLEAR resets");
        send_key(4'd12); // CLEAR
        repeat (2) @(posedge clk);
        if (result != 0) $error("FAIL TEST5: result not zero after CLEAR (%0d)", result);
        if (overflow) $error("FAIL TEST5: overflow not cleared after CLEAR");
        if (result_valid) $error("FAIL TEST5: result_valid not cleared after CLEAR");
        else $display("PASS TEST5: CLEAR ok");

        $display("END TB - module_suma_tb");
        $finish;
    end

endmodule
// ...existing