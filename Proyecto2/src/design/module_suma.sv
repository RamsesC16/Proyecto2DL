module module_suma #(
    parameter RESULT_WIDTH = 14
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [3:0]            key_code,
    input  wire                  key_pulse,
    output reg [RESULT_WIDTH-1:0] result = 0,
    output reg                  result_valid = 0,
    output reg                  result_pulse = 0,
    output wire                 overflow
);

    reg [RESULT_WIDTH-1:0] current_value = 0;
    reg [RESULT_WIDTH-1:0] stored_value = 0;
    reg accumulating = 0;
    
    assign overflow = (result >= 10000);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_value <= 0;
            stored_value <= 0;
            result <= 0;
            result_valid <= 0;
            result_pulse <= 0;
            accumulating <= 0;
        end else begin
            result_pulse <= 0; // Reset pulse cada ciclo
            
            if (key_pulse) begin
                case (key_code)
                    // Dígitos 0-9
                    4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 
                    4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin
                        if (!accumulating) begin
                            current_value <= key_code;
                            accumulating <= 1;
                        end else begin
                            current_value <= (current_value * 10) + key_code;
                        end
                        result_valid <= 0;
                    end
                    
                    // ADD
                    4'd10: begin
                        stored_value <= current_value;
                        current_value <= 0;
                        accumulating <= 0;
                        result_valid <= 1;
                        result_pulse <= 1;
                    end
                    
                    // EQUAL
                    4'd11: begin
                        result <= stored_value + current_value;
                        current_value <= 0;
                        stored_value <= 0;
                        accumulating <= 0;
                        result_valid <= 1;
                        result_pulse <= 1;
                    end
                    
                    // CLEAR
                    4'd12: begin
                        current_value <= 0;
                        stored_value <= 0;
                        result <= 0;
                        accumulating <= 0;
                        result_valid <= 0;
                    end
                endcase
            end
        end
    end

endmodule