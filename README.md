# Proyecto 2 Diseño Lógico.
Integrantes: Julio David Quesada Hernández, Ramses Cortes Torres. 

## 1. Abreviatura y Definiciones:
FPGA (Field Programmable Gate Array): Dispositivo programable que permite implementar circuitos digitales personalizados mediante una arquitectura de bloques lógicos configurables, utilizados para pruebas, desarrollo y aplicaciones electrónicas avanzadas.

Sumador: Circuito digital encargado de realizar la operación aritmética de suma entre dos números binarios o decimales, produciendo como salida su resultado y, en algunos casos, un bit de acarreo.

Flip-Flop: Componente secuencial básico que puede almacenar un único valor binario (0 o 1). Se utiliza como elemento de memoria en sistemas digitales y en el control de máquinas de estado.

Debounce (Antirrebote): Técnica empleada en electrónica digital para eliminar las señales erróneas que se producen por el rebote mecánico al presionar un botón o interruptor, garantizando que solo se registre una única entrada válida por pulsación.
## 2. Descripción General del Problema:

El proyecto tuvo como objetivo principal la interconexión de distintos módulos digitales mediante máquinas de estado finitas, con el fin de lograr que cada componente pudiera operar bajo condiciones específicas o asincrónicas respecto a los demás. Esto exigió una planificación lógica anticipada y una supervisión constante del comportamiento de cada módulo dentro del sistema. A lo largo del desarrollo se alcanzaron varios logros importantes, entre ellos la creación e implementación del diseño digital para su funcionamiento en la FPGA, la elaboración de testbenches individuales para cada módulo, y la comprensión del uso de máquinas de estado sincrónicas y asincrónicas. Además, se implementó correctamente la lectura del teclado hexadecimal, permitiendo capturar los datos ingresados para utilizarlos en la operación de suma, y se diseñó un módulo de suma funcional a nivel de simulación. También se logró el despliegue correcto de los datos en el display de siete segmentos, asegurando la correspondencia entre las teclas presionadas y los valores mostrados.
Actualmente, el sistema muestra correctamente los números ingresados en los displays de siete segmentos; sin embargo, la operación de suma completa solo se ejecuta en simulación, ya que en la implementación física no se logró integrar exitosamente la lógica de suma. Por ello, existen dos versiones del módulo principal: una dedicada a comprobar el funcionamiento del display y su correspondencia con el teclado, y otra que intenta realizar la operación de suma, la cual únicamente funciona en simulación.
## 3. Descripción General del Sistema: 
<img width="1768" height="495" alt="image" src="https://github.com/user-attachments/assets/fb0c2900-af18-4b2c-887a-4f84e8529d83" />

De forma general, el circuito desarrollado tiene como función principal recibir dos números ingresados desde un teclado hexadecimal. Estos valores son almacenados internamente mediante flip-flops que operan bajo el control de una máquina de estados finita. Antes de ser procesadas, las señales provenientes del teclado atraviesan un módulo debouncer, encargado de eliminar rebotes eléctricos para asegurar que solo se registre una pulsación válida por tecla. Una vez filtrada la señal, el dato se envía al módulo de la máquina de estados encargada de la operación de suma. Dicha máquina controla la captura secuencial de las teclas presionadas, asignando la primera a las centenas, la segunda a las decenas y la tercera a las unidades de cada número. Cuando ambos números han sido introducidos, la máquina ejecuta la operación de suma y almacena el resultado mediante flip-flops internos. Finalmente, el valor obtenido se muestra en los displays de siete segmentos mediante un multiplexor que selecciona cuál dígito debe visualizarse y un decodificador que traduce cada número a su correspondiente patrón de visualización.

## 3.1 Módulo DeBounce 
Funcionamiento: El módulo DeBounce se encarga de eliminar el rebote que ocurre cuando se presiona una tecla o botón. Este rebote genera varias señales muy rápidas, lo que puede hacer que el sistema piense que se presionó la tecla más de una vez.

