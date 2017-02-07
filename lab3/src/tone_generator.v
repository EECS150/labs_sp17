module tone_generator (
    input output_enable,
    input [23:0] tone_switch_period, 
    input clk,
    input rst,
    output square_wave_out
);
    // Remove this line after copying your tone_generator implementation from lab 2
    assign square_wave_out = 1'b0;
endmodule
