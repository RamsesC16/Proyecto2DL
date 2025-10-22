// ...existing code...
module module_disp_controller #(
    parameter int RESULT_WIDTH = 14,   // ancho del resultado binario
    parameter int DIGITS       = 4,    // número de dígitos a mostrar (actual impl. para 4)
    parameter int SCAN_CYCLES  = 200   // clocks por dígito en multiplexado
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [RESULT_WIDTH-1:0] result_in,
    input  logic                    result_valid_in, // level; latch on rising
    output logic [6:0]              segs,    // a..g (1 = segment ON)
    output logic [DIGITS-1:0]       an,      // anodos/cátodos (active low: 0 enables digit)
    output logic                    busy     // high while converting (combinacional)
);

    // derived sizes
    localparam int LOG_DIGITS = (DIGITS <= 1) ? 1 : $clog2(DIGITS);
    localparam int LOG_SCAN  = $clog2(SCAN_CYCLES + 1);
    localparam int SHIFT_WIDTH = RESULT_WIDTH + 4*DIGITS;

    // state encoding (no typedef)
    localparam logic [1:0] S_IDLE    = 2'd0;
    localparam logic [1:0] S_CONVERT = 2'd1;
    localparam logic [1:0] S_READY   = 2'd2;

    logic [1:0] state, next_state;

    // registers
    logic [SHIFT_WIDTH-1:0] shift_reg;
    logic [$clog2(RESULT_WIDTH+1)-1:0] dd_cnt;
    logic prev_result_valid;

    // BCD digits storage (4 digits of 4 bits)
    logic [3:0] bcd0, bcd1, bcd2, bcd3;

    // multiplexing
    logic [LOG_DIGITS-1:0] digit_idx;
    logic [LOG_SCAN-1:0] scan_cnt;

    // sequential: control + double-dabble steps
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_result_valid <= 1'b0;
            state <= S_IDLE;
            shift_reg <= '0;
            dd_cnt <= '0;
            bcd0 <= 4'd0; bcd1 <= 4'd0; bcd2 <= 4'd0; bcd3 <= 4'd0;
            digit_idx <= '0;
            scan_cnt <= '0;
        end else begin
            prev_result_valid <= result_valid_in;
            state <= next_state;

            case (state)
                S_IDLE: begin
                    if (result_valid_in && !prev_result_valid) begin
                        // load: place binary in low bits and zeros in upper BCD area
                        shift_reg <= { { (4*DIGITS){1'b0} } , result_in };
                        dd_cnt <= '0;
                    end
                end
                S_CONVERT: begin
                    // add-3 on each BCD nibble if >=5 (upper BCD area)
                    logic [3:0] n0, n1, n2, n3;
                    n0 = shift_reg[RESULT_WIDTH+3:RESULT_WIDTH];
                    n1 = shift_reg[RESULT_WIDTH+7:RESULT_WIDTH+4];
                    n2 = shift_reg[RESULT_WIDTH+11:RESULT_WIDTH+8];
                    n3 = shift_reg[RESULT_WIDTH+15:RESULT_WIDTH+12];
                    logic [SHIFT_WIDTH-1:0] tmp;
                    tmp = shift_reg;
                    if (n0 >= 4'd5) tmp[RESULT_WIDTH+3:RESULT_WIDTH]    = n0 + 4'd3;
                    if (n1 >= 4'd5) tmp[RESULT_WIDTH+7:RESULT_WIDTH+4]  = n1 + 4'd3;
                    if (n2 >= 4'd5) tmp[RESULT_WIDTH+11:RESULT_WIDTH+8] = n2 + 4'd3;
                    if (n3 >= 4'd5) tmp[RESULT_WIDTH+15:RESULT_WIDTH+12]= n3 + 4'd3;
                    tmp = tmp << 1;
                    shift_reg <= tmp;
                    dd_cnt <= dd_cnt + 1'b1;
                end
                S_READY: begin
                    // capture BCD digits from upper bits of shift_reg
                    bcd0 <= shift_reg[RESULT_WIDTH+3:RESULT_WIDTH];
                    bcd1 <= shift_reg[RESULT_WIDTH+7:RESULT_WIDTH+4];
                    bcd2 <= shift_reg[RESULT_WIDTH+11:RESULT_WIDTH+8];
                    bcd3 <= shift_reg[RESULT_WIDTH+15:RESULT_WIDTH+12];
                end
                default: begin end
            endcase

            // multiplex scan counter (always running)
            if (scan_cnt >= SCAN_CYCLES - 1) begin
                scan_cnt <= '0;
                digit_idx <= digit_idx + 1'b1;
            end else begin
                scan_cnt <= scan_cnt + 1'b1;
            end
        end
    end

    // next_state logic (combinational)
    always_comb begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (result_valid_in && !prev_result_valid) next_state = S_CONVERT;
            end
            S_CONVERT: begin
                if (dd_cnt >= RESULT_WIDTH) next_state = S_READY;
            end
            S_READY: begin
                if (result_valid_in && !prev_result_valid) next_state = S_CONVERT;
            end
            default: next_state = S_IDLE;
        endcase
    end

    // anodes (active low) - explicit 4-digit mapping (synthesis-friendly)
    always_comb begin
        case (digit_idx)
            2'd0: an = 4'b1110;
            2'd1: an = 4'b1101;
            2'd2: an = 4'b1011;
            2'd3: an = 4'b0111;
            default: an = {DIGITS{1'b1}};
        endcase
    end

    // select current digit value
    logic [3:0] cur_digit_val;
    always_comb begin
        case (digit_idx)
            2'd0: cur_digit_val = bcd0;
            2'd1: cur_digit_val = bcd1;
            2'd2: cur_digit_val = bcd2;
            2'd3: cur_digit_val = bcd3;
            default: cur_digit_val = 4'd0;
        endcase
    end

    // 7-seg decoder (1 = segment ON)
    always_comb begin
        case (cur_digit_val)
            4'd0: segs = 7'b1111110;
            4'd1: segs = 7'b0110000;
            4'd2: segs = 7'b1101101;
            4'd3: segs = 7'b1111001;
            4'd4: segs = 7'b0110011;
            4'd5: segs = 7'b1011011;
            4'd6: segs = 7'b1011111;
            4'd7: segs = 7'b1110000;
            4'd8: segs = 7'b1111111;
            4'd9: segs = 7'b1111011;
            default: segs = 7'b0000000; // blank
        endcase
    end

    // busy is combinational from state (single driver)
    assign busy = (state == S_CONVERT);

endmodule
// ...existing code...