module piano_fsm (
    input clk,  // 33 Mhz clock as usual
    input rst,
    input rotary_event,
    input rotary_left,

    output [7:0] ua_transmit_din,
    output ua_transmit_wr_en,
    input ua_transmit_full,

    input [7:0] ua_receive_dout,
    input ua_receive_empty,
    output ua_receive_rd_en,

    output [19:0] ac97_din,
    output ac97_wr_en,
    input ac97_full,

    output piezo_speaker
);
    assign piezo_speaker = 1'b0;
    assign ua_transmit_din = 0;
    assign ua_transmit_wr_en = 0;
    assign ua_receive_rd_en = 0;
    assign ac97_din = 0;
    assign ac97_wr_en = 0;
endmodule
