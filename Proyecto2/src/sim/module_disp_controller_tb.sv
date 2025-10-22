// ...existing code...
`timescale 1ns/1ps
module module_disp_controller_tb;
    // parámetros TB
    localparam int RESULT_WIDTH = 14;
    localparam int DIGITS = 4;
    localparam int SCAN_CYCLES = 8;

    // señales
    logic clk;
    logic rst_n;
    logic [RESULT_WIDTH-1:0] result_in;
    logic result_valid_in;
    wire [6:0] segs;
    wire [DIGITS-1:0] an;
    wire busy;

    // instancia DUT (ajustada al nombre del módulo)
    module_disp_controller #(
        .RESULT_WIDTH(RESULT_WIDTH),
        .DIGITS(DIGITS),
        .SCAN_CYCLES(SCAN_CYCLES)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .result_in(result_in),
        .result_valid_in(result_valid_in),
        .segs(segs),
        .an(an),
        .busy(busy)
    );

    initial begin
        $dumpfile("module_disp_controller_tb.vcd");
        $dumpvars(0, module_disp_controller_tb);
    end

    // reloj 10ns
    initial clk = 0;
    always #5 clk = ~clk;

    // pulso de result_valid (one-shot)
    task automatic pulse_result(input int value);
        begin
            result_in = value;
            @(posedge clk);
            result_valid_in = 1;
            @(posedge clk);
            result_valid_in = 0;
            // unos ciclos
            repeat (2) @(posedge clk);
        end
    endtask

    // espera a que conversion termine (busy go HIGH then LOW)
    task automatic wait_conversion_complete(output int ok, input int timeout_cycles);
        integer i;
        begin
            ok = 0;
            // esperar busy=1
            for (i=0; i<timeout_cycles; i=i+1) begin
                @(posedge clk);
                if (busy) begin
                    ok = 1;
                    i = timeout_cycles;
                end
            end
            if (!ok) return;
            // esperar busy=0 (fin)
            ok = 0;
            for (i=0; i<timeout_cycles; i=i+1) begin
                @(posedge clk);
                if (!busy) begin
                    ok = 1;
                    i = timeout_cycles;
                end
            end
        end
    endtask

    // check_display espera un valor empaquetado: 16-bit con nibbles [3]=thousands .. [0]=units
    task automatic check_display(input logic [16-1:0] expected_packed, output int ok);
        integer d, i;
        int found;
        logic [3:0] expect_digit;
        logic [6:0] expect_seg;
        logic [DIGITS-1:0] target_an;
        begin
            ok = 1;
            for (d = 0; d < DIGITS; d = d + 1) begin
                expect_digit = expected_packed[d*4 +: 4]; // nibble
                case (d)
                    0: target_an = 4'b1110;
                    1: target_an = 4'b1101;
                    2: target_an = 4'b1011;
                    3: target_an = 4'b0111;
                    default: target_an = {DIGITS{1'b1}};
                endcase
                // expected segment pattern
                case (expect_digit)
                    4'd0: expect_seg = 7'b1111110;
                    4'd1: expect_seg = 7'b0110000;
                    4'd2: expect_seg = 7'b1101101;
                    4'd3: expect_seg = 7'b1111001;
                    4'd4: expect_seg = 7'b0110011;
                    4'd5: expect_seg = 7'b1011011;
                    4'd6: expect_seg = 7'b1011111;
                    4'd7: expect_seg = 7'b1110000;
                    4'd8: expect_seg = 7'b1111111;
                    4'd9: expect_seg = 7'b1111011;
                    default: expect_seg = 7'b0000000;
                endcase

                found = 0;
                for (i = 0; i < SCAN_CYCLES*6; i = i + 1) begin
                    @(posedge clk);
                    if (an === target_an) begin
                        if (segs === expect_seg) begin
                            found = 1;
                            i = SCAN_CYCLES*6;
                        end
                    end
                end
                if (!found) begin
                    $display("ERROR: digit %0d expected %0d but not observed (an=%b segs=%b)", d, expect_digit, an, segs);
                    ok = 0;
                end
            end
        end
    endtask

    // pruebas
    integer ok;
    initial begin
        // init
        rst_n = 0;
        result_in = '0;
        result_valid_in = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);

        $display("TB: TEST 1: value=0 -> 0000");
        pulse_result(0);
        wait_conversion_complete(ok, 2000);
        if (!ok) $error("Conversion timeout for 0");
        logic [15:0] exp_packed = {4'd0,4'd0,4'd0,4'd0}; // [3]=thousands .. [0]=units
        check_display(exp_packed, ok);
        if (ok) $display("PASS TEST1");

        $display("TB: TEST 2: value=12 -> 0012");
        pulse_result(12);
        wait_conversion_complete(ok, 2000);
        exp_packed = {4'd0,4'd0,4'd1,4'd2};
        check_display(exp_packed, ok);
        if (ok) $display("PASS TEST2");

        $display("TB: TEST 3: value=9999 -> 9999");
        pulse_result(9999);
        wait_conversion_complete(ok, 2000);
        exp_packed = {4'd9,4'd9,4'd9,4'd9};
        check_display(exp_packed, ok);
        if (ok) $display("PASS TEST3");

        $display("TB: TEST 4: random value 3057");
        pulse_result(3057);
        wait_conversion_complete(ok, 2000);
        exp_packed = {4'd3,4'd0,4'd5,4'd7};
        check_display(exp_packed, ok);
        if (ok) $display("PASS TEST4");

        $display("END TB - module_disp_controller_tb");
        $finish;
    end

endmodule
// ...existing code...