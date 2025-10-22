`timescale 1ns/1ps

module module_bin_to_bcd (
    input  [11:0] i_bin,   // Entrada binaria de 12 bits
    output [15:0] o_bcd    // Salida BCD de 16 bits (4 dígitos)
);

    reg [11:0] bin_shift;
    reg [15:0] bcd;
    integer i;

    always @(*) begin
        bcd = 0;
        bin_shift = i_bin;
        for (i = 0; i < 12; i = i + 1) begin
            if (bcd[3:0]   >= 5) bcd[3:0]   = bcd[3:0]   + 3;
            if (bcd[7:4]   >= 5) bcd[7:4]   = bcd[7:4]   + 3;
            if (bcd[11:8]  >= 5) bcd[11:8]  = bcd[11:8]  + 3;
            if (bcd[15:12] >= 5) bcd[15:12] = bcd[15:12] + 3;
            bcd = {bcd[14:0], bin_shift[11]};
            bin_shift = bin_shift << 1;
        end
        o_bcd = bcd;
    end

endmodule