Para evitarlo, el módulo usa un pequeño sincronizador de dos etapas que alinea la señal del botón con el reloj del sistema y ayuda a evitar errores por metastabilidad. Luego, cuenta cuántos ciclos seguidos la señal se mantiene estable. Si la entrada se mantiene igual durante el tiempo definido (STABLE_CYCLES), el módulo actualiza su salida y, si detecta un cambio de 0 a 1, genera un pulso de un solo ciclo.
Código: 
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
Testbench:
## 3.2 Módulo disp_controller
Funcionamiento: El módulo disp_controller se encarga de manejar los cuatro displays de siete segmentos que muestran los valores del proyecto. Como la FPGA no puede activar todos los dígitos al mismo tiempo, utiliza multiplexación, encendiendo cada display de forma alternada a gran velocidad para que el ojo humano perciba que todos están encendidos simultáneamente. Toma un dato de 16 bits y, mediante un contador interno, selecciona cuál de los cuatro dígitos mostrar en cada ciclo. Ese valor se envía a un decodificador de siete segmentos, que convierte el número binario en la combinación correcta de segmentos encendidos para formar el dígito correspondiente. El módulo activa el ánodo del display correspondiente (activo bajo) y entrega la señal de segmentos adecuada, logrando que los cuatro dígitos se muestren correctamente y de manera estable.
Código: 
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
Testbench:
## 3.3 Módulo disp_dec
Funcionamiento: El módulo disp_dec se encarga de convertir un número de 4 bits en la señal correspondiente para un display de siete segmentos. Toma la entrada binaria y, mediante una estructura case, activa los segmentos correctos para formar el dígito decimal correspondiente. Cada combinación de segmentos representa un número del 0 al 9, mientras que cualquier otro valor apaga todos los segmentos. De esta manera, este módulo actúa como un decodificador que traduce valores binarios en la representación visual adecuada para los displays de siete segmentos.
Código:
`timescale 1ns/1ns

module module_disp_dec(
    input logic [3:0] w, 
    output logic [6:0] d
);
    always_comb begin
        case(w)  // Cambiar 'digit' por 'w' (la entrada real)
        4'h0: d = 7'b1111110; // ABCDEF encendidos, G apagado
        4'h1: d = 7'b0110000; // BC encendidos
        4'h2: d = 7'b1101101; // ABDEG encendidos  
        4'h3: d = 7'b1111001; // ABCD encendidos
        4'h4: d = 7'b0110011; // BCFG encendidos
        4'h5: d = 7'b1011011; // ACDFG encendidos
        4'h6: d = 7'b1011111; // ACDEFG encendidos
        4'h7: d = 7'b1110000; // ABC encendidos
        4'h8: d = 7'b1111111; // Todos encendidos
        4'h9: d = 7'b1111011; // ABCDFG encendidos
        default: d = 7'b0000000; // Todos apagados
        endcase
    end
endmodule
Testbench:
## 3.4 Módulo lecture
Funcionamiento: El módulo lecture permite la lectura confiable de un teclado hexadecimal, realizando un barrido secuencial de las columnas y registrando las filas activas. Cada tecla presionada se guarda temporalmente y solo se considera válida después de mantenerse estable durante varios ciclos, filtrando posibles rebotes. El valor validado se entrega en la salida sample, mientras que la señal de la columna activa se envía a la salida columnas, garantizando que el sistema pueda procesar correctamente los datos ingresados.
Código:
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
Testbench:
## 3.5 Módulo mux
Funcionamiento: El módulo mux se encarga de seleccionar cuál de los dígitos de un número de 16 bits será enviado a la salida de 4 bits, según la señal de control proveniente del display controller. Esta selección permite mostrar correctamente las unidades, decenas, centenas o miles en el display de 7 segmentos, asegurando que en cada ciclo solo se active el dígito correspondiente y se mantenga la sincronización con la multiplexación de los displays.
Código: 
`timescale 1ns/1ps
// Este mux es controlado por el display controller, el cual indica si se deben mostrar las unidades, decenas o centenas.



module module_mux(
    input logic [3:0] a,    // Maquina de estados one-hot
    input logic [15:0] cdu,    // cdu[3:0] = unidades, cdu[7:4] = decenas, cdu[11:8] = centenas
    output logic [3:0] w    // Numero de 4 bits (salida)
);

    always_comb begin
        case (a)
            4'b0001: w = cdu[3:0];      // unidades
            4'b0010: w = cdu[7:4];      // decenas
            4'b0100: w = cdu[11:8];     // centenas
            4'b1000: w = cdu[15:12];    // miles
            default: w = 4'b0000;
        endcase
    end

    
