`timescale 1ns/1ps

module module_bin_to_bcd_tb;
    logic [11:0] i_bin;
    logic [15:0] o_bcd;
    
    // Instancia del módulo bajo prueba
    module_bin_to_bcd uut (
        .i_bin(i_bin),
        .o_bcd(o_bcd)
    );
    
    initial begin
        $display("Iniciando testbench para bin_to_bcd...");
        
        // Test case 1: 123 (decimal)
        i_bin = 12'd123;
        #10;
        $display("Binario: %d -> BCD: %h (esperado: 0123)", i_bin, o_bcd);
        
        // Test case 2: 255 (decimal)
        i_bin = 12'd255;
        #10;
        $display("Binario: %d -> BCD: %h (esperado: 0255)", i_bin, o_bcd);
        
        // Test case 3: 999 (máximo con 12 bits)
        i_bin = 12'd999;
        #10;
        $display("Binario: %d -> BCD: %h (esperado: 0999)", i_bin, o_bcd);
        
        // Test case 4: 15 (decimal)
        i_bin = 12'd15;
        #10;
        $display("Binario: %d -> BCD: %h (esperado: 0015)", i_bin, o_bcd);
        
        // Test case 5: 0 (decimal)
        i_bin = 12'd0;
        #10;
        $display("Binario: %d -> BCD: %h (esperado: 0000)", i_bin, o_bcd);
        
        $display("Test completado.");
        $finish;
    end

endmodule