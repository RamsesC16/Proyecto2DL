`timescale 1ns/1ps
module module_DeBounce_tb();
    // Parameters for test
    localparam real CLK_FREQ_HZ    = 27_000_000.0;
    localparam real CLK_PERIOD    = 1e9 / CLK_FREQ_HZ; // ns per cycle
    localparam int  N             = 6;
    localparam int  MAX_COUNT_SIM = 80; // retención pequeña para simular rapido

    logic clk;
    logic n_reset;
    logic button_in;
    logic [3:0] columnas;
    logic DB_out;
    logic [3:0] columna_presionada;

    // Instantiate DUT with reduced MAX_COUNT for simulation speed
    module_DeBounce #(
        .N(N),
        .MAX_COUNT(MAX_COUNT_SIM)
    ) dut (
        .clk(clk),
        .n_reset(n_reset),
        .button_in(button_in),
        .columnas(columnas),
        .DB_out(DB_out),
        .columna_presionada(columna_presionada)
    );

    // clock generator
    initial clk = 0;
    always #(CLK_PERIOD/2.0) clk = ~clk;

    // helper task to print current counters and columns (hierarchical access)
    task automatic print_probe(string tag);
        $display("%0t %s: DB_out=%0b columnas=%b columna_presionada=%b db_cnt=%0d hold_cnt=%0d",
                 $time, tag, DB_out, columnas, columna_presionada,
                 dut.db_cnt, dut.hold_cnt);
    endtask

    // ensure DUT idle helper: waits until db_cnt==0 and DB_out==0 or times out
    task automatic wait_dut_idle(int timeout_cycles = 500);
        int waited = 0;
        while ((dut.db_cnt != 0 || DB_out != 0) && (waited < timeout_cycles)) begin
            @(posedge clk);
            waited++;
        end
        if (waited >= timeout_cycles) begin
            // if still not idle, perform a reset pulse to force known state
            $display("%0t WARNING: DUT not idle after %0d cycles, issuing reset", $time, timeout_cycles);
            n_reset = 0;
            repeat(2) @(posedge clk);
            n_reset = 1;
            repeat(10) @(posedge clk);
        end
    endtask

    // Background monitor: print when counters are non-zero to reduce log volume
    initial begin
        forever begin
            @(posedge clk);
            if (dut.db_cnt != 0 || dut.hold_cnt != 0) begin
                $display("%0t MON: db_cnt=%0d hold_cnt=%0d DB_out=%0b columnas=%b columna_presionada=%b",
                         $time, dut.db_cnt, dut.hold_cnt, DB_out, columnas, columna_presionada);
            end
        end
    end

    // Test stimulus
    initial begin
        $display("Starting instrumented debounce TB (full)");

        // init
        n_reset = 0;
        button_in = 0;
        columnas = 4'b0010;
        repeat(10) @(posedge clk);
        n_reset = 1;
        repeat(10) @(posedge clk);

        // 1) Clean press (no bounce) -> should trigger
        $display("\n---- Test 1: clean press ----");
        button_in = 1;
        // wait for DB_out assert, print at assert
        wait(DB_out == 1);
        print_probe("ASSERT");
        // wait for release then print
        wait(DB_out == 0);
        print_probe("RELEASE");

        // Ensure DUT idle before next test
        button_in = 0;
        wait_dut_idle(500);

        repeat(10) @(posedge clk);

        // 2) Short bounce -> should NOT trigger (DUT is idle beforehand)
        $display("\n---- Test 2: short bounce ----");
        // sanity check: must be idle
        if (dut.db_cnt != 0 || DB_out != 0) begin
            $display("%0t INFO: DUT not idle, forcing reset before Test 2", $time);
            n_reset = 0; @(posedge clk); @(posedge clk); n_reset = 1; repeat(10) @(posedge clk);
        end
        // apply short bounce pattern
        button_in = 1; @(posedge clk);
        button_in = 0; @(posedge clk);
        button_in = 1; @(posedge clk);
        button_in = 0;
        // monitor a window to ensure no DB_out
        repeat(200) begin
            @(posedge clk);
            if (DB_out) $error("Bounce incorrectly produced DB_out at time %0t", $time);
        end
        $display(" No DB_out as expected after short bounce");

        // Ensure DUT idle before next test
        button_in = 0;
        wait_dut_idle(500);

        repeat(10) @(posedge clk);

        // 3) Long noisy press that stabilizes -> should trigger
        $display("\n---- Test 3: long noisy press then stable ----");
        // simulate bouncing for some cycles
        for (int i = 0; i < 20; i = i + 1) begin
            button_in = (i % 2);
            @(posedge clk);
        end
        // then stable high and change columns mid-noise to see capture behaviour
        columnas = 4'b0100;
        button_in = 1;
        // wait for assert
        wait(DB_out == 1);
        print_probe("ASSERT_AFTER_NOISE");
        // hold some cycles while active
        repeat(50) @(posedge clk);
        // change columnas while DB_out is active to check if columna_presionada changes (it should not)
        columnas = 4'b1000;
        print_probe("CHANGED_COLUMN_DURING_ACTIVE");
        // wait for release
        wait(DB_out == 0);
        print_probe("RELEASE_AFTER_NOISE");

        $display("\nAll tests finished (instrumented full).");
        $finish;
    end
endmodule