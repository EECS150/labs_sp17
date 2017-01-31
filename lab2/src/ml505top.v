//-----------------------------------------------------------------------------
// UC Berkeley EECS 151/251A FPGA Lab
// Lab 1, Fall 2016
// Module: ml505top.v
// Desc: Talks to the world outside your design.
//-----------------------------------------------------------------------------

module ml505top (
    input  CLK_33MHZ_FPGA,
    input  [7:0] GPIO_DIP,
    output PIEZO_SPEAKER,
    output [7:0] GPIO_LED
);    

    tone_generator piezo_controller (
        .clk(CLK_33MHZ_FPGA),
        .output_enable(GPIO_DIP[0]),
        .tone_switch_period({17'd0, GPIO_DIP[7:1]} << 9),
        .square_wave_out(PIEZO_SPEAKER)
    );

    assign GPIO_LED[7:0] = 8'd0;
endmodule
