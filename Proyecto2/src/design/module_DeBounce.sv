module module_DeBounce #(
    parameter integer STABLE_CYCLES = 1000 // ciclos de reloj que la entrada debe permanecer estable
)(
    input  logic clk,
    input  logic rst_n,     // activo bajo
    input  logic btn_async, // entrada asíncrona (botón)
    output logic btn_level, // nivel debounced
    output logic btn_pulse  // pulso de un ciclo en rising edge debounced
);

    // sincronizador de 2 etapas para mitigar metastabilidad
    logic sync_ff0, sync_ff1;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff0 <= 1'b0;
            sync_ff1 <= 1'b0;
        end else begin
            sync_ff0 <= btn_async;
            sync_ff1 <= sync_ff0;
        end
    end

    // contador para estabilidad
    logic [$clog2(STABLE_CYCLES+1)-1:0] stable_cnt;
    logic candidate;

    // candidate = valor sincronizado actual
    assign candidate = sync_ff1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stable_cnt <= '0;
            btn_level  <= 1'b0;
            btn_pulse  <= 1'b0;
        end else begin
            btn_pulse <= 1'b0; // default

            if (candidate == btn_level) begin
                // si coincide con el nivel actual, reiniciar contador
                stable_cnt <= '0;
            end else begin
                // candidato distinto: incrementar contador
                if (stable_cnt >= STABLE_CYCLES - 1) begin
                    // se mantuvo estable el tiempo requerido: actualizar nivel
                    btn_level <= candidate;
                    stable_cnt <= '0;
                    // generar pulso solo en transición 0->1
                    if (candidate == 1'b1)
                        btn_pulse <= 1'b1;
                end else begin
                    stable_cnt <= stable_cnt + 1'b1;
                end
            end
        end
    end

endmodule