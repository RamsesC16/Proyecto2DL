`timescale 1 ns / 1 ns

module DeBounce_tf();
    reg clk;
    reg n_reset;
    reg button_in;

    wire DB_out;


    DeBounce UUT (
        .clk(clk), 
        .n_reset(n_reset), 
        .button_in(button_in), 
        .DB_out(DB_out)
        );


    initial begin
			$display ($time, " << Starting the Simulation >> ");
            clk = 1'b0;
            n_reset = 1'b0;
			#200 n_reset = 1'b1;     
            button_in = 1'b0;
    end


	always 
			#10 clk = ~clk;   

	always 
		begin
			#40000 button_in = 1'b1;
			
			#400 button_in = 1'b0;		
			
			#800 button_in = 1'b1;	
			
			#800 button_in = 1'b0;				
			
			#800 button_in = 1'b1;

			#40000 button_in = 1'b0;
			
			#4000 button_in = 1'b1;		
			
			#40000 button_in = 1'b0;

			#400 button_in = 1'b1;
			
			#800 button_in = 1'b0;		
			
			#800 button_in = 1'b1;

			#800 button_in = 1'b0;
			
			#40000 button_in = 1'b1;		
			
			#4000 button_in = 1'b0;

		end


    initial begin
        $dumpfile("DeBounce_tf.vcd"); 
        $dumpvars(0, DeBounce_tf); 
    end



endmodule 