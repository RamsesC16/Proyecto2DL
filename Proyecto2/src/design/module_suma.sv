module module_suma (
    input  logic clk,
    input  logic [3:0] sample,  // Valor del teclado
    output logic [15:0] cdu,    // Resultado en BCD: M C D U (4 bits cada uno)
    output logic [3:0] debug
);

    typedef enum logic [2:0] {S0, S1, S2, S3, S4, S5, S6} statetype;
    statetype state = S0;

    // Variables internas
    logic [9:0] w1, w2;
    logic [3:0] sample_A;
    logic flag;
    logic [11:0] sum;
    assign debug = ~state;



    logic [3:0] unidades1, unidades2, decenas1, decenas2;
    logic [3:0] centenas1, centenas2;


    always_comb begin
        w1 = (centenas1 * 100) +
             (decenas1  * 10) +
             unidades1;
        w2 = (centenas2 * 100) +
             (decenas2  * 10) +
             unidades2;  
    end

    // Registro de sample y detección de cambio
    always_ff @(posedge clk) begin
        sample_A <= sample;
    end

    assign flag = (sample_A != sample);

    // Máquina de estados
    always_ff @(posedge clk) begin
        if (flag && sample != 4'b1111) begin
            case (state)
                S0: centenas1 <= sample;
                S1: decenas1  <= sample;
                S2: unidades1  <= sample;
                S3: centenas2 <= sample;
                S4: decenas2  <= sample;
                S5: unidades2  <= sample;
                S6: sum <= w1 + w2;
            endcase

            case (state)
                S0: state <= S1;
                S1: state <= S2;
                S2: state <= S3;
                S3: state <= S4;
                S4: state <= S5;
                S5: state <= S6;
                S6: state <= S0;
                default: state <= S0;
            endcase
        end
    end

    bin_to_bcd conv_bcd (
        .i_bin(sum),
        .o_bcd(cdu)
    );
endmodule





module bin_to_bcd (
    input  logic [11:0] i_bin,  // Entrada binaria de 12 bits
    output logic [15:0] o_bcd   // Salida BCD de 16 bits
);
    logic [11:0] bin_shift;  // Registro para el desplazamiento
    logic [15:0] bcd;        // Registro de salida BCD


    integer i;
    always @(*) begin
        // Inicialización del registro BCD en 0
        bcd = 16'd0;  // 16 bits a cero
        bin_shift = i_bin;

        // Iteración de 12 ciclos (uno por cada bit de la entrada binaria)
        for (i = 0; i < 12; i = i + 1) begin
            // Corrige cada dígito BCD si es mayor que 4
            if (bcd[3:0] > 4)
                bcd[3:0] = bcd[3:0] + 3;
            if (bcd[7:4] > 4)
                bcd[7:4] = bcd[7:4] + 3;
            if (bcd[11:8] > 4)
                bcd[11:8] = bcd[11:8] + 3;
            if (bcd[15:12] > 4)
                bcd[15:12] = bcd[15:12] + 3;

            // Desplazamiento a la izquierda de bcd y se agrega el bit más significativo de bin_shift
            bcd = {bcd[14:0], bin_shift[11]};
            bin_shift = bin_shift << 1;
        end

        // Asignación de la salida BCD
        o_bcd = bcd;
    end
endmodule