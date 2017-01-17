//-----------------------------------------------------------------------------
// UC Berkeley EECS 151/251A FPGA Lab
// Lab 0, Spring 2017
// Module: ml505top.v
// Desc: Talks to the world outside your design.
//-----------------------------------------------------------------------------

module ml505top (
	input  [4:0] GPIO_COMPSW,
	input  CLK_33MHZ_FPGA,
    input  [7:0] GPIO_DIP,
    output [7:0] GPIO_LED
);

    // AND gate example (LED 0 is driven by (GPIO 1) AND (GPIO 2)):
    and (GPIO_LED[0], GPIO_DIP[0], GPIO_DIP[1]);
    
    assign GPIO_LED[7:1] = 0;

endmodule
