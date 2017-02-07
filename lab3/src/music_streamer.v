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

    reg [9:0] tone_index = 0;
    reg [22:0] clock_counter = 0;
    rom music_data (
        .address(tone_index),       // 10 bits
        .data(tone),                // 24 bits
        .last_address()
    );

    // Add your implementation from lab 2 here

    // Remove these assignments after creating the FSM
    assign led_center = 1'b1;
    assign led_north = 1'b0;
    assign led_east = 1'b0;
    assign led_west = 1'b0;
    assign led_south = 1'b0;
    assign GPIO_leds = 8'd0;

    // Use these nets for constructing your FSM
    localparam PAUSED = 3'd0;
    localparam REGULAR_PLAY = 3'd1;
    localparam REVERSE_PLAY = 3'd2;
    localparam PLAY_SEQ = 3'd3;
    localparam EDIT_SEQ = 3'd4;
    reg [2:0] current_state;
    reg [2:0] next_state;

    // The following RTL is provided as starter code for Section 8: Music Sequencer
    reg [23:0] sequencer_mem [7:0];
    reg [2:0] sequencer_addr;
    reg [23:0] tone_under_edit;

    // Registering and modification of the tone_under_edit (sequencer)
    always @ (posedge clk) begin
        tone_under_edit <= tone_under_edit;

        // If we are moving into edit mode from the play mode, register the note
        if (next_state == EDIT_SEQ && current_state == PLAY_SEQ) begin
            tone_under_edit <= sequencer_mem[sequencer_addr];
        end
        // We are currently in edit mode, if we switch notes or edit the current note, we should update the tone_under_edit
        else if (current_state == EDIT_SEQ) begin
            if (button_east) tone_under_edit <= sequencer_mem[sequencer_addr + 3'd1];
            else if (button_west) tone_under_edit <= sequencer_mem[sequencer_addr - 3'd1];
            else if (rotary_event && rotary_left) tone_under_edit <= tone_under_edit + 24'd1000;
            else if (rotary_event && !rotary_left) tone_under_edit <= tone_under_edit - 24'd1000;
            else tone_under_edit <= tone_under_edit;
        end
    end


    // Modification of the sequencer notes (sequencer_mem)
    always @ (posedge clk) begin
        if (rst) begin
            sequencer_mem[0] <= 24'd37500;
            sequencer_mem[1] <= 24'd37500;
            sequencer_mem[2] <= 24'd37500;
            sequencer_mem[3] <= 24'd37500;
            sequencer_mem[4] <= 24'd37500;
            sequencer_mem[5] <= 24'd37500;
            sequencer_mem[6] <= 24'd37500;
            sequencer_mem[7] <= 24'd37500;
        end
        // If we are in edit mode and the user pushes in the rotary encoder, store the tone_under_edit in the sequencer memory
        else if (current_state == EDIT_SEQ && rotary_push) begin
            sequencer_mem[sequencer_addr] <= tone_under_edit;
        end
        else begin
            sequencer_mem[sequencer_addr] <= sequencer_mem[sequencer_addr];
        end
    end

endmodule
