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
TEST MODULO DEBOUNCE

VCD info: dumpfile module_DeBounce_tb.vcd opened for output.
[55000] START tests
[995000] btn_pulse asserted
[1465000] btn_pulse asserted
[1985000] btn_pulse asserted
[2235000] END tests
../sim/module_DeBounce_tb.sv:79: $finish called at 2235000 (1ps)
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
TEST MODULO DISP_CONTROLLER

Segmentos: 1001111, Anodos: 1101
Segmentos: 1111101, Anodos: 1011
Test completado.
../sim/module_disp_controller_tb.sv:44: $finish called at 2020000 (1ps)
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
===========================================
=== TESTBENCH MODULE_LECTURE (TECLADO) ===
===========================================
--- [19000] Columna activa: 0001
[1100000] Reset completado
  >> Columnas: 0001 | Filas: 1111 | Sample: 0x0

=== PRUEBA 1: Teclas num├⌐ricas 1-9 ===

[1100000] Tecla presionada: codigo 0x2 (Fila=0, Columna=0)
  >> Columnas: 0001 | Filas: 1111 | Sample: 0x0
[4854811000] Tecla presionada: codigo 0x5 (Fila=0, Columna=1)
--- [4854848000] Columna activa: 0010
  >> Columnas: 0010 | Filas: 1111 | Sample: 0x0
[7282171000] Tecla presionada: codigo 0x8 (Fila=0, Columna=2)
--- [7282208000] Columna activa: 0100
  >> Columnas: 0100 | Filas: 1111 | Sample: 0x0
--- [9709567000] Columna activa: 1000
[12136890000] Tecla presionada: codigo 0x3 (Fila=1, Columna=0)
--- [12136927000] Columna activa: 0001
  >> Columnas: 0001 | Filas: 1111 | Sample: 0x0
[14564249000] Tecla presionada: codigo 0x6 (Fila=1, Columna=1)
--- [14564286000] Columna activa: 0010
  >> Columnas: 0010 | Filas: 1111 | Sample: 0x0
[16991608000] Tecla presionada: codigo 0x9 (Fila=1, Columna=2)
--- [16991645000] Columna activa: 0100
  >> Columnas: 0100 | Filas: 1111 | Sample: 0x0
--- [19419005000] Columna activa: 1000
[21846327000] Tecla presionada: codigo 0x1 (Fila=2, Columna=0)
--- [21846364000] Columna activa: 0001
  >> Columnas: 0001 | Filas: 1111 | Sample: 0x0
[24273687000] Tecla presionada: codigo 0x4 (Fila=2, Columna=1)
--- [24273724000] Columna activa: 0010
  >> Columnas: 0010 | Filas: 1111 | Sample: 0x0
[26701046000] Tecla presionada: codigo 0x7 (Fila=2, Columna=2)
--- [26701083000] Columna activa: 0100
  >> Columnas: 0100 | Filas: 1111 | Sample: 0x0

=== PRUEBA 2: Tecla 0 y letras ===

--- [29128443000] Columna activa: 1000
--- [31555802000] Columna activa: 0001
[33983124000] Tecla presionada: codigo 0x0 (Fila=3, Columna=1)
--- [33983161000] Columna activa: 0010
  >> Columnas: 0010 | Filas: 1111 | Sample: 0x0
--- [36410521000] Columna activa: 0100
[38837843000] Tecla presionada: codigo 0xA (Fila=0, Columna=3)
--- [38837880000] Columna activa: 1000
  >> Columnas: 1000 | Filas: 1111 | Sample: 0x0
[38858843000] Tecla presionada: codigo 0xF (Fila=1, Columna=3)
  >> Columnas: 1000 | Filas: 1111 | Sample: 0x0
[38879843000] Tecla presionada: codigo 0xE (Fila=2, Columna=3)
  >> Columnas: 1000 | Filas: 1111 | Sample: 0x0
[38900843000] Tecla presionada: codigo 0xD (Fila=3, Columna=3)
  >> Columnas: 1000 | Filas: 1111 | Sample: 0x0
[41265202000] Tecla presionada: codigo 0xA (Fila=3, Columna=0)
--- [41265240000] Columna activa: 0001
  >> Columnas: 0001 | Filas: 1111 | Sample: 0x0
--- [43692599000] Columna activa: 0010
[46119921000] Tecla presionada: codigo 0xB (Fila=3, Columna=2)
--- [46119958000] Columna activa: 0100
  >> Columnas: 0100 | Filas: 1111 | Sample: 0x0

=== PRUEBA 3: Debounce y teclas rapidas ===

Presionando teclas rapidamente...
--- [48547318000] Columna activa: 1000
[50974640000] Tecla presionada:   1 rapida (Fila=0, Columna=0)
--- [50974677000] Columna activa: 0001
[53402000000] Tecla presionada:   2 rapida (Fila=0, Columna=1)
--- [53402037000] Columna activa: 0010
--- [55829396000] Columna activa: 0100
--- [58256755000] Columna activa: 1000
[60684078000] Tecla presionada: a otra vez (Fila=0, Columna=0)
--- [60684115000] Columna activa: 0001

