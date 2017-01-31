module music_streamer (
    input clk,
    output [23:0] tone,
    output [9:0] rom_address
);
    reg [9:0] tone_index = 0;
    reg [22:0] clock_counter = 0;

    assign rom_address = 0;

    rom music_data (
        .address(tone_index),   // 10 bits
        .data(tone),            // 24 bits
        .last_address()
    );

    // Edit these blocks and add any registers that you may need
    always @ (posedge clk) begin
        clock_counter <= clock_counter + 1'd1;
    end

    always @ (posedge clk) begin
        tone_index <= tone_index + 1'd1;
    end

endmodule
