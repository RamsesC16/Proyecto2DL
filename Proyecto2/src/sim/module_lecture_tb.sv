`timescale 1ns/1ps

module module_lecture_tb();
    reg clk;
    reg n_reset;
    reg [3:0] filas_raw;
    
    wire [3:0] columnas;
    wire [3:0] sample;
    
    // Instanciar el módulo lecture
    module_lecture u_lecture (
        .clk(clk),
        .n_reset(n_reset),
        .filas_raw(filas_raw),
        .columnas(columnas),
        .sample(sample)
    );
    
    // Generador de reloj (27 MHz como en Tang Nano 9k)
    always #18.519 clk = ~clk;  // 27 MHz period ~37ns
    
    // Tarea para simular tecla presionada
    task press_key;
        input [1:0] fila;    // 0-3
        input [1:0] columna; // 0-3  
        input [79:0] key_name; // Nombre de la tecla
        begin
            // Esperar a que la columna correcta esté activa
            wait(columnas == (4'b0001 << columna));
            
            // Activar la fila correspondiente (active low)
            case (fila)
                2'd0: filas_raw = 4'b1110;
                2'd1: filas_raw = 4'b1101;
                2'd2: filas_raw = 4'b1011;
                2'd3: filas_raw = 4'b0111;
            endcase
            
            $display("[%0t] Tecla presionada: %s (Fila=%0d, Columna=%0d)", 
                     $time, key_name, fila, columna);
            #1000; // Mantener presionada por 1us
            
            // Liberar tecla
            filas_raw = 4'b1111;
            #20000; // Esperar entre teclas
        end
    endtask
    
    // Tarea para mostrar estado actual
    task show_state;
        begin
            $display("  >> Columnas: %4b | Filas: %4b | Sample: 0x%h",
                     columnas, filas_raw, sample);
        end
    endtask
    
    // Monitoreo continuo del escaneo
    reg [3:0] last_columnas = 0;
    always @(posedge clk) begin
        if (columnas !== last_columnas) begin
            $display("--- [%0t] Columna activa: %4b", $time, columnas);
            last_columnas <= columnas;
        end
    end
    
    initial begin
        // Inicializar
        clk = 0;
        n_reset = 0;
        filas_raw = 4'b1111; // Ninguna tecla presionada
        
        $display("===========================================");
        $display("=== TESTBENCH MODULE_LECTURE (TECLADO) ===");
        $display("===========================================");
        
        // Reset
        #100;
        n_reset = 1;
        #1000;
        $display("[%0t] Reset completado", $time);
        show_state();
        
        $display("");
        $display("=== PRUEBA 1: Teclas numéricas 1-9 ===");
        $display("");
        
        // Probar teclas numéricas según el mapeo
        press_key(2'd0, 2'd0, "1 fisica -> codigo 0x2"); // Fila0, Col0 -> Tecla 1
        show_state();
        
        press_key(2'd0, 2'd1, "2 fisica -> codigo 0x5"); // Fila0, Col1 -> Tecla 2
        show_state();
        
        press_key(2'd0, 2'd2, "3 fisica -> codigo 0x8"); // Fila0, Col2 -> Tecla 3
        show_state();
        
        press_key(2'd1, 2'd0, "4 fisica -> codigo 0x3"); // Fila1, Col0 -> Tecla 4
        show_state();
        
        press_key(2'd1, 2'd1, "5 fisica -> codigo 0x6"); // Fila1, Col1 -> Tecla 5
        show_state();
        
        press_key(2'd1, 2'd2, "6 fisica -> codigo 0x9"); // Fila1, Col2 -> Tecla 6
        show_state();
        
        press_key(2'd2, 2'd0, "7 fisica -> codigo 0x1"); // Fila2, Col0 -> Tecla 7
        show_state();
        
        press_key(2'd2, 2'd1, "8 fisica -> codigo 0x4"); // Fila2, Col1 -> Tecla 8
        show_state();
        
        press_key(2'd2, 2'd2, "9 fisica -> codigo 0x7"); // Fila2, Col2 -> Tecla 9
        show_state();
        
        $display("");
        $display("=== PRUEBA 2: Tecla 0 y letras ===");
        $display("");
        
        press_key(2'd3, 2'd1, "0 fisica -> codigo 0x0"); // Fila3, Col1 -> Tecla 0
        show_state();
        
        press_key(2'd0, 2'd3, "A fisica -> codigo 0xA"); // Fila0, Col3 -> Tecla A
        show_state();
        
        press_key(2'd1, 2'd3, "B fisica -> codigo 0xF"); // Fila1, Col3 -> Tecla B
        show_state();
        
        press_key(2'd2, 2'd3, "C fisica -> codigo 0xE"); // Fila2, Col3 -> Tecla C
        show_state();
        
        press_key(2'd3, 2'd3, "D fisica -> codigo 0xD"); // Fila3, Col3 -> Tecla D
        show_state();
        
        press_key(2'd3, 2'd0, "* fisica -> codigo 0xA"); // Fila3, Col0 -> Tecla *
        show_state();
        
        press_key(2'd3, 2'd2, "# fisica -> codigo 0xB"); // Fila3, Col2 -> Tecla #
        show_state();
        
        $display("");
        $display("=== PRUEBA 3: Debounce y teclas rapidas ===");
        $display("");
        
        // Probar debounce con teclas rápidas
        $display("Presionando teclas rapidamente...");
        press_key(2'd0, 2'd0, "1 rapida");
        press_key(2'd0, 2'd1, "2 rapida");
        press_key(2'd0, 2'd0, "1 rapida otra vez");
        
        $display("");
        $display("=== PRUEBA 4: Tecla larga ===");
        $display("");
        
        // Probar una tecla larga
        $display("Tecla larga (5):");
        wait(columnas == 4'b0010); // Esperar columna 1
        filas_raw = 4'b1101; // Fila 0, Col 1 -> Tecla 5
        #50000; // 50us presionada
        show_state();
        #50000; // Otros 50us
        show_state();
        filas_raw = 4'b1111; // Liberar
        
        $display("");
        $display("=== RESUMEN DE MAPEO ===");
        $display("");
        
        $display("Tecla Fisica -> Codigo Salida");
        $display(" 1 -> 0x2");
        $display(" 2 -> 0x5"); 
        $display(" 3 -> 0x8");
        $display(" 4 -> 0x3");
        $display(" 5 -> 0x6");
        $display(" 6 -> 0x9");
        $display(" 7 -> 0x1");
        $display(" 8 -> 0x4");
        $display(" 9 -> 0x7");
        $display(" 0 -> 0x0");
        $display(" A -> 0xA");
        $display(" B -> 0xF");
        $display(" C -> 0xE");
        $display(" D -> 0xD");
        $display(" * -> 0xA");
        $display(" # -> 0xB");
        
        $display("");
        $display("=== TEST COMPLETADO ===");
        $display("");
        
        #100000;
        $finish;
    end
    
    // Monitorear cambios en sample
    reg [3:0] last_sample = 0;
    always @(posedge clk) begin
        if (sample !== last_sample && sample !== 0) begin
            $display(">>> [%0t] TECLA DETECTADA: 0x%h", $time, sample);
            last_sample <= sample;
        end
    end

endmodule