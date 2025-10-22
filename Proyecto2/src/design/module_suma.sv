module module_suma #(
    parameter int RESULT_WIDTH = 14,    // bits for result (14 bits -> up to 16383), adjust if need >9999
    parameter int RESULT_MAX   = 10000  // decimal cap (e.g. 10000 => max displayable 0..9999)
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic [3:0]            key_code,   // 0..9 digits, 10=ADD,11=EQUAL,12=CLEAR
    input  logic                  key_pulse,  // one-shot per key press (1 clk)
    output logic [RESULT_WIDTH-1:0] result,    // current total (or last result)
    output logic                  result_valid, // level: a result is available
    output logic                  result_pulse, // one-shot when a result is produced (ADD/EQUAL)
    output logic                  overflow     // high when overflow occurred (saturated)
);

    // internal registers
    logic [RESULT_WIDTH-1:0] total_reg;
    logic [RESULT_WIDTH-1:0] curr_reg;
    logic result_valid_reg;
    logic result_pulse_reg;
    logic overflow_reg;

    // local helpers
    logic [RESULT_WIDTH-1:0] next_curr;
    logic [RESULT_WIDTH-1:0] next_total;
    logic [RESULT_WIDTH-1:0] digit_ext;
    logic is_digit;
    logic is_add;
    logic is_equal;
    logic is_clear;

    assign is_digit = (key_code <= 4'd9);
    assign is_add   = (key_code == 4'd10);
    assign is_equal = (key_code == 4'd11);
    assign is_clear = (key_code == 4'd12);

    // safe extension of digit
    assign digit_ext = { {(RESULT_WIDTH-4){1'b0}}, key_code }; // key_code <=9 fits

    // sequential logic: consume one-shot key_pulse
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_reg       <= '0;
            curr_reg        <= '0;
            result_valid_reg<= 1'b0;
            result_pulse_reg<= 1'b0;
            overflow_reg    <= 1'b0;
        end else begin
            // default clear pulse flag each clock
            result_pulse_reg <= 1'b0;

            if (key_pulse) begin
                if (is_clear) begin
                    // clear everything
                    total_reg        <= '0;
                    curr_reg         <= '0;
                    result_valid_reg <= 1'b0;
                    overflow_reg     <= 1'b0;
                end else if (is_digit) begin
                    // append decimal digit: curr*10 + digit
                    // compute tentative next_curr using wider temporary arithmetic
                    logic [RESULT_WIDTH:0] tmp;
                    tmp = curr_reg * 10 + digit_ext;
                    if (tmp >= RESULT_MAX) begin
                        curr_reg     <= {RESULT_WIDTH{1'b1}} & (RESULT_MAX - 1); // saturate
                        overflow_reg <= 1'b1;
                    end else begin
                        curr_reg <= tmp[RESULT_WIDTH-1:0];
                    end
                    // entering digits clears previous "result valid" state
                    result_valid_reg <= 1'b0;
                end else if (is_add || is_equal) begin
                    // perform total = total + curr
                    logic [RESULT_WIDTH:0] tmp_sum;
                    tmp_sum = total_reg + curr_reg;
                    if (tmp_sum >= RESULT_MAX) begin
                        total_reg    <= {RESULT_WIDTH{1'b1}} & (RESULT_MAX - 1); // saturate
                        overflow_reg <= 1'b1;
                    end else begin
                        total_reg <= tmp_sum[RESULT_WIDTH-1:0];
                    end
                    // reset current operand
                    curr_reg <= '0;
                    // produce result output
                    result_valid_reg <= 1'b1;
                    result_pulse_reg <= 1'b1;
                end
                // other key_codes ignored
            end
            // otherwise no change
        end
    end

    // outputs
    assign result       = total_reg;
    assign result_valid = result_valid_reg;
    assign result_pulse = result_pulse_reg;
    assign overflow     = overflow_reg;

endmodule