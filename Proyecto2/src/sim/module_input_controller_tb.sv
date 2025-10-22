`timescale 1ns/1ps

module module_input_controller_tb;
    logic clk, rst_n, key_pulse;
    logic [3:0] key_code;
    logic [3:0] numA, numB;
    logic calculate_en;
    logic [1:0] state_leds;
    
    module_input_controller uut (.*);
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0; rst_n = 0; key_pulse = 0; key_code = 0;
        #20 rst_n = 1;
        
        // Secuencia: 3 → 5 → Calcular
        #10 key_code = 4'd3; key_pulse = 1; #10 key_pulse = 0;
        #20 key_code = 4'd5; key_pulse = 1; #10 key_pulse = 0;
        #50;
        
        $display("Test completado - numA: %d, numB: %d", numA, numB);
        $finish;
    end
endmodule