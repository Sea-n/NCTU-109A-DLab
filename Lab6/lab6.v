`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of CS, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/10/10 16:10:38
// Design Name: UART I/O example for Arty
// Module Name: lab6
// Project Name: 
// Target Devices: Xilinx FPGA @ 100MHz
// Tool Versions: 
// Description: 
// 
// The parameters for the UART controller are 9600 baudrate, 8-N-1-N
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab6(
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  input  uart_rx,
  output uart_tx
);

localparam [2:0] S_MAIN_INIT = 0,
                 S_MAIN_PROMPT1 = 1,
                 S_MAIN_READ_NUM1 = 2,
                 S_MAIN_PROMPT2 = 3,
                 S_MAIN_READ_NUM2 = 4,
                 S_MAIN_CALC = 5,
                 S_MAIN_REPLY = 6;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz
localparam STR1 = 0;
localparam LEN1 = 35;
localparam STR2 = 35;
localparam LEN2 = 36;
localparam STR3 = 71;
localparam LEN3 = 36;
localparam MEM_SIZE = 107;

// declare system variables
wire enter_pressed;
wire print_enable, print_done;
reg [$clog2(MEM_SIZE):0] send_counter;
reg [2:0] P, P_next;
reg [1:0] Q, Q_next;
reg [$clog2(INIT_DELAY):0] init_counter;
reg [4:0] calc_counter;
reg [7:0] data[0:MEM_SIZE-1];
reg  [0:LEN1*8-1] msg1 = {"\r\nEnter the first decimal number: ", 8'h00};
reg  [0:LEN2*8-1] msg2 = {"\r\nEnter the second decimal number: ", 8'h00};
reg  [0:LEN3*8-1] msg3 = {"\r\nThe integer quotient is: 0x0000\r\n", 8'h00};
reg  [15:0] num1;
reg  [15:0] num2;
reg  [15:0] num3;
reg  [2:0]  key_cnt;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire [7:0] echo_key; // keystrokes to be echoed to the terminal
wire is_num_key;
wire is_receiving;
wire is_transmitting;
wire recv_error;

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

// Initializes some strings.
// System Verilog has an easier way to initialize an array,
// but we are using Verilog 2001 :(
//
integer idx;

always @(posedge clk) begin
  if (~reset_n) begin
    for (idx = 0; idx < LEN1; idx = idx + 1) data[idx+STR1] = msg1[idx*8 +: 8];
    for (idx = 0; idx < LEN2; idx = idx + 1) data[idx+STR2] = msg2[idx*8 +: 8];
    for (idx = 0; idx < LEN3; idx = idx + 1) data[idx+STR3] = msg3[idx*8 +: 8];
  end
  else if (P == S_MAIN_REPLY) begin
    data[STR3+29] <= ((num3[15:12] > 9) ? "7" : "0") + num3[15:12];
    data[STR3+30] <= ((num3[11: 8] > 9) ? "7" : "0") + num3[11: 8];
    data[STR3+31] <= ((num3[ 7: 4] > 9) ? "7" : "0") + num3[ 7: 4];
    data[STR3+32] <= ((num3[ 3: 0] > 9) ? "7" : "0") + num3[ 3: 0];
  end
end

// Combinational I/O logics of the top-level system
assign usr_led = usr_btn;
assign enter_pressed = (rx_temp == 8'h0D); // don't use rx_byte here!

// ------------------------------------------------------------------------
// Main FSM that reads the UART input and triggers
// the output of the string "Hello, World!".
always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // Wait for initial delay of the circuit.
	   if (init_counter > INIT_DELAY) P_next = S_MAIN_PROMPT1;
		else P_next = S_MAIN_INIT;
    S_MAIN_PROMPT1: // Print the prompt message.
      if (print_done) P_next = S_MAIN_READ_NUM1;
      else P_next = S_MAIN_PROMPT1;
    S_MAIN_READ_NUM1: // wait for <Enter> key.
      if (enter_pressed) P_next = S_MAIN_PROMPT2;
      else P_next = S_MAIN_READ_NUM1;
    S_MAIN_PROMPT2: // Print the prompt message.
      if (print_done) P_next = S_MAIN_READ_NUM2;
      else P_next = S_MAIN_PROMPT2;
    S_MAIN_READ_NUM2: // wait for <Enter> key.
      if (enter_pressed) P_next = S_MAIN_CALC;
      else P_next = S_MAIN_READ_NUM2;
    S_MAIN_CALC: // wait for division
      if (calc_counter == 0) P_next = S_MAIN_REPLY;
      else P_next = S_MAIN_CALC;
    S_MAIN_REPLY: // Print the reply message.
      if (print_done) P_next = S_MAIN_INIT;
      else P_next = S_MAIN_REPLY;
  endcase
end

// FSM output logics: print string control signals.
assign print_enable = (P != S_MAIN_PROMPT1 && P_next == S_MAIN_PROMPT1) ||
                      (P == S_MAIN_READ_NUM1 && P_next == S_MAIN_PROMPT2) ||
                      (P == S_MAIN_CALC   && P_next == S_MAIN_REPLY);
assign print_done = (tx_byte == 8'h0);

// Initialization counter.
always @(posedge clk) begin
  if (P == S_MAIN_INIT) init_counter <= init_counter + 1;
  else init_counter <= 0;
end
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics: UART transmission control signals
assign transmit = (Q_next == S_UART_WAIT ||
                  (P == S_MAIN_READ_NUM1 && received) ||
                  (P == S_MAIN_READ_NUM2 && received) ||
                   print_enable);
assign is_num_key = (rx_byte > 8'h2F) && (rx_byte < 8'h3A) && (key_cnt < 5);
assign echo_key = (is_num_key || rx_byte == 8'h0D)? rx_byte : 0;
assign tx_byte  = ((P == S_MAIN_READ_NUM1 || P == S_MAIN_READ_NUM2) && received) ? echo_key : data[send_counter];

// UART send_counter control circuit
always @(posedge clk) begin
  case (P_next)
    S_MAIN_INIT: send_counter <= STR1;
    S_MAIN_READ_NUM1: send_counter <= STR2;
    S_MAIN_READ_NUM2: send_counter <= STR3;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR);
  endcase
end
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// UART input logic
// Decimal number input will be saved in num1 or num2.
always @(posedge clk) begin
  if (~reset_n || (P == S_MAIN_PROMPT1 || P == S_MAIN_PROMPT2))
    key_cnt <= 0;
  else if (received && is_num_key)
    key_cnt <= key_cnt + 1;
end

always @(posedge clk) begin
  if (P == S_MAIN_PROMPT1)
    num1 <= 0;
  else if (P == S_MAIN_PROMPT2) begin
    num2 <= 0;
    num3 <= 0;
    calc_counter <= 31;
  end else if (received && is_num_key) begin
    if (P == S_MAIN_READ_NUM1)
        num1 <= (num1 * 10) + (rx_byte - 48);
    if (P == S_MAIN_READ_NUM2)
        num2 <= (num2 * 10) + (rx_byte - 48);
  end else if (P == S_MAIN_CALC) begin
    if ((num1>>calc_counter) >= num2) begin
        num3 <= num3 | (1<<calc_counter);
        num1 <= num1 - (num2<<calc_counter);
    end
    calc_counter <= calc_counter- 1;
  end
end

// The following logic stores the UART input in a temporary buffer.
// The input character will stay in the buffer for one clock cycle.
always @(posedge clk) begin
  rx_temp <= (received)? rx_byte : 8'h0;
end
// End of the UART input logic
// ------------------------------------------------------------------------

endmodule
