`timescale 1ns/1ns
module module_disp_dec(
    input logic [3:0] w, 
    output logic [6:0] d
);
    always_comb begin
        case (w)
            4'h0: d = 7'b1111110;
            4'h1: d = 7'b0110000;
            4'h2: d = 7'b1101101;
            4'h3: d = 7'b1111001;
            4'h4: d = 7'b0110011;
            4'h5: d = 7'b1011011;
            4'h6: d = 7'b1011111;
            4'h7: d = 7'b1110000;
            4'h8: d = 7'b1111111;
            4'h9: d = 7'b1111011;
            4'hA: d = 7'b1110111;
            4'hB: d = 7'b0011111;
            4'hC: d = 7'b1001110;
            4'hD: d = 7'b0111101;
            4'hE: d = 7'b1001111;
            4'hF: d = 7'b1000111;
            default: d = 7'b0000000;
        endcase
    end
endmodule