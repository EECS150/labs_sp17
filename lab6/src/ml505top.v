`timescale 1ns/100ps
// These are the compass button mappings in the 5-bit signal
`define B_CENTER 0
`define B_EAST 1
`define B_NORTH 2
`define B_SOUTH 3
`define B_WEST 4

module ml505top #(
    // We are using a 33 Mhz clock for our design
    // It is declared as a parameter so the testbench can override it if desired
    parameter CLOCK_FREQ = 33_000_000,

    // These are used for the button debouncer and the rotary A/B debouncer
    // They are overridden in the testbench for faster runtime
    parameter integer B_SAMPLE_COUNT_MAX = 0.00076 * CLOCK_FREQ,
    parameter integer B_PULSE_COUNT_MAX = 0.11364/0.00076,
    parameter integer R_SAMPLE_COUNT_MAX = 0.000303 * CLOCK_FREQ,
    parameter integer R_PULSE_COUNT_MAX = 0.003636/0.00030
)(
    input CLK_33MHZ_FPGA,       // 33 Mhz Clock Signal Input
    input [7:0] GPIO_DIP,       // 8 GPIO DIP Switches
    input FPGA_ROTARY_INCA,     // Rotary Encoder Wheel A Signal
    input FPGA_ROTARY_INCB,     // Rotary Encoder Wheel B Signal
    input FPGA_ROTARY_PUSH,     // Rotary Encoder Push Button Signal (Active-high)
    input [4:0] GPIO_BUTTONS,   // Compass Pushbuttons (Active-high)
    input FPGA_CPU_RESET_B,     // CPU_RESET Pushbutton (Active-LOW), signal should be interpreted as logic high when 0

    output PIEZO_SPEAKER,       // Piezo Speaker Output Line (buffered off-FPGA, drives piezo)
    output [7:0] GPIO_LED,      // 8 GPIO LEDs
    output GPIO_LED_C,          // Compass Center LED
    output GPIO_LED_N,          // Compass North LED
    output GPIO_LED_E,          // Compass East LED
    output GPIO_LED_W,          // Compass West LED
    output GPIO_LED_S,          // Compass South LED

    // AC97 Protocol Signals
    input AUDIO_BIT_CLK,
    input AUDIO_SDATA_IN,
    output AUDIO_SDATA_OUT,
    output AUDIO_SYNC,
    output FLASH_AUDIO_RESET_B,

    // UART connections
    input FPGA_SERIAL_RX,
    output FPGA_SERIAL_TX
);
    // You can change these to provide debug info when testing your Piano FSM
    assign GPIO_LED = 8'b0;
    assign GPIO_LED_C = 1'b0;
    assign GPIO_LED_N = 1'b0;
    assign GPIO_LED_E = 1'b0;
    assign GPIO_LED_W = 1'b0;
    assign GPIO_LED_S = 1'b0;

    // Connection between the Piano FSM and PIEZO_SPEAKER
    wire square_wave;

    // We will gate the piezo speaker output with the 8th GPIO switch
    assign PIEZO_SPEAKER = GPIO_DIP[7] ? square_wave : 0;

    // AC97 intermediary signals
    wire bit_clk;
    wire sync;
    wire sdata_out;
    wire reset_b;

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

    // Buffer the AC97 bit clock
    BUFG BitClockBuffer(.I(AUDIO_BIT_CLK), .O(bit_clk));

    // Route the sdata_out and sync signals through IOBs (input/output blocks)
    reg sdata_out_iob, sync_iob /* synthesis iob="true" */;
    assign AUDIO_SDATA_OUT = sdata_out_iob;
    assign AUDIO_SYNC = sync_iob;

    always @ (posedge bit_clk) begin
        sdata_out_iob <= sdata_out;
        sync_iob <= sync;
    end

    // Route the reset_b signal through an IOB clocked by the system_clock
    reg reset_b_iob /* synthesis iob="true" */;
    always @ (posedge CLK_33MHZ_FPGA) begin
        reset_b_iob <= reset_b;
    end

    // Assign the reset signal directly to the reset net going into the codec
    assign FLASH_AUDIO_RESET_B = reset_b_iob;

    // Modify the instantiation of the AC97 controller
    wire ac97_fifo_full;
    ac97_controller audio_controller (
        .sdata_in(AUDIO_SDATA_IN),
        .sdata_out(sdata_out),
        .bit_clk(bit_clk),
        .sync(sync),
        .reset_b(reset_b),
        .volume_control(GPIO_DIP[5:2]),
        .system_clock(CLK_33MHZ_FPGA),
        .system_reset(reset),
        .square_wave(square_wave)
    );

    // Make your ml505top modifications here
endmodule
