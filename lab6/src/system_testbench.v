`timescale 1ns/100ps

`define SECOND 1000000000
`define MS 1000000
`define SYSTEM_CLK_PERIOD 30.3
`define BIT_CLK_PERIOD 81.38

module system_testbench();
    // DUT I/O
    reg system_clock = 0;
    reg [7:0] gpio_switches = 0;
    reg [4:0] gpio_buttons = 0;
    wire [7:0] gpio_leds;
    reg cpu_reset_b = 0;
    reg rotary_A, rotary_B, rotary_push = 0;
    wire led_c, led_n, led_e, led_w, led_s;
    wire piezo_out;
    wire fpga_serial_rx, fpga_serial_tx;

    ml505top #(
        // We are going to override debouncer parameters just to make the testbench faster
        // Now we can saturate a debouncer in 1 clock cycle
        .B_SAMPLE_COUNT_MAX(1),
        .B_PULSE_COUNT_MAX(1),
        .R_SAMPLE_COUNT_MAX(1),
        .R_PULSE_COUNT_MAX(1)
    ) DUT (
        .CLK_33MHZ_FPGA(system_clock),
        .GPIO_DIP(gpio_switches),
        .FPGA_ROTARY_INCA(rotary_A),
        .FPGA_ROTARY_INCB(rotary_B),
        .FPGA_ROTARY_PUSH(rotary_push),
        .GPIO_BUTTONS({button_w, button_s, button_n, button_e, button_c}),    
        .FPGA_CPU_RESET_B(cpu_reset_b),

        .PIEZO_SPEAKER(piezo_out),
        .GPIO_LED(gpio_leds),
        .GPIO_LED_C(led_c),
        .GPIO_LED_N(led_n),
        .GPIO_LED_E(led_e),
        .GPIO_LED_W(led_w),
        .GPIO_LED_S(led_s),

        .AUDIO_BIT_CLK(bit_clk),
        .AUDIO_SDATA_IN(),  // Leave unconnected for this lab
        .AUDIO_SDATA_OUT(sdata_out),
        .AUDIO_SYNC(sync),
        .FLASH_AUDIO_RESET_B(reset_b),

        .FPGA_SERIAL_RX(fpga_serial_rx),
        .FPGA_SERIAL_TX(fpga_serial_tx)
    );

    ac97_codec_model # (
        // Can change to 1 if you want printouts of what the codec model received on every frame
        .DEBUG_MODE(1'b0)
    ) model (
        .sdata_out(sdata_out),
        .sync(sync),
        .reset_b(reset_b),
        .bit_clk(bit_clk),
        .sdata_in()
    );

    // Instantiate an off-chip UART here that uses the RX and TX lines
    // You can refer to the echo_testbench from lab 4

    always #(`SYSTEM_CLK_PERIOD/2) system_clock = ~system_clock;
    
    initial begin
        // Enable piezo and audio controller output
        gpio_switches[0] = 1'b1;
        gpio_switches[7] = 1'b1;

        // Simulate pushing the CPU_RESET button and holding it for a while
        // Verify that the reset signal into the ac97 controller only pulses once
        // Verify that the reset signal to the codec is held for t_RSTLOW seconds
        cpu_reset_b = 1'b0;
        repeat (10) @(posedge system_clock);
        cpu_reset_b = 1'b1;
        repeat (10) @(posedge system_clock);

        // Send a few characters through the off_chip_uart

        // Watch your Piano FSM at work
        #(`MS * 20);

        // ADD SOME MORE STUFF HERE TO TEST YOUR PIANO FSM
        $finish();
    end


endmodule
