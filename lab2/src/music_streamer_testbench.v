`timescale 1ns/1ns

`define SECOND 1000000000
`define MS 1000000
`define SAMPLE_PERIOD 22675.7

module music_streamer_testbench();
    reg clock;

    wire piezo;

    initial clock = 0;
    always #(30.3/2) clock <= ~clock;

    ml505top top (
        .CLK_33MHZ_FPGA(clock),
        .GPIO_DIP(8'hFF),
        .GPIO_LED(),
        .PIEZO_SPEAKER(piezo)
    );

    initial begin
        #(2 * `SECOND);
        $finish();
    end

    integer file;
    initial begin
        file = $fopen("output.txt", "w");
        forever begin
            $fwrite(file, "%h\n", piezo);
            #(`SAMPLE_PERIOD);
        end
    end

endmodule
