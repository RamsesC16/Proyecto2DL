module module_disp_controller #(
    parameter DIVIDER = 100000
)(
    input wire clk,
    input wire rst,
    input wire [15:0] data,
    output reg [6:0] seg,
    output reg [3:0] an
);

    reg [31:0] count = 0;
    reg [1:0] sel = 0;
    reg [3:0] digit;
    
    // Registro para segmentos (corregido)
    reg [6:0] seg_reg;
    
    // Lógica de multiplexación
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            sel <= 0;
        end else begin
            count <= count + 1;
            if (count == DIVIDER) begin
                count <= 0;
                if (sel == 3)
                    sel <= 0;
                else
                    sel <= sel + 1;
            end
        end
    end
    
    // Selección de dígito
    always @(*) begin
        case(sel)
            2'b00: digit = data[3:0];
            2'b01: digit = data[7:4];
            2'b10: digit = data[11:8];
            2'b11: digit = data[15:12];
            default: digit = 4'b0000;
        endcase
    end
    
    // Decodificador 7 segmentos (cátodo común para Tang Nano)
    always @(*) begin
        case(digit)
            4'h0: seg_reg = 7'b0000001;  // 0
            4'h1: seg_reg = 7'b1001111;  // 1
            4'h2: seg_reg = 7'b0010010;  // 2
            4'h3: seg_reg = 7'b0000110;  // 3
            4'h4: seg_reg = 7'b1001100;  // 4
            4'h5: seg_reg = 7'b0100100;  // 5
            4'h6: seg_reg = 7'b0100000;  // 6
            4'h7: seg_reg = 7'b0001111;  // 7
            4'h8: seg_reg = 7'b0000000;  // 8
            4'h9: seg_reg = 7'b0000100;  // 9
            default: seg_reg = 7'b1111111; // Apagado
        endcase
    end
    
    assign seg = seg_reg;
    
    // Selección de ánodos
    always @(*) begin
        case(sel)
            2'b00: an = 4'b1110;
            2'b01: an = 4'b1101;
            2'b10: an = 4'b1011;
            2'b11: an = 4'b0111;
            default: an = 4'b1111;
        endcase
    end

endmodule