endmodule
Testbench:
## 3.6 Módulo suma
Funcionamiento: El módulo suma está diseñado para acumular y procesar los valores ingresados desde el teclado hexadecimal, construyendo números a partir de las teclas presionadas y realizando la operación de suma cuando se reciben las señales correspondientes. Cada dígito ingresado se multiplica por 10 y se suma al valor actual para formar números de varias cifras, mientras que las señales de operación (como suma o igual) permiten almacenar temporalmente los números y calcular el resultado final.
Código: 
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
Testbench:
## 3.7 Módulo bin_to_bcd
Funcionamiento: El módulo bin_to_bcd convierte un número binario de 12 bits en su equivalente en formato BCD de 16 bits, permitiendo representar hasta cuatro dígitos decimales. La conversión se realiza mediante un algoritmo de desplazamiento y suma (shift-and-add-3), donde se revisa cada nibble del BCD en construcción; si un nibble es mayor o igual a 5, se le suma 3 antes de desplazar los bits del número binario. Este proceso garantiza que cada grupo de 4 bits de la salida corresponda a un dígito decimal correcto, listo para ser mostrado en un display de 7 segmentos.
Código: 
`timescale 1ns/1ps

module module_bin_to_bcd (
    input  [11:0] i_bin,   // Entrada binaria de 12 bits
    output [15:0] o_bcd    // Salida BCD de 16 bits (4 dígitos)
);

    reg [11:0] bin_shift;
    reg [15:0] bcd;
    integer i;

    always @(*) begin
        bcd = 0;
        bin_shift = i_bin;
        for (i = 0; i < 12; i = i + 1) begin
            if (bcd[3:0]   >= 5) bcd[3:0]   = bcd[3:0]   + 3;
            if (bcd[7:4]   >= 5) bcd[7:4]   = bcd[7:4]   + 3;
            if (bcd[11:8]  >= 5) bcd[11:8]  = bcd[11:8]  + 3;
            if (bcd[15:12] >= 5) bcd[15:12] = bcd[15:12] + 3;
            bcd = {bcd[14:0], bin_shift[11]};
            bin_shift = bin_shift << 1;
        end
        o_bcd = bcd;
    end

endmodule
Testbench:
## 3.8 Módulo input_controller
Funcionamiento: El módulo input_controller se encarga de gestionar la captura de los números ingresados desde el teclado y controlar el flujo de la operación mediante una máquina de estados. Esta máquina tiene tres estados: STATE_A, donde se espera la entrada del primer número; STATE_B, donde se captura el segundo número; y STATE_CALCULATE, donde se habilita el cálculo de la suma. Los números se almacenan en registros internos al detectar un pulso válido de tecla, y las salidas numA y numB reflejan los valores capturados. Además, la señal calculate_en se activa únicamente en el estado de cálculo, mientras que state_leds proporciona una indicación visual del estado actual para depuración.
Código: 
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
Testbench:
## 3.9 Módulo top ("Sumador")
Funcionamiento: Este módulo es el top que intenta realizar la suma de dos números ingresados desde un teclado hexadecimal y mostrar el resultado en un display de 7 segmentos. Integra todos los módulos necesarios: lectura de teclado, conversión de teclas a códigos, módulo de suma, conversión de binario a BCD y controlador de displays.
Código: 
`timescale 1ns/1ps

