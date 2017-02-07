// These are the compass button mappings in the 5-bit signal
`define B_CENTER 0
`define B_EAST 1
`define B_NORTH 2
`define B_SOUTH 3
`define B_WEST 4

`define CLOCK_FREQ 33_000_000

module ml505top (
    input CLK_33MHZ_FPGA,       // 33 Mhz Clock Signal Input
    input [7:0] GPIO_DIP,       // 8 GPIO DIP Switches
    input FPGA_ROTARY_INCA,     // Rotary Encoder Wheel A Signal
    input FPGA_ROTARY_INCB,     // Rotary Encoder Wheel B Signal
    input FPGA_ROTARY_PUSH,     // Rotary Encoder Push Button Signal (Active-high)
    input [4:0] GPIO_BUTTONS,    // Compass User Pushbuttons (Active-high)
    input FPGA_CPU_RESET_B,     // CPU_RESET Pushbutton (Active-LOW), signal should be interpreted as logic high when 0

    output PIEZO_SPEAKER,       // Piezo Speaker Output Line (buffered off-FPGA, drives piezo)
    output [7:0] GPIO_LED,      // 8 GPIO LEDs
    output GPIO_LED_C,          // Compass Center LED
    output GPIO_LED_N,          // Compass North LED
    output GPIO_LED_E,          // Compass East LED
    output GPIO_LED_W,          // Compass West LED
    output GPIO_LED_S           // Compass South LED
);

    // Here are some time constants used for the button and rotary encoder debouncer
    localparam integer B_SAMPLE_COUNT_MAX = 0.00076 * `CLOCK_FREQ;
    localparam integer B_PULSE_COUNT_MAX = 0.11364/0.00076;
    localparam integer R_SAMPLE_COUNT_MAX = 0.000303 * `CLOCK_FREQ;
    localparam integer R_PULSE_COUNT_MAX = 0.003636/0.00030;

    // The compass_buttons are a 5-bit signal with bit 0 = center button
    wire [4:0] compass_buttons;
    wire rotary_push, reset;

    // The button_parser is a wrapper for the synchronizer -> debouncer -> edge detector signal chain
    button_parser #(
        .width(7),
        .sample_count_max(B_SAMPLE_COUNT_MAX),
        .pulse_count_max(B_PULSE_COUNT_MAX)
    ) b_parser (
        .clk(CLK_33MHZ_FPGA),
        .in({FPGA_ROTARY_PUSH, GPIO_BUTTONS, ~FPGA_CPU_RESET_B}),
        .out({rotary_push, compass_buttons, reset})
    );

    // Synchronized versions of the input buttons and rotary encoder wheel signals
    wire rotary_inca_sync, rotary_incb_sync;
    synchronizer #(
        .width(2)
    ) input_synchronizer (
        .clk(CLK_33MHZ_FPGA),
        .async_signal({FPGA_ROTARY_INCA, FPGA_ROTARY_INCB}),
        .sync_signal({rotary_inca_sync,rotary_incb_sync})
    );

    // Debounced versions of the A and B signals (already synchronized)
    wire rotary_inca_deb, rotary_incb_deb;
    debouncer #(
        .width(2),
        .sample_count_max(R_SAMPLE_COUNT_MAX), 
        .pulse_count_max(R_PULSE_COUNT_MAX)
    ) rotary_debouncer (
        .clk(CLK_33MHZ_FPGA),
        .glitchy_signal({rotary_inca_sync,rotary_incb_sync}),
        .debounced_signal({rotary_inca_deb,rotary_incb_deb})
    );

    // Signals from your rotary decoder
    wire rotary_event, rotary_left;
    rotary_decoder wheel_decoder (
        .clk(CLK_33MHZ_FPGA),
        .rst(reset),
        .rotary_A(rotary_inca_deb),
        .rotary_B(rotary_incb_deb),
        .rotary_event(rotary_event),
        .rotary_left(rotary_left)
    );


    // Connection between music_streamer and tone_generator
    wire [23:0] tone_to_play;

    tone_generator piezo_controller (
        .clk(CLK_33MHZ_FPGA),
        .rst(reset),
        .output_enable(GPIO_DIP[0]),
        .tone_switch_period(tone_to_play),
        .square_wave_out(PIEZO_SPEAKER)
    );

    music_streamer streamer (
        .clk(CLK_33MHZ_FPGA),
        .rst(reset),
        .rotary_event(rotary_event),
        .rotary_left(rotary_left),
        .rotary_push(rotary_push),
        .button_center(compass_buttons[`B_CENTER]),
        .button_north(compass_buttons[`B_NORTH]),
        .button_east(compass_buttons[`B_EAST]),
        .button_west(compass_buttons[`B_WEST]),
        .button_south(compass_buttons[`B_SOUTH]),
        .led_center(GPIO_LED_C),
        .led_north(GPIO_LED_N),
        .led_east(GPIO_LED_E),
        .led_west(GPIO_LED_W),
        .led_south(GPIO_LED_S),
        .tone(tone_to_play),
        .GPIO_leds(GPIO_LED)
    );
endmodule
