`timescale 1ns/1ns

module module_disp_dec(
    input logic [3:0] w, 
    output logic [6:0] d
);
    always_comb begin
        case(w)  // Cambiar 'digit' por 'w' (la entrada real)
        4'h0: d = 7'b1111110; // ABCDEF encendidos, G apagado
        4'h1: d = 7'b0110000; // BC encendidos
        4'h2: d = 7'b1101101; // ABDEG encendidos  
        4'h3: d = 7'b1111001; // ABCD encendidos
        4'h4: d = 7'b0110011; // BCFG encendidos
        4'h5: d = 7'b1011011; // ACDFG encendidos
        4'h6: d = 7'b1011111; // ACDEFG encendidos
        4'h7: d = 7'b1110000; // ABC encendidos
        4'h8: d = 7'b1111111; // Todos encendidos
        4'h9: d = 7'b1111011; // ABCDFG encendidos
        default: d = 7'b0000000; // Todos apagados
        endcase
    end
endmodule