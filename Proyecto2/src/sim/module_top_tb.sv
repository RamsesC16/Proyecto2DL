`timescale 1ns/1ps

module tb_calculadora();
    reg clk;
    reg rst_n;
    reg [3:0] key_code;
    reg key_pulse;
    
    wire [13:0] resultado;
    wire result_valid;
    wire result_pulse;
    wire overflow;
    
    // Instanciar el módulo suma
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
    
    // Generador de reloj
    always #5 clk = ~clk;
    
    // Tareas para simular teclas
    task press_key;
        input [3:0] k;
        begin
            key_code = k;
            key_pulse = 1'b1;
            @(posedge clk);
            key_pulse = 1'b0;
            #100; // Esperar entre teclas
        end
    endtask
    
    initial begin
        // Inicializar
        clk = 0;
        rst_n = 0;
        key_code = 0;
        key_pulse = 0;
        
        // Reset
        #20;
        rst_n = 1;
        #100;
        
        $display("=== TEST 1: 15 + 27 ===");
        
        // Ingresar 15
        press_key(4'h1); // 1
        press_key(4'h5); // 5
        $display("Ingresado: 15");
        
        // Presionar ADD
        press_key(4'd10); // ADD
        $display("Presionado ADD");
        
        // Ingresar 27
        press_key(4'h2); // 2
        press_key(4'h7); // 7
        $display("Ingresado: 27");
        
        // Presionar EQUAL
        press_key(4'd11); // EQUAL
        $display("Presionado EQUAL");
        
        // Esperar resultado
        #200;
        $display("Resultado esperado: 42, Obtenido: %d", resultado);
        
        #100;
        
        $display("=== TEST 2: CLEAR ===");
        press_key(4'd12); // CLEAR
        $display("Presionado CLEAR");
        #100;
        $display("Resultado después de CLEAR: %d", resultado);
        
        #100;
        $display("=== SIMULACIÓN COMPLETADA ===");
        $finish;
    end
    
    // Monitorear cambios
    always @(posedge clk) begin
        if (result_pulse) begin
            $display("[%0t] Resultado calculado: %d", $time, resultado);
        end
    end

endmodule