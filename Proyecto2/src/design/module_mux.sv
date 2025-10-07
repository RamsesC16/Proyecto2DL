`timescale 1ns/1ps
// Este mux es controlado por el display controller, el cual indica si se deben mostrar las unidades, decenas o centenas.



module module_mux(
    input logic [3:0] a,    // Maquina de estados one-hot
    input logic [15:0] cdu,    // cdu[3:0] = unidades, cdu[7:4] = decenas, cdu[11:8] = centenas
    output logic [3:0] w    // Numero de 4 bits (salida)
);

    always_comb begin
        case (a)
            4'b0001: w = cdu[3:0];      // unidades
            4'b0010: w = cdu[7:4];      // decenas
            4'b0100: w = cdu[11:8];     // centenas
            4'b1000: w = cdu[15:12];    // miles
            default: w = 4'b0000;
        endcase
    end

    
endmodule