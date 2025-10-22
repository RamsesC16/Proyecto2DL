`timescale 1ns/1ps

module module_input_controller(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        key_pulse,      // Pulso de tecla detectada
    input  logic [3:0]  key_code,       // Código de tecla (0-15)
    output logic [3:0]  numA,           // Primer número
    output logic [3:0]  numB,           // Segundo número
    output logic        calculate_en,   // Habilitar cálculo
    output logic [1:0]  state_leds      // Estado para LEDs (debug)
);

    // Estados de la máquina de estados
    typedef enum logic [1:0] {
        STATE_A,        // Esperando número A
        STATE_B,        // Esperando número B  
        STATE_CALCULATE // Mostrando resultado
    } state_t;

    state_t current_state, next_state;

    // Registros para números A y B
    logic [3:0] numA_reg, numB_reg;

    // ==================================================
    // MÁQUINA DE ESTADOS - Lógica de siguiente estado
    // ==================================================
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            STATE_A: begin
                if (key_pulse && key_code <= 4'd9) // Solo teclas 0-9
                    next_state = STATE_B;
            end
            
            STATE_B: begin
                if (key_pulse && key_code <= 4'd9) // Solo teclas 0-9
                    next_state = STATE_CALCULATE;
            end
            
            STATE_CALCULATE: begin
                if (key_pulse) // Cualquier tecla para reiniciar
                    next_state = STATE_A;
            end
            
            default: next_state = STATE_A;
        endcase
    end

    // ==================================================
    // REGISTRO DE ESTADO
    // ==================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_A;
        end else begin
            current_state <= next_state;
        end
    end

    // ==================================================
    // CAPTURA DE NÚMEROS A Y B
    // ==================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            numA_reg <= 4'b0;
            numB_reg <= 4'b0;
        end else if (key_pulse && key_code <= 4'd9) begin
            case (current_state)
                STATE_A: numA_reg <= key_code;  // Capturar A
                STATE_B: numB_reg <= key_code;  // Capturar B
                default: ; // No hacer nada en otros estados
            endcase
        end
    end

    // ==================================================
    // SALIDAS
    // ==================================================
    assign numA = numA_reg;
    assign numB = numB_reg;
    
    // Habilitar cálculo solo cuando pasamos a STATE_CALCULATE
    assign calculate_en = (current_state == STATE_CALCULATE) && 
                         (next_state == STATE_CALCULATE);

    // LEDs para mostrar estado actual
    assign state_leds = current_state;

endmodule