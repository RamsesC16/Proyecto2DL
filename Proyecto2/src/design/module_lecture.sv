// ...existing code...
module module_lecture #(
    parameter integer SCAN_CYCLES       = 500,  // ciclos por fila antes de pasar a la siguiente
    parameter integer SAMPLE_DELAY      = 2,    // ciclos desde drive row hasta muestreo
    parameter integer DEBOUNCE_SAMPLES  = 6     // muestras consecutivas iguales para aceptar tecla
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [3:0]  cols_in,   // entradas de columnas (pull-ups en HW, activo 0)
    output logic [3:0]  rows_out,  // filas a manejar (activas low)
    output logic [3:0]  key_code,  // código de tecla (0..15)
    output logic        key_valid, // nivel debounced (alguna tecla presionada)
    output logic        key_pulse  // one-shot al detectarse 0->1 (prioritario)
);

    // sincronizador 2 etapas para las columnas
    logic [3:0] col_sync0, col_sync1;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_sync0 <= 4'hF;
            col_sync1 <= 4'hF;
        end else begin
            col_sync0 <= cols_in;
            col_sync1 <= col_sync0;
        end
    end

    // escaneo de filas
    logic [$clog2(SCAN_CYCLES+1)-1:0] scan_cnt;
    logic [1:0] row_idx;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_cnt <= '0;
            row_idx  <= 2'd0;
        end else begin
            if (scan_cnt >= SCAN_CYCLES - 1) begin
                scan_cnt <= '0;
                row_idx  <= row_idx + 1'b1;
            end else begin
                scan_cnt <= scan_cnt + 1'b1;
            end
        end
    end

    // filas activas (one-hot, active low)
    always_comb begin
        case (row_idx)
            2'd0: rows_out = 4'b1110;
            2'd1: rows_out = 4'b1101;
            2'd2: rows_out = 4'b1011;
            2'd3: rows_out = 4'b0111;
            default: rows_out = 4'b1111;
        endcase
    end

    // evento de muestreo
    logic sample_event;
    assign sample_event = (scan_cnt == SAMPLE_DELAY);

    // helper index
    function automatic logic [3:0] col_index_of(input logic [3:0] cols);
        if (cols[0] == 1'b0) col_index_of = 4'd0;
        else if (cols[1] == 1'b0) col_index_of = 4'd1;
        else if (cols[2] == 1'b0) col_index_of = 4'd2;
        else if (cols[3] == 1'b0) col_index_of = 4'd3;
        else col_index_of = 4'd0;
    endfunction

    // Debounce simple por candidato (muestras por fila)
    logic [15:0] latched_keys;            // 1 = pressed (debounced)
    logic [3:0]  prev_candidate_index;
    logic        prev_candidate_active;
    logic [$clog2(DEBOUNCE_SAMPLES+1)-1:0] sample_stable_cnt;
    logic [3:0]  curr_candidate_index;
    logic        curr_candidate_active;
    logic        key_pulse_reg;

    // tomar muestra del candidato en cada sample_event
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_candidate_index <= 4'd0;
            prev_candidate_active <= 1'b0;
            sample_stable_cnt <= '0;
            latched_keys <= '0;
            key_pulse_reg <= 1'b0;
            curr_candidate_index <= 4'd0;
            curr_candidate_active <= 1'b0;
        end else begin
            key_pulse_reg <= 1'b0;

            if (sample_event) begin
                // leer probe sincronizada
                logic [3:0] sampled_cols;
                sampled_cols = col_sync1;

                if (sampled_cols != 4'hF) begin
                    curr_candidate_active = 1'b1;
                    curr_candidate_index  = {row_idx, col_index_of(sampled_cols)};
                end else begin
                    curr_candidate_active = 1'b0;
                    curr_candidate_index  = 4'd0;
                end

                // comparar con la muestra previa
                if (curr_candidate_active == prev_candidate_active && curr_candidate_index == prev_candidate_index) begin
                    if (sample_stable_cnt < DEBOUNCE_SAMPLES) sample_stable_cnt <= sample_stable_cnt + 1'b1;
                end else begin
                    prev_candidate_active <= curr_candidate_active;
                    prev_candidate_index  <= curr_candidate_index;
                    sample_stable_cnt     <= 1'b1;
                end

                // si estable por suficientes muestras, actualizar estado latched
                if (sample_stable_cnt >= DEBOUNCE_SAMPLES) begin
                    // actualizar la tecla correspondiente
                    if (curr_candidate_active) begin
                        // marcar presionada
                        if (!latched_keys[curr_candidate_index]) begin
                            latched_keys[curr_candidate_index] <= 1'b1;
                            key_pulse_reg <= 1'b1; // 0->1
                        end
                    end else begin
                        // liberar: si estaba marcada, limpiarla
                        if (latched_keys[prev_candidate_index]) begin
                            latched_keys[prev_candidate_index] <= 1'b0;
                        end
                    end
                    // saturar contador
                    sample_stable_cnt <= DEBOUNCE_SAMPLES;
                end
            end
        end
    end

    // salidas
    assign key_pulse = key_pulse_reg;
    assign key_valid = |latched_keys;

    // prioridad: primer índice con latched_keys==1
    logic [3:0] found_code;
    integer i;
    always_comb begin
        found_code = 4'd0;
        for (i = 0; i < 16; i = i + 1) begin
            if (latched_keys[i]) begin
                found_code = i[3:0];
                i = 16;
            end
        end
    end
    assign key_code = found_code;

endmodule
// ...existing code...