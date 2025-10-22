`timescale 1ns/1ps

module module_disp_controller #(
    parameter DIVIDER = 100000
)(
    input wire clk,
    input wire rst,
    input wire [15:0] data,
    output wire [6:0] seg,
    output reg [3:0] an
);

    reg [31:0] count = 0;
    reg [1:0] sel = 0;
    reg [3:0] digit;
    reg [6:0] seg_corrected;
    
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
    
    // Decodificador 7 segmentos (ÁNODO COMÚN) con ORDEN INVERTIDO
    // d[6] = G, d[5] = F, d[4] = E, d[3] = D, d[2] = C, d[1] = B, d[0] = A
    always @(*) begin
        case(digit)
            // Formato: {G,F,E,D,C,B,A} donde 1=encendido, 0=apagado
            4'h0: seg_corrected = 7'b0111111; // ABCDEF encendidos, G apagado
            4'h1: seg_corrected = 7'b0000110; // BC encendidos
            4'h2: seg_corrected = 7'b1011011; // ABDEG encendidos  
            4'h3: seg_corrected = 7'b1001111; // ABCD encendidos
            4'h4: seg_corrected = 7'b1100110; // BCFG encendidos
            4'h5: seg_corrected = 7'b1101101; // ACDFG encendidos
            4'h6: seg_corrected = 7'b1111101; // ACDEFG encendidos
            4'h7: seg_corrected = 7'b0000111; // ABC encendidos
            4'h8: seg_corrected = 7'b1111111; // Todos encendidos
            4'h9: seg_corrected = 7'b1101111; // ABCDFG encendidos
            default: seg_corrected = 7'b0000000; // Todos apagados
        endcase
    end
    
    assign seg = seg_corrected;
    
    // Selección de ánodos (activo bajo)
    always @(*) begin
        case(sel)
            2'b00: an = 4'b1110; // Display derecho
            2'b01: an = 4'b1101; // Display 1
            2'b10: an = 4'b1011; // Display 2  
            2'b11: an = 4'b0111; // Display izquierdo
        endcase
    end

endmodule