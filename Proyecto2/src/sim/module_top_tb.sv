`timescale 1ns/1ps

module module_top_tb;
    logic clk;
    logic [3:0] columnas;
    logic [3:0] filas_raw;
    logic [3:0] a;
    logic [6:0] d;
    logic [3:0] led;
    
    module_top uut (
        .clk(clk),
        .columnas(columnas),
        .filas_raw(filas_raw),
        .a(a),
        .d(d),
        .led(led)
    );
    
    always #18.519 clk = ~clk;
    
    initial begin
        $display("TEST CON RESET FIX");
        
        // Inicialización
        clk = 0;
        columnas = 4'b1111;
        
        #50000;
        $display("[%0t] Inicio - Filas: %b", $time, filas_raw);
        
        #100000;
        $display("[%0t] Despues de 100us - Filas: %b", $time, filas_raw);
        
        #500000;
        $display("[%0t] Despues de 500us - Filas: %b, Anodos: %b", $time, filas_raw, a);
        
        // Verificar si el reset funcionó
        if (filas_raw != 4'b1111) begin
            $display("✅ RESET FUNCIONA! Filas se escanean");
        end else begin
            $display("❌ Reset NO funciona");
        end
        
        $finish;
    end
endmodule