=== PRUEBA 4: Tecla larga ===

Tecla larga (5):
--- [63111474000] Columna activa: 0010
>>> [63149401000] TECLA DETECTADA: 0x6
  >> Columnas: 0010 | Filas: 1101 | Sample: 0x6
  >> Columnas: 0010 | Filas: 1101 | Sample: 0x6

=== RESUMEN DE MAPEO ===

Tecla Fisica -> Codigo Salida
 1 -> 0x2
 2 -> 0x5
 3 -> 0x8
 4 -> 0x3
 5 -> 0x6
 6 -> 0x9
 7 -> 0x1
 8 -> 0x4
 9 -> 0x7
 0 -> 0x0
 A -> 0xA
 B -> 0xF
 C -> 0xE
 D -> 0xD
 * -> 0xA
 # -> 0xB

=== TEST COMPLETADO ===
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
=== PRUEBA NUEVO MODULE_SUMA ===
1. 15 + 27 = 42
>>> RESULTADO CALCULADO:     0
>>> RESULTADO CALCULADO:    42
   Resultado:    42 (esperado: 42)

2. CLEAR y 8 + 5 = 13
>>> RESULTADO CALCULADO:     0
>>> RESULTADO CALCULADO:    13
   Resultado:    13 (esperado: 13)
../sim/module_suma_tb.sv:71: $finish called at 635000 (1ps)
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
Testbench: ===========================================
=== DEBUG DETALLADO SISTEMA ===
===========================================
[2000000000] Reset completado - Iniciando...

=== PRUEBA: Tecla 5 en columna 1 ===

[2000000000] PRESIONANDO: Tecla 5 (Fila=1, Columna=1)
    Columnas actual: 0001
    Filas actual: 1101
[2500000000] LIBERANDO: Tecla 5

=== PRUEBA: ADD en columna 3 ===

[3000000000] PRESIONANDO: Tecla A (ADD) (Fila=0, Columna=3)
    Columnas actual: 0001
    Filas actual: 1110
[3500000000] LIBERANDO: Tecla A (ADD)

=== PRUEBA: Tecla 3 en columna 2 ===

[4000000000] PRESIONANDO: Tecla 3 (Fila=0, Columna=2)
    Columnas actual: 0001
    Filas actual: 1110
[4500000000] LIBERANDO: Tecla 3

=== PRUEBA: EQUAL en columna 3 ===

[5000000000] PRESIONANDO: Tecla B (EQUAL) (Fila=1, Columna=3)
    Columnas actual: 0001
    Filas actual: 1101
[5500000000] LIBERANDO: Tecla B (EQUAL)

=== ESTADO FINAL ===
Resultado: 0
Valido: 0
Overflow: 0
Key sample: 0x0
Key pulse: 0