module module_top(
    input  wire        clk,
    output wire [3:0]  columnas,
    input  wire [3:0]  filas_raw,
    output wire [3:0]  a,
    output wire [6:0]  d
);

    wire [3:0] key_sample;
    wire [13:0] resultado_suma;
    wire result_valid;
    wire result_pulse;
    wire overflow;
    wire [11:0] bin_para_conversor;
    wire [15:0] bcd_para_display;
    wire [6:0] segments;
    wire [3:0] anodos;

    // Reset interno
    reg rst_n;
    reg [23:0] reset_counter = 0;
    
    // Detección de pulsos de teclas
    reg [3:0] last_key_sample = 0;
    reg key_pulse = 0;
    
    always @(posedge clk) begin
        if (reset_counter < 24'hFFFFFF) begin
            reset_counter <= reset_counter + 1;
            rst_n <= 1'b0;
        end else begin
            rst_n <= 1'b1;
        end
    end

    // Detectar flanco de tecla para generar pulso
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_key_sample <= 0;
            key_pulse <= 0;
        end else begin
            // Detectar cuando cambia la tecla (flanco de subida)
            if (key_sample != 0 && key_sample != last_key_sample) begin
                key_pulse <= 1'b1;
            end else begin
                key_pulse <= 1'b0;
            end
            last_key_sample <= key_sample;
        end
    end

    // Módulo lecture (teclado)
    module_lecture u_lecture (
        .clk(clk),
        .n_reset(rst_n),
        .filas_raw(filas_raw),
        .columnas(columnas),
        .sample(key_sample)
    );

    // CONVERSOR de teclas físicas a códigos del módulo suma
    wire [3:0] key_code_para_suma;
    assign key_code_para_suma = 
        (key_sample == 4'h2) ? 4'h1 : // Tecla 1 física → Dígito 1
        (key_sample == 4'h5) ? 4'h2 : // Tecla 2 física → Dígito 2
        (key_sample == 4'h8) ? 4'h3 : // Tecla 3 física → Dígito 3
        (key_sample == 4'h3) ? 4'h4 : // Tecla 4 física → Dígito 4
        (key_sample == 4'h6) ? 4'h5 : // Tecla 5 física → Dígito 5
        (key_sample == 4'h9) ? 4'h6 : // Tecla 6 física → Dígito 6
        (key_sample == 4'h1) ? 4'h7 : // Tecla 7 física → Dígito 7
        (key_sample == 4'h4) ? 4'h8 : // Tecla 8 física → Dígito 8
        (key_sample == 4'h7) ? 4'h9 : // Tecla 9 física → Dígito 9
        (key_sample == 4'h0) ? 4'h0 : // Tecla 0 física → Dígito 0
        (key_sample == 4'hA) ? 4'd10 : // Tecla A → ADD
        (key_sample == 4'hB) ? 4'd11 : // Tecla B → EQUAL
        (key_sample == 4'hC) ? 4'd12 : // Tecla C → CLEAR
        4'd15; // Otras teclas → ignorar

    // NUEVO módulo suma funcional
    module_suma u_suma (
        .clk(clk),
        .rst_n(rst_n),
        .key_code(key_code_para_suma),
        .key_pulse(key_pulse),  // Usar detección real de pulsos
        .result(resultado_suma),
        .result_valid(result_valid),
        .result_pulse(result_pulse),
        .overflow(overflow)
    );

    // Conversión a BCD
    assign bin_para_conversor = resultado_suma[11:0];
    
    module_bin_to_bcd u_bin_to_bcd (
        .i_bin(bin_para_conversor),
        .o_bcd(bcd_para_display)
    );

    // Display controller
    module_disp_controller u_display (
        .clk(clk),
        .rst(~rst_n),
        .data(bcd_para_display),
        .seg(segments),
        .an(anodos)
    );

    // Asignar salidas
    assign a = anodos;
    assign d = segments;

endmodule
Testbench:
## 3.8 Módulo Top ("Verificador de funcionamiento de displays")
## 4. Ejercicios
## 4.1 Contadores Sincrónicos:  
## 4.2 Construcción de un cerrojo Set-Reset con compuertas NAND: 
## 5. Problemas encontrados durante la implementación:
Durante la implementación del proyecto, se identificó que era necesario encontrar un equilibrio adecuado en el DeBouncer entre rigidez y sensibilidad. Si el DeBouncer era demasiado sensible, el rebote de las teclas provocaba que al presionar una tecla se registrara otra de manera incorrecta. Por otro lado, si se configuraba con demasiada rigidez, algunas pulsaciones no se registraban, impidiendo que el valor apareciera en los displays de 7 segmentos. Como resultado, en ciertas ocasiones al presionar algunas teclas se mostraban números incorrectos en los displays. Además, se presentó un segundo problema con el módulo de suma: aunque funcionaba correctamente en simulación a través del testbench, no fue posible implementarlo de manera física en la FPGA.
## 6. Análisis de Potencia: 
## 7. Bitácoras: 
