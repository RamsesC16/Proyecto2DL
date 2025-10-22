`timescale 1ns/1ps

module module_top_tb();
    reg clk;
    reg [3:0] filas_raw;
    
    wire [3:0] columnas;
    wire [3:0] a;
    wire [6:0] d;
    
    // Señales del sistema para debug
    wire [3:0] key_sample;
    wire [13:0] resultado_suma;
    wire result_valid;
    wire result_pulse;
    wire overflow;
    
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

    // CONVERSOR de teclas
    wire [3:0] key_code_para_suma;
    assign key_code_para_suma = 
        (key_sample == 4'h2) ? 4'h1 : // 1
        (key_sample == 4'h5) ? 4'h2 : // 2
        (key_sample == 4'h8) ? 4'h3 : // 3
        (key_sample == 4'h3) ? 4'h4 : // 4
        (key_sample == 4'h6) ? 4'h5 : // 5
        (key_sample == 4'h9) ? 4'h6 : // 6
        (key_sample == 4'h1) ? 4'h7 : // 7
        (key_sample == 4'h4) ? 4'h8 : // 8
        (key_sample == 4'h7) ? 4'h9 : // 9
        (key_sample == 4'h0) ? 4'h0 : // 0
        (key_sample == 4'hA) ? 4'd10 : // A
        (key_sample == 4'hB) ? 4'd11 : // B
        (key_sample == 4'hC) ? 4'd12 : // C
        4'd15;

    // Módulo suma
    module_suma u_suma (
        .clk(clk),
        .rst_n(rst_n),
        .key_code(key_code_para_suma),
        .key_pulse(key_pulse),
        .result(resultado_suma),
        .result_valid(result_valid),
        .result_pulse(result_pulse),
        .overflow(overflow)
    );

    // Display directo
    wire [15:0] display_data = {4'b0, resultado_suma[11:0]};
    module_disp_controller u_display (
        .clk(clk),
        .rst(~rst_n),
        .data(display_data),
        .seg(d),
        .an(a)
    );

    // Generador de reloj
    always #18.519 clk = ~clk;
    
    // Tarea para presionar tecla en momento específico
    task press_key_at_time;
        input integer press_time;
        input [1:0] fila;
        input [1:0] columna;  
        input string key_name;
        begin
            #press_time;
            
            // Activar fila cuando la columna correspondiente esté activa
            case (fila)
                0: filas_raw = 4'b1110;
                1: filas_raw = 4'b1101; 
                2: filas_raw = 4'b1011;
                3: filas_raw = 4'b0111;
            endcase
            
            $display("[%0t] PRESIONANDO: %s (Fila=%0d, Columna=%0d)", 
                     $time, key_name, fila, columna);
            $display("    Columnas actual: %4b", columnas);
            $display("    Filas actual: %4b", filas_raw);
            
            // Mantener presionada por varios ciclos de escaneo
            #500000; // 500us
            
            // Liberar
            filas_raw = 4'b1111;
            $display("[%0t] LIBERANDO: %s", $time, key_name);
            
            #500000; // Esperar entre teclas
        end
    endtask
    
    // Monitoreo detallado
    reg [3:0] last_columnas = 0;
    always @(posedge clk) begin
        if (columnas !== last_columnas) begin
            last_columnas <= columnas;
        end
    end
    
    // Monitorear key_sample
    reg [3:0] last_key_debug = 0;
    always @(posedge clk) begin
        if (key_sample !== last_key_debug) begin
            last_key_debug <= key_sample;
            if (key_sample !== 0) begin
                $display(">>> [%0t] TECLA DETECTADA: 0x%h", $time, key_sample);
            end
        end
    end
    
    // Monitorear key_pulse
    always @(posedge clk) begin
        if (key_pulse) begin
            $display("*** [%0t] PULSO ACTIVO: Tecla=0x%h -> Codigo=0x%h", 
                     $time, key_sample, key_code_para_suma);
        end
    end
    
    // Monitorear resultados
    always @(posedge clk) begin
        if (result_pulse) begin
            $display("=== [%0t] RESULTADO: %0d ===", $time, resultado_suma);
        end
    end
    
    initial begin
        clk = 0;
        filas_raw = 4'b1111;
        
        $display("===========================================");
        $display("=== DEBUG DETALLADO SISTEMA ===");
        $display("===========================================");
        
        // Esperar reset completo
        #2000000;
        $display("[%0t] Reset completado - Iniciando...", $time);
        
        $display("");
        $display("=== PRUEBA: Tecla 5 en columna 1 ===");
        $display("");
        
        // Esperar a que esté en columna 1 (0010) para tecla 5
        press_key_at_time(0, 1, 1, "Tecla 5");
        
        $display("");
        $display("=== PRUEBA: ADD en columna 3 ===");
        $display("");
        
        press_key_at_time(0, 0, 3, "Tecla A (ADD)");
        
        $display("");
        $display("=== PRUEBA: Tecla 3 en columna 2 ===");
        $display("");
        
        press_key_at_time(0, 0, 2, "Tecla 3");
        
        $display("");
        $display("=== PRUEBA: EQUAL en columna 3 ===");
        $display("");
        
        press_key_at_time(0, 1, 3, "Tecla B (EQUAL)");
        
        $display("");
        $display("=== ESTADO FINAL ===");
        $display("Resultado: %0d", resultado_suma);
        $display("Valido: %b", result_valid);
        $display("Overflow: %b", overflow);
        $display("Key sample: 0x%h", key_sample);
        $display("Key pulse: %b", key_pulse);
        
        $display("");
        $display("=== DEBUG COMPLETADO ===");
        
        #2000000;
        $finish;
    end

endmodule