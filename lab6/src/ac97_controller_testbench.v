`timescale 1ns/100ps

`define SECOND 1000000000
`define MS 1000000
`define SYSTEM_CLK_PERIOD 30.3
`define BIT_CLK_PERIOD 81.38

module ac97_controller_testbench();
    // System clock domain I/O
    reg system_clock = 0;
    reg system_reset = 0;

    reg [3:0] volume_control = 0;
    wire square_wave;

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

    // Add your Async FIFO here and connect it to the DUT

    initial begin
        // Pulse the system reset to the ac97 controller
        @(posedge system_clock);
        system_reset = 1'b1;
        @(posedge system_clock);
        system_reset = 1'b0;

        // Push a few packets of data into the AC97 FIFO


        // Let 10 AC97 frames pass
        repeat (256 * 10) @(posedge bit_clk);

        
        // Let 1 AC97 frame pass
        repeat (256) @(posedge bit_clk);

        $finish();
    end


endmodule
