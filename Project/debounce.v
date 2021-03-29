`timescale 1ns / 1ps

module debounce(
    input clk,
    input btn_input,
    output btn_output
);

parameter DEBOUNCE_PERIOD = 5_000_000; // 50 ms @ 100 MHz

reg [$clog2(DEBOUNCE_PERIOD):0] counter;

assign btn_output = btn_input == 1 && counter == 0;

always @(posedge clk) begin
    if (btn_input == 1) counter <= DEBOUNCE_PERIOD;
    else counter <= counter - (counter != 0);
end

endmodule
