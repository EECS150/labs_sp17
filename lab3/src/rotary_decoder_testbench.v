`timescale 1ns/100ps

`define CLK_PERIOD 10

/*
    This testbench ISN'T self checking. You will need to inspect the waveform and interpret the results of this test.
*/
module rotary_decoder_testbench();
    // Generate 100 Mhz clock
    reg clk = 0;
    always #(`CLK_PERIOD/2) clk = ~clk;

    // I/O of rotary_decoder
    reg rotary_A, rotary_B, rst;
    wire rotary_event, rotary_left;

    rotary_decoder DUT (
        .clk(clk),
        .rst(rst),
        .rotary_A(rotary_A),
        .rotary_B(rotary_B),
        .rotary_event(rotary_event),
        .rotary_left(rotary_left)
    );

    initial begin
        rotary_A = 1'b0;
        rotary_B = 1'b0;
        rst = 1'b0;
        @(posedge clk);

        // Pulse reset in case your rotary_decoder uses it
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        // Generate a right spin
        rotary_A = 1'b1;
        repeat (10) @(posedge clk);
        rotary_B = 1'b1;
        repeat (3) @(posedge clk);
        rotary_A = 1'b0;
        @(posedge clk);
        rotary_B = 1'b0;

        repeat (5) @(posedge clk);

        // Generate a left spin
        rotary_B = 1'b1;
        repeat (10) @(posedge clk);
        rotary_A = 1'b1;
        repeat (3) @(posedge clk);
        rotary_B = 1'b0;
        @(posedge clk);
        rotary_A = 1'b0;

        repeat (5) @(posedge clk);

        $finish();
    end
endmodule
