`timescale 1ns / 1ps

module blinky_led_tb;

    // Testbench signals
    logic clk;
    logic [5:0] led;

    // Instantiate the Unit Under Test 
    blinky_led #(135) DUT (
        .clk(clk),
        .led(led)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // 50 MHz clock (period = 20ns)
    end

    // Simulation control
    initial begin
        // Initialize
        $display("Starting simulation...");
        
        // Wait for some time to observe behavior
        #175000;  // Simulate for a sufficient amount of time to see LED changes

        // End simulation
        $display("Ending simulation...");
        $finish;
    end

    // Monitor LED changes
    initial begin
        $monitor("Time: %0dns, LED: %b", $time, led);
    end

    initial begin
        $dumpfile("blinky_led_tb.vcd");  // For waveform viewing
        $dumpvars(0, blinky_led_tb);
    end

endmodule
