//-----------------------------------------------------------------------------
// UC Berkeley EECS 151/251A FPGA Lab
// Lab 1, Spring 2017
// Module: ml505top.v
// Desc: Talks to the world outside your design.
//-----------------------------------------------------------------------------

module ml505top (
    input  CLK_33MHZ_FPGA,
    input  [7:0] GPIO_DIP,
    output [7:0] GPIO_LED,
    output GPIO_LED_C,
    output GPIO_LED_N,
    output GPIO_LED_E,
    output GPIO_LED_W,
    output GPIO_LED_S
);

    structural_adder user_adder (
        .a({4'b0,GPIO_DIP[3:0]}),
        .b({4'b0,GPIO_DIP[7:4]}),
        .sum(GPIO_LED[7:0])
    );

    // Self test of the structural adder

    wire [7:0] adder_operand1, adder_operand2;
    wire [8:0] structural_out, behavioral_out;
    wire test_fail;
    assign GPIO_LED_C = ~test_fail;
    assign GPIO_LED_N = ~test_fail;
    assign GPIO_LED_E = ~test_fail;
    assign GPIO_LED_W = ~test_fail;
    assign GPIO_LED_S = ~test_fail;

    structural_adder structural_test_adder (
        .a(adder_operand1),
        .b(adder_operand2),
        .sum(structural_out)
    );

    behavioral_adder behavioral_test_adder (
        .a(adder_operand1),
        .b(adder_operand2),
        .sum(behavioral_out)
    );

    adder_tester tester (
        .adder_operand1(adder_operand1),
        .adder_operand2(adder_operand2),
        .structural_sum(structural_out),
        .behavioral_sum(behavioral_out),
        .clk(CLK_33MHZ_FPGA),
        .test_fail(test_fail)
    );
    
endmodule
