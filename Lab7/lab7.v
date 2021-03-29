`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module lab7(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D,
  
  input  uart_rx,
  output uart_tx
);

localparam [1:0] S_MAIN_WAIT = 3'b00,  // wait for press button
                 S_MAIN_SHOW = 3'b01,  // show header
                 S_MAIN_READ = 3'b10,  // read from sram[user_addr] to data_out
                 S_MAIN_CALC = 3'b11;  // calculate B, S and show matrix
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam STR1 = 0;
localparam LEN1 = 39;
localparam STR2 = 39;  // h27
localparam LEN2 = 33;
localparam MEM_SIZE = 72;  // h48

// declare system variables
wire btn1;
wire print_enable, print_done;
reg  [$clog2(MEM_SIZE):0] send_counter;
reg  [1:0]  P, P_next;
reg  [1:0]  Q, Q_next;
reg  [11:0] addrA, addrB;
//reg  [7:0]  user_data;
reg  [0:LEN1*8-1] msg1 = {"The matrix multiplication result is:\r\n", 8'h00};
reg  [0:LEN2*8-1] msg2 = {"[ LOREM, IPSUM, DOLOR, SITAM ]\r\n",       8'h00};
reg  [7:0]  data[0:MEM_SIZE-1];
reg  [7:0]  cnt;
reg  [17:0] S;
reg  [127:0] row_A, row_B;

// declare SRAM control signals
wire [10:0] addr_A, addr_B;
wire [7:0]  data_in;
wire [7:0]  matA, matB;
wire        sram_en;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
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


assign usr_led = {Q, P};

LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);

debounce btn_db1(.clk(clk), .btn_input(usr_btn[1]), .btn_output(btn1));

// ------------------------------------------------------------------------
// The following code creates an initialized SRAM memory block that
// stores an 1024x8-bit unsigned numbers.
sram ramA(.clk(clk), .we(usr_btn[3]), .en(sram_en),
          .addr(addrA), .data_i(data_in), .data_o(matA));
sram ramB(.clk(clk), .we(usr_btn[3]), .en(sram_en),
          .addr(addrB), .data_i(data_in), .data_o(matB));

assign addr_A = addrA;
assign addr_B = addrB;
assign sram_en = (P == S_MAIN_READ); // Enable the SRAM block.
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------


// ------------------------------------------------------------------------
// FSM of the main controller
always @(posedge clk) begin
    if (~reset_n)
        P <= S_MAIN_WAIT;
    else
        P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_WAIT:
        if (btn1) P_next <= S_MAIN_SHOW;
        else P_next <= S_MAIN_WAIT;
    S_MAIN_SHOW:
        if (print_done) P_next <= S_MAIN_READ;
        else P_next <= S_MAIN_SHOW;
    S_MAIN_READ:
        if (~print_done) P_next <= S_MAIN_READ;
        else if (cnt == 65) P_next <= S_MAIN_WAIT;
        else P_next <= S_MAIN_CALC;
    S_MAIN_CALC:
        P_next <= S_MAIN_READ;
  endcase
end
// End of the main controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The following code updates the 1602 LCD text messages.
always @(posedge clk) begin
    if (~reset_n) begin
        row_A <= "----------------";
    end else begin
        row_A[15*8 +: 8] <=   S[16 +: 2] | "0";
        row_A[14*8 +: 8] <= ((S[12 +: 4] > 9) ? "7" : "0") + S[12 +: 4];
        row_A[13*8 +: 8] <= ((S[ 8 +: 4] > 9) ? "7" : "0") + S[ 8 +: 4];
        row_A[12*8 +: 8] <= ((S[ 4 +: 4] > 9) ? "7" : "0") + S[ 4 +: 4];
        row_A[11*8 +: 8] <= ((S[ 0 +: 4] > 9) ? "7" : "0") + S[ 0 +: 4];
        
        row_A[9*8 +: 8] <= ((cnt[4 +: 4] > 9) ? "7" : "0") + cnt[4 +: 4];
        row_A[8*8 +: 8] <= ((cnt[0 +: 4] > 9) ? "7" : "0") + cnt[0 +: 4];
        
        row_A[3*8 +: 8] <= ((addrA[4 +: 4] > 9) ? "7" : "0") + addrA[4 +: 4];
        row_A[2*8 +: 8] <= ((addrB[0 +: 4] > 9) ? "7" : "0") + addrB[0 +: 4];
    end
end

always @(posedge clk) begin
    if (~reset_n) begin
        row_B <= "----------------";
    end else begin
        row_B[15*8 +: 8] <= data[STR2 +  0];
        row_B[14*8 +: 8] <= data[STR2 +  1];
        row_B[13*8 +: 8] <= data[STR2 +  2];
        row_B[12*8 +: 8] <= data[STR2 +  3];
        row_B[11*8 +: 8] <= data[STR2 +  4];
        row_B[10*8 +: 8] <= data[STR2 +  5];
        row_B[ 9*8 +: 8] <= data[STR2 +  6];
        row_B[ 8*8 +: 8] <= data[STR2 +  7];
        row_B[ 7*8 +: 8] <= data[STR2 +  8];
        row_B[ 6*8 +: 8] <= data[STR2 +  9];
        row_B[ 5*8 +: 8] <= data[STR2 + 10];
        row_B[ 4*8 +: 8] <= data[STR2 + 11];
        row_B[ 3*8 +: 8] <= data[STR2 + 12];
        
        row_B[ 1*8 +: 8] <= ((send_counter[4 +: 4] > 9) ? "7" : "0") + send_counter[4 +: 4];
        row_B[ 0*8 +: 8] <= ((send_counter[0 +: 4] > 9) ? "7" : "0") + send_counter[0 +: 4];
    end
end
// End of the 1602 LCD text-updating code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The circuit block that processes the user's button event.
always @(posedge clk) begin
    if (P == S_MAIN_SHOW)
        cnt <= 0;
    if (P == S_MAIN_CALC) begin
        if (cnt[3:0] == 4'h2) begin  // Print row and process next
            if (print_done || cnt < 16)
                cnt <= cnt + 1;
            else
                cnt <= cnt;
        end else if (cnt == 65)  // End of 4 row
            cnt <= cnt;
        else
            cnt <= cnt + 1;
            
        if (cnt[1:0] == 2'h1)  // Column 0
            S <= matA * matB;
        else  // Column 1, 2, 3
            S <= matA * matB + S;

            addrA <= 5'h00 | (cnt[1:0]<<2) | cnt[5:4];
            addrB <= 5'h10 |  cnt[3:0];
    end
end
// End of the user's button control.
// ------------------------------------------------------------------------


// FSM output logics: print string control signals.
assign print_enable = (P != S_MAIN_SHOW && P_next == S_MAIN_SHOW) ||
                      (P == S_MAIN_READ && cnt[3:0] == 4'h0 && cnt >= 16);
assign print_done = (tx_byte == 8'h0);
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
      if (print_enable) Q_next <= S_UART_WAIT;
      else Q_next <= S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next <= S_UART_SEND;
      else Q_next <= S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next <= S_UART_INCR; // transmit next character
      else Q_next <= S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next <= S_UART_IDLE; // string transmission ends
      else Q_next <= S_UART_WAIT;
  endcase
end

// FSM output logics: UART transmission control signals
assign transmit = (Q_next == S_UART_WAIT ||
                   print_enable);
assign tx_byte  = data[send_counter];

// UART send_counter control circuit
always @(posedge clk) begin
    if (~reset_n)
        send_counter <= 0;
    else if (P == S_MAIN_WAIT)
        send_counter <= STR1;
    else if (cd[3:0] == 4'hf)
        send_counter <= STR2;
    else
        send_counter <= send_counter + (Q_next == S_UART_INCR);
end
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// Initializes some strings.
integer idx;

always @(posedge clk) begin
    if (~reset_n) begin
        for (idx = 0; idx < LEN1; idx = idx + 1) data[idx+STR1] = msg1[idx*8 +: 8];
        for (idx = 0; idx < LEN2; idx = idx + 1) data[idx+STR2] = msg2[idx*8 +: 8];
    end else if (P == S_MAIN_READ && cd[1:0] == 2'h0) begin
        data[STR2 +  2 + ((cd[3:2]+3)&3)*7] <=   S[16 +: 2] | "0";
        data[STR2 +  3 + ((cd[3:2]+3)&3)*7] <= ((S[12 +: 4] > 9) ? "7" : "0") + S[12 +: 4];
        data[STR2 +  4 + ((cd[3:2]+3)&3)*7] <= ((S[ 8 +: 4] > 9) ? "7" : "0") + S[ 8 +: 4];
        data[STR2 +  5 + ((cd[3:2]+3)&3)*7] <= ((S[ 4 +: 4] > 9) ? "7" : "0") + S[ 4 +: 4];
        data[STR2 +  6 + ((cd[3:2]+3)&3)*7] <= ((S[ 0 +: 4] > 9) ? "7" : "0") + S[ 0 +: 4];
    end
end

endmodule // Lab 7