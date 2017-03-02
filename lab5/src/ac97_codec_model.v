`timescale 1ns/100ps
/*
    This module attempts to model the AC97 codec (AD1981B) and displays debug messages
    when a control register has been set or when slots 3 and 4 have been written with PCM data.
    This model isn't perfect, but just a good starting point for checking timing of your AC97 controller.
*/
module ac97_codec_model # (
    parameter DEBUG_MODE = 1'b1
)(
    input sdata_out,
    input sync,
    input reset_b,
    output bit_clk,
    output sdata_in
);

    // Some timing parameters from the AD1981B datasheet
    localparam RST_2_CLK = 200;
    localparam READY_DELAY = 10000;
    localparam BIT_CLK_HALF_PERIOD = 40.7;

    // Codec state registers
    reg raw_bit_clk, bit_clk_enable, codec_ready;
    reg prev_sync_value;
    reg [15:0] slot_0;
    reg [19:0] slot_1, slot_2;
    reg signed [19:0] slot_3, slot_4;
    reg [19:0] sdata_out_shift;
    reg [9:0] bit_counter;
    reg [15:0] control_regs [0:127];

    // Initial states of internal codec registers
    initial begin
        raw_bit_clk = 1'b0;
        bit_clk_enable = 1'b0;
        codec_ready = 1'b0;
        prev_sync_value = 1'b0;
        sdata_out_shift = 20'd0;
        bit_counter = 10'd0;
        // Set default values of codec registers
        control_regs[0] =		16'h0D40;	// Reset
        control_regs[2] =		16'h8000;	// Master Volume
        control_regs[4] =		16'h8000;	// Line Level Volume
        control_regs[6] =		16'h8000;	// Mono Volume
        control_regs[10] =		16'h0000;	// PC_Beep Volume
        control_regs[12] =		16'h8008;	// Phone Volume
        control_regs[14] =		16'h8008;	// Mic Volume
        control_regs[16] =		16'h8808;	// Line In Volume
        control_regs[18] =		16'h8808;	// CD Volume
        control_regs[20] =		16'h8808;	// Video Volume
        control_regs[22] =		16'h8808;	// Aux Volume
        control_regs[24] =		16'h8808;	// PCM Out Volume
        control_regs[26] =		16'h0000;	// Record Select
        control_regs[28] =		16'h8000;	// Record Gain
        control_regs[32] =		16'h0000;	// General Purpose
        control_regs[34] =		16'h0101;	// 3D Control (Read Only)
        control_regs[36] =		16'h0000;	// Reserved
        control_regs[38] =		16'h000X;	// Powerdown Control/Status
        control_regs[40] =		16'hX001;	// Extended Audio ID
        control_regs[42] =		16'h0000;	// Extended Audio Control/Status
        control_regs[44] =		16'hBB80;	// PCM DAC Rate
        control_regs[50] =		16'hBB80;	// PCM ADC Rate
        control_regs[90] =		16'h0000;	// Reserved
        control_regs[116] =		16'h0000;	// Reserved
        control_regs[122] =		16'h0000;	// Reserved
        control_regs[124] =		16'h4E53;	// Vendor ID1
        control_regs[126] =		16'h4349;	// Vendor ID2
        // Set initial slots received to zeros
        slot_0 =                20'h00000;
        slot_1 =                20'h00000;
        slot_2 =                20'h00000;
        slot_3 =                20'h00000;
        slot_4 =                20'h00000;
    end

    always #(BIT_CLK_HALF_PERIOD) raw_bit_clk <= ~raw_bit_clk;
    wire start_frame;
    assign bit_clk = raw_bit_clk & bit_clk_enable;
    assign start_frame = sync & ~prev_sync_value;
   
    always begin
        @(negedge reset_b) begin
            bit_clk_enable <= 1'b0;
        end
        @(posedge reset_b) begin #(RST_2_CLK)
            bit_clk_enable <= @(posedge raw_bit_clk) 1'b1;
        end
    end

    always begin
        @(negedge reset_b) begin
            codec_ready <= 1'b0;
        end
        // This is an oversimplification. In the real codec, this delay is greater than 
        // RST_2_CLK, and the way to see if the codec is ready is to read sdata_in until
        // it's first tag bit becomes 1. This functionality will be relegated to the project.
        @(posedge reset_b) begin #(RST_2_CLK)
            codec_ready <= @(posedge raw_bit_clk) 1'b1;
        end
    end
   
    always @(posedge bit_clk) begin
        if (start_frame) bit_counter <= 9'h0; 
        else bit_counter <= bit_counter + 1;
    end

    always @(posedge bit_clk) begin
        if (~reset_b) prev_sync_value <= 1'b0;
        else prev_sync_value <= sync;
    end     

    always @(negedge bit_clk) begin
        if (~reset_b) sdata_out_shift <= 20'h00000;
        else sdata_out_shift <= {sdata_out_shift[18:0], sdata_out};
    end

    always @(negedge bit_clk) begin
        // START OF FRAME
        if (codec_ready & start_frame & DEBUG_MODE) begin
            $display("Starting receipt of AC97 frame at time: %t", $time);
        end
        // SLOT 0 (Tag bits)
        if (codec_ready & (bit_counter == 16)) begin
            slot_0 <= sdata_out_shift[15:0];
        end
        else if (bit_counter == 17 & DEBUG_MODE) begin
            $display("\tReceived Slot 0. Frame Valid: %b, Valid Reg Address: %b, Valid Reg Data: %b, PCM Left Valid Data: %b, PCM Right Valid Data: %b",
                slot_0[15], slot_0[14], slot_0[13], slot_0[12], slot_0[11]);
            if (slot_0[15] == 1'b0) begin
                $display("\tFrame is not valid.");
            end
        end
        // SLOT 1 (Register Command + Address)
        else if (codec_ready & (bit_counter == 36)) begin
            slot_1 <= sdata_out_shift[19:0];
        end
        else if (bit_counter == 37 & DEBUG_MODE) begin
            // If the data in this slot is valid, print it out and register it.
            if (slot_0[14] && slot_0[15]) begin
                $display("\tReceived Slot 1. Command: %s, Address: 0x%h, Rest of Frame: 0x%h", slot_1[19] ? "Read" : "Write", slot_1[18:12], slot_1[11:0]);
            end
            else begin
                $display("\tSlot 1 marked not valid. Data discarded.");
            end
        end
        // SLOT 2 (Register Write Data)
        else if (codec_ready & (bit_counter == 56)) begin
            slot_2 <= sdata_out_shift[19:0];
        end
        else if (bit_counter == 57 & DEBUG_MODE) begin
            if (slot_0[13] && slot_0[15]) begin
                $display("\tReceived Slot 2. Data: 0x%h, Rest of Frame: 0x%h", slot_2[19:4], slot_1[3:0]);
            end
            else begin
                $display("\tSlot 2 marked not valid. Data discarded.");
            end
        end
        // SLOT 3 (PCM Data Left Channel)
        else if (codec_ready & (bit_counter == 76)) begin
            slot_3 <= sdata_out_shift[19:0];
        end
        else if (bit_counter == 77 & DEBUG_MODE) begin
            if (slot_0[12] && slot_0[15]) begin
                $display("\tReceived Slot 3. Left Channel PCM Data (signed decimal): %d", slot_3);
            end
            else begin
                $display("\tSlot 3 marked not valid. Data discarded.");
            end
        end
        // SLOT 4 (PCM Data Right Channel)
        else if (codec_ready & (bit_counter == 96)) begin
            slot_4 <= sdata_out_shift[19:0];
        end
        else if (bit_counter == 97 & DEBUG_MODE) begin
            if (slot_0[11] && slot_0[15]) begin
                $display("\tReceived Slot 4. Right Channel PCM Data (signed decimal): %d", slot_4);
            end
            else begin
                $display("\tSlot 4 marked not valid. Data discarded.");
            end
        end
    end

    // This block checks that the SYNC signal has the correct duty cycle and that
    // the reset signal is long enough to meet the spec in the datasheet.
    specify
        specparam
            tBC =		81.4,
            tBCH =		32.6,
            tBCL =		32.6,
            tSYNC =		20833.3,
            tSYNCH =	1302.4,
            tSYNCL =	19454.6,
            tDSETUP =	15,
            tDHOLD =	5,
            tRST_LOW =	1000;

        $width (posedge sync, tSYNCH);
        $width (negedge sync, tSYNCL);
        $width (negedge reset_b, tRST_LOW);

        $period (posedge sync, tSYNC);
        $period (negedge sync, tSYNC);
    endspecify
   
endmodule
