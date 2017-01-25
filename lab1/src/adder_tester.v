module adder_tester (
    output [7:0] adder_operand1,
    output [7:0] adder_operand2,
    input [8:0] structural_sum,
    input [8:0] behavioral_sum,
    input clk,
    output test_fail
);

    // This 'reg assignment' sets the value of the 'error' register to 0 when 'make impact' is run
    // This kind of initial value setting IS NOT synthesizable on ASICs. It only works on certain FPGAs.
    reg error = 0;
    assign test_fail = error;

    reg [15:0] operands;
    assign adder_operand1 = operands[7:0];
    assign adder_operand2 = operands[15:8];

    // Iterate the operands continuously until all combinations are tried
    always @ (posedge clk) begin
        operands <= operands + 1'd1;
    end

    // If we encounter a case where the adders don't match, or we have already encountered one such case,
    // flip the error register high and hold it there.
    always @ (posedge clk) begin
        if (structural_sum != behavioral_sum) begin
            error <= 1'b1;
        end
        else begin
            error <= error;
        end
    end

endmodule
