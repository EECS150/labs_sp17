// These are the compass button mappings in the 5-bit signal
`define B_CENTER 0
`define B_EAST 1
`define B_NORTH 2
`define B_SOUTH 3
`define B_WEST 4

`define CLOCK_FREQ 33_000_000

module debouncer_fpga_test (
    input CLK_33MHZ_FPGA,       // 33 Mhz Clock Signal Input
    input FPGA_ROTARY_PUSH,     // Rotary Encoder Push Button Signal (Active-high)
    input [4:0] GPIO_BUTTONS,   // Compass User Pushbuttons (Active-high)
    input FPGA_CPU_RESET_B,     // CPU_RESET Pushbutton (Active-LOW), signal should be interpreted as logic high when 0

    output [7:0] GPIO_LED      // 8 GPIO LEDs
);
    // Here are some time constants used for the button debouncer
    localparam integer B_SAMPLE_COUNT_MAX = 0.00076 * `CLOCK_FREQ;
    localparam integer B_PULSE_COUNT_MAX = 0.11364/0.00076;

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

    // Here is the test adder
    reg [7:0] number = 0;
    assign GPIO_LED[7:0] = number;

    always @ (posedge CLK_33MHZ_FPGA) begin
        if (|compass_buttons) begin
            number <= number + 1;
        end
        else if (rotary_push) begin
            number <= number - 1;
        end
        else if (reset) begin
            number <= 0;
        end
        else begin
            number <= number;
        end
    end

endmodule
