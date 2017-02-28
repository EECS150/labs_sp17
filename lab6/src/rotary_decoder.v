module rotary_decoder (
    input clk,
    input rst,
    input rotary_A,
    input rotary_B,
    output rotary_event,
    output rotary_left
);

    // Create your rotary decoder circuit here
    // This module takes in rotary_A and rotary_B which are the A and B signals synchronized to clk
    // In this module you should implement the Rotary Contact Filter 
    // and should output a vector of 1-bit signals that pulse high for one clock cycle when their respective counter saturates

    // Remove these lines after implementing your rotary decoder
    assign rotary_event = 0;
    assign rotary_left = 0;
endmodule
