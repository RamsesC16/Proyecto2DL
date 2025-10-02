`timescale 1ns / 1ps

module module_spi_lcd_tb;

    // Testbench signals
    logic clk;
    logic resetn;
    logic ser_rx;
    logic ser_tx;
    logic lcd_resetn;
    logic lcd_clk;
    logic lcd_cs;
    logic lcd_rs;
    logic lcd_data;

    // Instantiate the Unit Under Test (UUT)
    module_spi_lcd uut (
        .clk        (clk),
        .resetn     (resetn),
        .ser_tx     (ser_tx),
        .ser_rx     (ser_rx),
        .lcd_resetn (lcd_resetn),
        .lcd_clk    (lcd_clk),
        .lcd_cs     (lcd_cs),
        .lcd_rs     (lcd_rs),
        .lcd_data   (lcd_data)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #18.52 clk = ~clk;  // 27 MHz clock (period = 37.04 ns)
    end

    // Simulation control
    initial begin
        // Initialize
        $display("Starting simulation...");
        $dumpfile("module_spi_lcd_tb.vcd");  // For waveform viewing
        $dumpvars(0, module_spi_lcd_tb);
        
        // Reset sequence
        resetn = 0;
        ser_rx = 0;
        #100 resetn = 1;  // Release reset after 100 ns
        
        // Wait for sufficient time to observe behavior
        #1000000;  // Adjust the simulation time as necessary to observe the module behavior

        // End simulation
        $display("Ending simulation...");
        $finish;
    end

    // Monitor LCD signals
    initial begin
        $monitor("Time: %0dns, LCD Reset: %b, LCD CLK: %b, LCD CS: %b, LCD RS: %b, LCD Data: %b",
                 $time, lcd_resetn, lcd_clk, lcd_cs, lcd_rs, lcd_data);
    end

endmodule
