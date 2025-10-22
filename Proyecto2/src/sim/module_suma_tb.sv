`timescale 1ns/1ps

module module_suma_tb();
    reg clk;
    reg rst_n;
    reg [3:0] key_code;
    reg key_pulse;
    
    wire [13:0] resultado;
    wire result_valid;
    wire result_pulse;
    wire overflow;
    
    module_suma u_suma (
        .clk(clk),
        .rst_n(rst_n),
        .key_code(key_code),
        .key_pulse(key_pulse),
        .result(resultado),
        .result_valid(result_valid),
        .result_pulse(result_pulse),
        .overflow(overflow)
    );
    
    always #5 clk = ~clk;
    
    task press_key;
        input [3:0] k;
        begin
            key_code = k;
            @(posedge clk);
            key_pulse = 1'b1;
            @(posedge clk);
            key_pulse = 1'b0;
            #20;
        end
    endtask
    
    initial begin
        $display("=== PRUEBA NUEVO MODULE_SUMA ===");
        
        clk = 0;
        rst_n = 0;
        key_code = 0;
        key_pulse = 0;
        
        // Reset
        #100;
        rst_n = 1;
        #100;
        
        $display("1. 15 + 27 = 42");
        press_key(4'h1);
        press_key(4'h5);
        press_key(4'd10); // ADD
        press_key(4'h2);
        press_key(4'h7);
        press_key(4'd11); // EQUAL
        #50;
        $display("   Resultado: %d (esperado: 42)", resultado);
        
        $display("\n2. CLEAR y 8 + 5 = 13");
        press_key(4'd12); // CLEAR
        press_key(4'h8);
        press_key(4'd10); // ADD
        press_key(4'h5);
        press_key(4'd11); // EQUAL
        #50;
        $display("   Resultado: %d (esperado: 13)", resultado);
        
        $finish;
    end
    
    always @(posedge clk) begin
        if (result_pulse) begin
            $display(">>> RESULTADO CALCULADO: %d", resultado);
        end
    end
endmodule