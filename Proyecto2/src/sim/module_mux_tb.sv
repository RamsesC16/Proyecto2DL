`timescale 1ns/1ps

module module_mux_tb;

    // Entradas al DUT (Device Under Test)
    logic [2:0] a;
    logic [11:0] cdu;

    // Salida del DUT
    logic [3:0] w;

    // Instancia del módulo bajo prueba
    module_mux uut (
        .a(a),
        .cdu(cdu),
        .w(w)
    );

    initial begin
        $display("Tiempo |   a   |    cdu    |  w");
        $display("-------------------------------");

        // Valores de prueba
        cdu = 12'b0111_0011_0001; // centenas=0100(4), decenas=0011(3), unidades=0000(0)

        // Caso 1: Mostrar unidades
        a = 3'b001;
        #10;
        $display("%4dns | %b | %b | %b", $time, a, cdu, w);  // Esperado: w = 0000

        // Caso 2: Mostrar decenas
        a = 3'b010;
        #10;
        $display("%4dns | %b | %b | %b", $time, a, cdu, w);  // Esperado: w = 0011

        // Caso 3: Mostrar centenas
        a = 3'b100;
        #10;
        $display("%4dns | %b | %b | %b", $time, a, cdu, w);  // Esperado: w = 0100

        // Caso 4: Estado inválido (no one-hot)
        a = 3'b000;
        #10;
        $display("%4dns | %b | %b | %b", $time, a, cdu, w);  // Esperado: w = 0000

        $finish;
    end

endmodule