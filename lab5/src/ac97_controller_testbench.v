`timescale 1ns/100ps

`define SECOND 1000000000
`define MS 1000000
`define SYSTEM_CLK_PERIOD 30.3
`define BIT_CLK_PERIOD 81.38

module ac97_controller_testbench();
    // System clock domain I/O
    reg system_clock = 0;
    reg system_reset = 0;
    reg square_wave = 0;
    reg [3:0] volume_control = 0;
    // Connections between AC97 codec and controller
    wire sdata_out, sync, reset_b, bit_clk;

    // Generate system clock
    always #(`SYSTEM_CLK_PERIOD/2) system_clock = ~system_clock;

    ac97_codec_model model (
        .sdata_in(),    // sdata_in isn't used in this lab
        .sdata_out(sdata_out),
        .sync(sync),
        .reset_b(reset_b),
        .bit_clk(bit_clk)
    );

    ac97_controller DUT (
        .sdata_in(),
        .bit_clk(bit_clk),
        .sdata_out(sdata_out),
        .sync(sync),
        .reset_b(reset_b),
        .system_clock(system_clock),
        .system_reset(system_reset),
        .volume_control(volume_control),
        .square_wave(square_wave)
    );

    initial begin
        // Pulse the system reset to the ac97 controller
        @(posedge system_clock);
        system_reset = 1'b1;
        @(posedge system_clock);
        system_reset = 1'b0;
        
        // Let 1 AC97 frame pass
        repeat (256) @(posedge bit_clk);

        // Send a square wave value of 1 for 2 frames
        @(posedge system_clock);
        square_wave = 1;
        repeat (256 * 2) @(posedge bit_clk);
        
        // Then send a square wave value of 0 for the next 2 frames
        @(posedge system_clock);        
        square_wave = 0;
        repeat (256 * 2) @(posedge bit_clk);

        // Let 1 more frame elapse
        repeat(256) @(posedge bit_clk);
        $finish();
    end


endmodule
