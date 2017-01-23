module tone_generator (
    input output_enable,
    input clk,
    output square_wave_out
);

    reg [16:0] clock_counter;

    always @ (posedge clk) begin
        clock_counter <= clock_counter + 1'd1;
    end

    assign square_wave_out = 1'b0;
endmodule
