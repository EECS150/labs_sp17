`timescale 1ns/1ns

`define SECOND 1000000000
`define MS 1000000
`define SAMPLE_PERIOD 22675.7

module music_streamer_testbench();
    // Global signals
    reg clock;
    reg reset;

    // Music streamer inputs
    reg rotary_event;
    reg rotary_left;
    reg rotary_push;
    reg button_center;
    reg button_north;
    reg button_east;
    reg button_west;
    reg button_south;

    // Music streamer outputs
    wire [23:0] tone_to_play;
    wire led_center;
    wire led_north;
    wire led_east;
    wire led_west;
    wire led_south;
    wire [7:0] GPIO_leds;

    // Tone generator input
    reg output_enable;

    // Tone generator output
    wire sq_wave;

    initial clock = 0;
    always #(30.3/2) clock <= ~clock;

    tone_generator piezo_controller (
        .clk(clock),
        .rst(reset),
        .output_enable(output_enable),
        .tone_switch_period(tone_to_play),
        .square_wave_out(sq_wave)
    );

    music_streamer streamer (
        .clk(clock),
        .rst(reset),
        .rotary_event(rotary_event),
        .rotary_left(rotary_left),
        .rotary_push(rotary_push),
        .button_center(button_center),
        .button_north(button_north),
        .button_east(button_east),
        .button_west(button_west),
        .button_south(button_south),
        .led_center(led_center),
        .led_north(led_north),
        .led_east(led_east),
        .led_west(led_west),
        .led_south(led_south),
        .tone(tone_to_play),
        .GPIO_leds(GPIO_leds)
    );

    initial begin
        reset = 0;
        // Reset our modules and enable the tone_generator output
        @(posedge clock);
        reset = 1;
        @(posedge clock);
        reset = 0;
        output_enable = 1;

        // Warning: do not exceed delays of 2 seconds at a time
        // otherwise the delay won't work properly with our simulator
        #(2 * `SECOND);

        // Get FSM into PAUSED state by simulating center button press
        @(posedge clock);
        button_center = 1'b1;
        @(posedge clock);
        button_center = 1'b0;
        #(300 * `MS);

        // Get FSM into REGULAR_PLAY, then REVERSE_PLAY state (press center, then south button)
        @(posedge clock);
        button_center = 1'b1;
        @(posedge clock);
        button_center = 1'b0;
        @(posedge clock);
        button_south = 1'b1;
        @(posedge clock);
        button_south = 1'b0;
        #(300 * `MS);

        // Simulate tempo adjustment by clicking wheel left 10 times
        repeat (10) begin
            @(posedge clock);
            rotary_event = 1'b1;
            rotary_left = 1'b1;
        end
        rotary_event = 1'b0;
        
        // Move to the REGULAR_PLAY state with tempo adjusted and see how music sounds
        @(posedge clock);
        button_south = 1'b1;
        @(posedge clock);
        button_south = 1'b0;
        #(1 * `SECOND);

        $finish();
    end

    integer file;
    initial begin
        file = $fopen("output.txt", "w");
        forever begin
            $fwrite(file, "%h\n", sq_wave);
            #(`SAMPLE_PERIOD);
        end
    end

endmodule
