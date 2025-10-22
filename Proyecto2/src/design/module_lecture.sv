`timescale 1ns/1ps

module module_lecture(
    input        clk,
    input        n_reset,
    input  [3:0] filas_raw,
    output [3:0] columnas,
    output [3:0] sample
);

    reg [16:0] counter = 0;
    reg [1:0] col_index = 0;
    reg [3:0] columnas_reg = 4'b0001;
    reg [3:0] sample_reg = 4'h0;
    reg [3:0] last_tecla = 4'h0;
    reg [9:0] same_count = 0;

    always @(posedge clk or negedge n_reset) begin
        if (!n_reset) begin
            counter <= 0;
            col_index <= 0;
            columnas_reg <= 4'b0001;
            sample_reg <= 4'h0;
            last_tecla <= 4'h0;
            same_count <= 0;
        end else begin
            counter <= counter + 1;
            
            if (counter[16]) begin
                counter <= 0;
                col_index <= col_index + 1;
                
                case (col_index)
                    2'd0: columnas_reg <= 4'b0001;
                    2'd1: columnas_reg <= 4'b0010;
                    2'd2: columnas_reg <= 4'b0100;
                    2'd3: columnas_reg <= 4'b1000;
                endcase
            end
            
            // MAPEO ORIGINAL EXACTO (de tu versión que funcionaba)
            if (filas_raw != 4'b1111) begin
                case ({columnas_reg, filas_raw})
                    // COLUMNA 1
                    8'b0001_1110: if (last_tecla != 4'h2) begin last_tecla <= 4'h2; same_count <= 0; end
                    8'b0001_1101: if (last_tecla != 4'h5) begin last_tecla <= 4'h5; same_count <= 0; end
                    8'b0001_1011: if (last_tecla != 4'h8) begin last_tecla <= 4'h8; same_count <= 0; end
                    8'b0001_0111: if (last_tecla != 4'h0) begin last_tecla <= 4'h0; same_count <= 0; end

                    // COLUMNA 2
                    8'b0010_1110: if (last_tecla != 4'h3) begin last_tecla <= 4'h3; same_count <= 0; end
                    8'b0010_1101: if (last_tecla != 4'h6) begin last_tecla <= 4'h6; same_count <= 0; end
                    8'b0010_1011: if (last_tecla != 4'h9) begin last_tecla <= 4'h9; same_count <= 0; end
                    8'b0010_0111: if (last_tecla != 4'hF) begin last_tecla <= 4'hF; same_count <= 0; end

                    // COLUMNA 3
                    8'b0100_1110: if (last_tecla != 4'h1) begin last_tecla <= 4'h1; same_count <= 0; end
                    8'b0100_1101: if (last_tecla != 4'h4) begin last_tecla <= 4'h4; same_count <= 0; end
                    8'b0100_1011: if (last_tecla != 4'h7) begin last_tecla <= 4'h7; same_count <= 0; end
                    8'b0100_0111: if (last_tecla != 4'hE) begin last_tecla <= 4'hE; same_count <= 0; end

                    // COLUMNA 4
                    8'b1000_1110: if (last_tecla != 4'hA) begin last_tecla <= 4'hA; same_count <= 0; end
                    8'b1000_1101: if (last_tecla != 4'hB) begin last_tecla <= 4'hB; same_count <= 0; end
                    8'b1000_1011: if (last_tecla != 4'hC) begin last_tecla <= 4'hC; same_count <= 0; end
                    8'b1000_0111: if (last_tecla != 4'hD) begin last_tecla <= 4'hD; same_count <= 0; end
                endcase
                
                if (same_count < 10'h3FF) begin
                    same_count <= same_count + 1;
                end else begin
                    sample_reg <= last_tecla;
                end
            end else begin
                same_count <= 0;
                last_tecla <= 4'h0;
            end
        end
    end

    assign columnas = columnas_reg;
    assign sample = sample_reg;

endmodule