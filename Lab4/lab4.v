`timescale 1ns / 1ps
module lab4(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);

wire [3:0] btn;
debounce A0(clk, reset_n, usr_btn[0], btn[0]);
debounce A1(clk, reset_n, usr_btn[1], btn[1]);
debounce A2(clk, reset_n, usr_btn[2], btn[2]);
debounce A3(clk, reset_n, usr_btn[3], btn[3]);

reg signed [3:0] cnt;
reg [3:0] bri;
reg mask;
reg [23:0] period;

assign usr_led = cnt & {4{mask}};

always @(posedge clk, negedge reset_n) begin
    if (reset_n == 0) begin
        bri <= 8;
        cnt <= 3;
        period <= 0;
        mask <= 1;
    end else begin
        if (btn[0] && cnt != -8)
            cnt <= cnt - 1;
        else if (btn[1] && cnt != 7)
            cnt <= cnt + 1;
        if (btn[2] && bri != 4'h1)
            bri <= bri - 1;
        else if (btn[3] && bri != 4'hf)
            bri <= bri + 1;

        if (period[19:16] <= bri)
            mask = 1;
        else
            mask = 0;

        period <= period + 1;
    end
end

endmodule


module debounce(
    input clk,
    input reset_n,
    input btn,
    output sig_out
);

reg [27:0] pressing;
reg sig;

assign sig_out = sig;

always @(posedge clk, negedge reset_n) begin
    if (reset_n == 0) begin
        pressing = 28'h7654321;
        sig <= 0;
    end else begin
        if (sig == 1)
            sig = 0;
        else if (pressing > 28'h7a8b9c0) begin
            sig <= 1;
            pressing <= 28'h6420531;
        end else if (btn)
            pressing <= pressing + 1;
        else if (pressing < 28'h7654322)
            pressing <= pressing + 3;
        else if (pressing > 28'h7654323)
            pressing <= pressing - 3;
    end
end

endmodule