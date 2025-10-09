`timescale 1ns/1ps

module module_disp_controller(
    input logic clk,
    output logic [3:0] a
);

    parameter int frequency = 27_000_000;               // Frecuencia de entrada en Hz
    parameter int max_count = frequency * 1/1000; // Cuenta máxima del contador

    logic [24:0] count;  // Contador con tamaño suficiente
   

    // Bloque secuencial
    always_ff @(posedge clk) begin
        if (count == max_count - 1) begin
            // Cambia el estado de los segmentos en secuencia cíclica
            case (a)
                4'b0001: a <= 4'b0010;
                4'b0010: a <= 4'b0100;
                4'b0100: a <= 4'b1000;
                4'b1000: a <= 4'b0001;
                default: a <= 4'b1000;
            endcase
            count <= 0;
        end 
        else begin
            count <= count + 1;
        end
    end

    // Inicialización adecuada en reset
    initial begin
        count = 0;
        a = 4'b0001; // Estado inicial del contador
    end

endmodule