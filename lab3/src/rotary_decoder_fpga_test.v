`define CLOCK_FREQ 33_000_000

module rotary_decoder_fpga_test (
    input CLK_33MHZ_FPGA,       // 33 Mhz Clock Signal Input
    input FPGA_ROTARY_INCA,     // Rotary Encoder Wheel A Signal
    input FPGA_ROTARY_INCB,     // Rotary Encoder Wheel B Signal
    input FPGA_ROTARY_PUSH,     // Rotary Encoder Push Button Signal (Active-high)
    output [7:0] GPIO_LED      // 8 GPIO LEDs
);
    // Here are some time constants used for the button and rotary encoder debouncer
    localparam integer B_SAMPLE_COUNT_MAX = 0.00076 * `CLOCK_FREQ;
    localparam integer B_PULSE_COUNT_MAX = 0.11364/0.00076;
    localparam integer R_SAMPLE_COUNT_MAX = 0.000303 * `CLOCK_FREQ;
    localparam integer R_PULSE_COUNT_MAX = 0.003636/0.00030;

    wire rotary_push;

    // The button_parser is a wrapper for the synchronizer -> debouncer -> edge detector signal chain
    button_parser #(
        .width(1),
        .sample_count_max(B_SAMPLE_COUNT_MAX),
        .pulse_count_max(B_PULSE_COUNT_MAX)
    ) b_parser (
        .clk(CLK_33MHZ_FPGA),
        .in(FPGA_ROTARY_PUSH),
        .out(rotary_push)
    );

    // Now we add a synchronizer -> debouncer -> rotary_decoder signal chain to the A and B signals
    
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
        .rotary_A(rotary_inca_deb),
        .rotary_B(rotary_incb_deb),
        .rotary_event(rotary_event),
        .rotary_left(rotary_left)
    );

    // Here is the test adder
    reg [7:0] number = 0;
    assign GPIO_LED = number;
    
    always @ (posedge CLK_33MHZ_FPGA) begin
        if (rotary_event && rotary_left) begin
            number <= number - 1;
        end
        else if (rotary_event && !rotary_left) begin
            number <= number + 1;
        end
        else if (rotary_push) begin
            number <= 0;
        end
        else begin
            number <= number;
        end
    end

endmodule
