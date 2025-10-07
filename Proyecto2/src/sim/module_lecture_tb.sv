`timescale 1ns / 1 ns

module module_lecture_tb;

    // Entradas
    reg clk;
    reg n_reset;
    reg [3:0] filas_raw;

    // Salida
    wire [3:0] sample;

    // Instancia del módulo bajo prueba
    module_lecture uut (
        .clk(clk),
        .n_reset(n_reset),
        .filas_raw(filas_raw),
        .sample(sample)
    );
 
    // Clock: 20ns período (50MHz)
    always #18.5 clk = ~clk;

    initial begin
        $dumpfile("module_lecture_tb.vcd");
        $dumpvars(0, module_lecture_tb);

        // Inicialización
        clk = 0;
        n_reset = 0;
        filas_raw = 4'b0000;

        // Esperamos para reset
        #100;
        n_reset = 1;

        // Esperamos a que columnas empiece (ciclo ~8ms)
        #1_000_000;

        // Simular pulsación: columna 0 activa y fila 0 en 1 → sample = 0001
        // Nota: esto depende de cómo las columnas cambian en columnas_fsm
        // Esperamos que columnas = 4'b1000 en este momento
        filas_raw = 4'b1000;
        #1_000_000; // botón pulsado
        filas_raw = 4'b0000;

        // Esperamos a próxima columna
        #1_000_000;

        // Pulsar fila 1 cuando columnas = 0100
        filas_raw = 4'b0100;
        #1_000_000; // botón pulsado
        filas_raw = 4'b0000;

        // Esperamos a próxima columna
        #1_000_000;

        // Pulsar fila 1 cuando columnas = 0100
        filas_raw = 4'b0010;
        #1_000_000; // botón pulsado
        filas_raw = 4'b0000;

        // Esperamos a próxima columna
        #1_000_000;

        // Pulsar fila 1 cuando columnas = 0100
        filas_raw = 4'b1000;
        #1_000_000; // botón pulsado
        filas_raw = 4'b0000;

        #1_000_000;
        $finish;
    end

endmodule