=== DEBUG COMPLETADO ===
../sim/module_top_tb.sv:218: $finish called at 8000000000 (1ps)
## 3.8 Módulo Top ("Verificador de funcionamiento de displays")
Descripción: Este módulo top tiene como finalidad comprobar el correcto funcionamiento tanto del teclado matricial como de los displays de 7 segmentos, mostrando en pantalla el número correspondiente a la tecla presionada. Para ello, el módulo module_lecture se encarga de escanear el teclado 4x4 activando sus columnas y detectando qué fila está siendo presionada, generando un valor binario de 4 bits (key_sample) que identifica la tecla. Dicho valor se amplía a 16 bits mediante la variable display_val, añadiendo ceros en las posiciones más significativas para que el controlador del display pueda manejarlo correctamente. Posteriormente, el módulo module_disp_controller recibe esta información y la muestra en los displays de 7 segmentos, gestionando la multiplexación de los ánodos y segmentos para que visualmente parezca que todos los dígitos están encendidos simultáneamente.
Código: `timescale 1ns/1ps

module module_top(
    input  wire        clk,
    output wire [3:0]  columnas,
    input  wire [3:0]  filas_raw,
    output wire [3:0]  a,
    output wire [6:0]  d
);

    wire [3:0] key_sample;
    
    module_lecture u_lecture (
        .clk(clk),
        .n_reset(1'b1),
        .filas_raw(filas_raw),
        .columnas(columnas),
        .sample(key_sample)
    );

    // Solo mostrar el código de tecla
    reg [15:0] display_val;
    
    always @(*) begin
        display_val = {12'h000, key_sample};
    end

    module_disp_controller u_display (
        .clk(clk),.
        .rst(1'b0),
        .data(display_val),
        .seg(d),
        .an(a)
    );

endmodule
## 4. Ejercicios
## 4.1 Contadores Sincrónicos:  
En esta práctica se implementaron dos contadores sincrónicos de 4 bits 74LS163 (o su equivalente 74HC163) conectados en cascada, alimentados por una señal de reloj (CLK) generada desde la FPGA a la frecuencia especificada en la guía. El propósito fue verificar la operación sincrónica del conteo y el funcionamiento de la salida de acarreo RCO, la cual indica que el contador alcanzó su valor terminal y habilita el conteo en el siguiente dispositivo al estar conectada a la entrada T del contador superior. Esta conexión asegura que el segundo contador incremente únicamente cuando el primero completa su ciclo, permitiendo un conteo conjunto de 8 bits sin interferencias. Se analizó la diferencia entre las entradas T y P (también denominadas ENT y ENP en la hoja de datos), determinándose que ambas deben estar activas para permitir el conteo, aunque ENT se encarga de la propagación del acarreo y ENP de la habilitación general. Tras cada flanco positivo del reloj, las salidas cambian de estado después de un breve retardo de propagación, sin que importe específicamente qué bit se use para el disparo del osciloscopio, aunque conviene seleccionar el MSB para observar la cascada. Se inspeccionó la salida RCO del contador menos significativo con el osciloscopio en modo analizador lógico y analógico para detectar posibles fallas breves o “glitches”, los cuales pueden presentarse cuando varias salidas cambian simultáneamente, especialmente en el conteo terminal o a altas frecuencias. El montaje demostró el funcionamiento esperado del conteo sincrónico y la correcta propagación del acarreo entre etapas, evidenciando la estabilidad y precisión del sistema. La tabla de verdad, el procedimiento detallado se encuentran registrados en la bitácora del laboratorio.
<img width="969" height="616" alt="image" src="https://github.com/user-attachments/assets/9a65c0db-c47a-486b-95b9-2bdacdfa888c" />
<img width="967" height="612" alt="image" src="https://github.com/user-attachments/assets/e4ee6759-303d-48ca-b206-6d7f89c486a3" />

## 4.2 Construcción de un cerrojo Set-Reset con compuertas NAND: 
Se construyó un cerrojo SR sincronizado mediante el uso de compuertas NAND 74HC00, de acuerdo con el esquema propuesto en la guía, empleando una señal de reloj generada por la FPGA a la frecuencia indicada. El circuito fue diseñado para que los cambios en las salidas ocurran únicamente cuando el reloj se encuentra en nivel alto, cumpliendo con el principio de sincronización temporal. Durante la operación se comprobó que, en la condición de “set”, la salida Q adopta el nivel alto y su complemento Q̅ el nivel bajo, mientras que en “reset” ocurre el comportamiento opuesto; cuando ambas entradas S y R permanecen en alto, el cerrojo conserva su estado previo, funcionando como elemento de memoria. El comportamiento fue verificado mediante mediciones en el osciloscopio y el analizador lógico, evidenciando que las transiciones se producen exclusivamente durante el intervalo activo del reloj, y que la retención se mantiene estable fuera de dicho intervalo. Este tipo de cerrojo es útil en aplicaciones donde se requiere almacenar información temporal de manera controlada por una señal de sincronización, como en sistemas secuenciales, registros y máquinas de estado. El circuito final, la tabla de verdad utilizada y el procedimiento experimental se encuentran documentados en la bitácora correspondiente.
<img width="1011" height="637" alt="image" src="https://github.com/user-attachments/assets/21178651-c1e1-453d-88d1-1f8903802bd6" />
<img width="1007" height="631" alt="image" src="https://github.com/user-attachments/assets/a6d44b27-7bcf-4105-8f20-6946351e28dc" />
<img width="1017" height="635" alt="image" src="https://github.com/user-attachments/assets/aaa3e6dc-d6d2-499e-bda3-c4027fc264f8" />
<img width="1017" height="639" alt="image" src="https://github.com/user-attachments/assets/962fdd08-f256-4715-93bf-bf3a9f660dd4" />

## 5. Problemas encontrados durante la implementación:
Durante la implementación del proyecto, se identificó que era necesario encontrar un equilibrio adecuado en el DeBouncer entre rigidez y sensibilidad. Si el DeBouncer era demasiado sensible, el rebote de las teclas provocaba que al presionar una tecla se registrara otra de manera incorrecta. Por otro lado, si se configuraba con demasiada rigidez, algunas pulsaciones no se registraban, impidiendo que el valor apareciera en los displays de 7 segmentos. Como resultado, en ciertas ocasiones al presionar algunas teclas se mostraban números incorrectos en los displays. Además, se presentó un segundo problema con el módulo de suma: aunque funcionaba correctamente en simulación a través del testbench, no fue posible implementarlo de manera física en la FPGA.
## 6. Análisis de Potencia: 
=== module_top ===

   Number of wires:               1284
   Number of wire bits:           2739
   Number of public wires:        1284
   Number of public wire bits:    2739
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:               1674
     ALU                           300
     DFF                             1
     DFFC                           22
     DFFCE                          60
     DFFE                           24
     DFFPE                           1
     DFFR                           32
     DFFRE                           2
     GND                             1
     IBUF                            5
     LUT1                          462
     LUT2                          149
     LUT3                           52
     LUT4                          144
     MUX2_LUT5                     247
     MUX2_LUT6                     109
     MUX2_LUT7                      37
     MUX2_LUT8                      10
     OBUF                           15
     VCC                             1
## 7. Bitácoras: 
