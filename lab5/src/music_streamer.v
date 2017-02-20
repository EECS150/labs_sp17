module music_streamer (
    input clk,
    input rst,
    input rotary_event,
    input rotary_left,
    input rotary_push,
    input button_center,
    input button_north,
    input button_east,
    input button_west,
    input button_south,
    output led_center,
    output led_north,
    output led_east,
    output led_west,
    output led_south,
    output [23:0] tone,
    output [7:0] GPIO_leds
);
    // Copy your music_streamer from lab 3
    assign led_center = 1'b0;
    assign led_north = 1'b0;
    assign led_east = 1'b0;
    assign led_south = 1'b0;
    assign led_west = 1'b0;
    assign tone = 24'd0;
    assign GPIO_leds = 8'd0;
endmodule
