`timescale 1ns/1ps

module module_lecture_tb;
    logic clk, rst_n;
    logic [3:0] cols_in;
    logic [3:0] rows_out, key_code;
    logic key_valid, key_pulse;
    
    module_lecture uut (
        .clk(clk),
        .rst_n(rst_n),
        .cols_in(cols_in),
        .rows_out(rows_out),
        .key_code(key_code),
        .key_valid(key_valid),
        .key_pulse(key_pulse)
    );
    
    // Reloj 27 MHz (Tang Nano 9K)
    always #18.519 clk = ~clk;
    
    initial begin
        $display("====================================");
        $display("🚀 TEST module_lecture SIMPLIFICADO");
        $display("====================================");
        
        // Inicialización
        clk = 0;
        rst_n = 0;
        cols_in = 4'b1111;
        
        // Reset
        #100000;
        rst_n = 1;
        $display("[%0t] Reset completado", $time);
        
        // Esperar a que empiece el escaneo
        #100000;
        $display("[%0t] Filas escaneando: %b", $time, rows_out);
        
        // TEST 1: Tecla 5 (Fila 1, Columna 1)
        $display("\n--- TEST 1: Tecla 5 ---");
        wait(rows_out == 4'b1101); // Esperar a fila 1
        cols_in = 4'b1101; // Activar columna 1
        $display("[%0t] Tecla 5 presionada - rows_out: %b, cols_in: %b", $time, rows_out, cols_in);
        
        // Esperar detección
        #500000;
        $display("[%0t] key_code=%d, key_valid=%b, key_pulse=%b", $time, key_code, key_valid, key_pulse);
        
        // Liberar tecla
        cols_in = 4'b1111;
        #500000;
        
        // TEST 2: Tecla 3 (Fila 0, Columna 3)  
        $display("\n--- TEST 2: Tecla 3 ---");
        wait(rows_out == 4'b1110); // Esperar a fila 0
        cols_in = 4'b0111; // Activar columna 3
        $display("[%0t] Tecla 3 presionada - rows_out: %b, cols_in: %b", $time, rows_out, cols_in);
        
        // Esperar detección
        #500000;
        $display("[%0t] key_code=%d, key_valid=%b, key_pulse=%b", $time, key_code, key_valid, key_pulse);
        
        $display("\n====================================");
        $display("✅ TEST COMPLETADO");
        $display("====================================");
        $finish;
    end
    
    // Monitoreo continuo
    initial begin
        #1000;
        forever begin
            #50000;
            if (key_pulse) begin
                $display("[%0t] 🔑 PULSO DETECTADO! key_code=%d", $time, key_code);
            end
        end
    end

endmodule