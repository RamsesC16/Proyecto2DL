`timescale 1ns/1ps
module module_bin_to_bcd (
    input  logic [11:0] i_bin,   // Entrada binaria de 12 bits
    output logic [15:0] o_bcd    // Salida BCD de 16 bits (4 dígitos)
);
    logic [11:0] bin_shift;
    logic [15:0] bcd;
    integer i;

    always_comb begin
        bcd = 16'd0;
        bin_shift = i_bin;
        for (i = 0; i < 12; i = i + 1) begin
            if (bcd[3:0]  > 4) bcd[3:0]  = bcd[3:0]  + 3;
            if (bcd[7:4]  > 4) bcd[7:4]  = bcd[7:4]  + 3;
            if (bcd[11:8] > 4) bcd[11:8] = bcd[11:8] + 3;
            if (bcd[15:12]> 4) bcd[15:12]= bcd[15:12]+ 3;
            bcd = {bcd[14:0], bin_shift[11]};
            bin_shift = bin_shift << 1;
        end
        o_bcd = bcd;
    end
endmodule