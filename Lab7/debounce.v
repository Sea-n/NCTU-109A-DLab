`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module debounce(
    input clk,
    input btn_input,
    output btn_output
    );

    reg [21:0] cnt = 24'h000000;
    reg sig  = 0;
    reg prev = 0;

    assign btn_output = sig;

    always @(posedge clk) begin
        if (sig == 1) begin
            sig <= 0;
            prev <= 1;
        end else if (~prev && cnt == 22'h234567)
            sig = 1;
        else if (prev && cnt == 0)
            prev <= 0;
        else if ( btn_input && ~prev)
            cnt <= cnt + 1;
        else if (~btn_input && cnt)
            cnt <= cnt - 1;
    end
endmodule
