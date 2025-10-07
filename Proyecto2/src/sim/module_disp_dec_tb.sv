`timescale 1ns/1ps

module module_disp_dec_tb;
    logic [3:0] w;         // Señal de entrada
    logic [6:0] d;      // Señal de salida

    // Instanciamos el módulo 'module_bcd_syndrome'
    module_disp_dec uut (.w(w), .d(d));

    initial begin
        // 0
        w = 4'b0000; #10;
        $display("Number: %b, Segments: %b", w, d);
        
        // 1
        w = 4'b0001; #10;
        $display("Number: %b, Segments: %b", w, d);

        // 2
        w = 4'b0010; #10;
        $display("Number: %b, Segments: %b", w, d);

        // 3
        w = 4'b0011; #10;
        $display("Number: %b, Segments: %b", w, d);

        // 4
        w = 4'b0100; #10;
        $display("Number: %b, Segments: %b", w, d);

        // 5
        w = 4'b0101; #10;
        $display("Number: %b, Segments: %b", w, d);
        
        // 6
        w = 4'b0110; #10;
        $display("Number: %b, Segments: %b", w, d);
        
        // 7
        w = 4'b0111; #10;
        $display("Number: %b, Segments: %b", w, d);

        // 8
        w = 4'b1000; #10;
        $display("Number: %b, Segments: %b", w, d);

        // 9
        w = 4'b1001; #10;
        $display("Number: %b, Segments: %b", w, d);
    end

    initial begin
        // Guardar el archivo de simulación en formato VCD
        $dumpfile("module_disp_dec_tb.vcd");
        $dumpvars(0, module_disp_dec_tb);  // Nombre correcto del módulo de prueba
    end
endmodule