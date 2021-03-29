`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of CS, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/10/10 16:18:54
// Design Name: 
// Module Name: lab6_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// A simple testbench for UART simulation.
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lab6_tb(
    );

reg  sys_clk = 0;
reg  reset = 0;
reg  [3:0] btn = 4'b0;
reg  rx = 1; /* When the UART rx line is idle, it carries logic '1'. */
wire tx = 0;
wire [3:0] led = 4'b0;
wire [7:0] ASCII_CR = 8'h0D;

integer idx;

event reset_trigger;
event reset_done_trigger;

initial begin
  forever begin
    @ (reset_trigger);
    @ (negedge sys_clk);
    reset = 1;
    @ (negedge sys_clk);
    reset = 0;
    -> reset_done_trigger;
  end
end

lab6 uut(
  .clk(sys_clk),
  .reset_n(~reset),
  .usr_btn(btn),
  .uart_rx(rx),
  .uart_tx(tx),
  .usr_led(led)
);

always 
  #5 sys_clk <= ~sys_clk;

initial
  begin: TEST_CASE_1
    #10 -> reset_trigger;

    // Send START bit after 100 msec
    #100_000_000
    rx = 0;

    // Send "CR" (0x0D) through uart_rx
    for (idx = 0; idx < 8; idx = idx + 1) begin
      #104_167 /* one-bit duration at 9600 bps */
      rx = ASCII_CR[idx];
    end

    // Send one STOP bit
    #104_167 rx = 1;

    // End the simulation
    #200_000 $finish;
  end

endmodule
