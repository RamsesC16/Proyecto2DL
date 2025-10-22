`timescale 1ns/1ps

module module_disp_controller_tb;
    reg clk;
    reg rst;
    reg [15:0] data;
    wire [6:0] seg;
    wire [3:0] an;
    
    // Instancia del módulo bajo prueba
    module_disp_controller #(.DIVIDER(10)) uut (
        .clk(clk),
        .rst(rst),
        .data(data),
        .seg(seg),
        .an(an)
    );
    
    // Generación de reloj
    always #5 clk = ~clk;
    
    initial begin
        // Inicialización
        clk = 0;
        rst = 1;
        data = 16'h1234;
        
        // Reset
        #20;
        rst = 0;
        
        // Esperar varios ciclos de multiplexación
        #1000;
        
        // Verificar funcionamiento
        $display("Segmentos: %b, Anodos: %b", seg, an);
        
        // Cambiar datos
        data = 16'h5678;
        #1000;
        
        $display("Segmentos: %b, Anodos: %b", seg, an);
        $display("Test completado.");
        $finish;
    end

endmodule