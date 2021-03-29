`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module lab8(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // SD card specific I/O ports
  output spi_ss,
  output spi_sck,
  output spi_mosi,
  input  spi_miso,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [2:0] S_MAIN_INIT = 3'b000, S_MAIN_IDLE = 3'b001,
                 S_MAIN_WATF = 3'b010, S_MAIN_FIND = 3'b011,
                 S_MAIN_WATR = 3'b100, S_MAIN_READ = 3'b101,
                 S_MAIN_CUNT = 3'b110, S_MAIN_SHOW = 3'b111;

// Declare system variables
wire [3:0] btn_level, btn;
reg  [3:0] prev_btn;
reg  [2:0] P, P_next;
reg  [9:0] sd_counter;

reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";
reg  [63:0] buffer;
reg  [15:0] ans_cnt;

// Declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req;
reg  [31:0] rd_addr;
wire init_finished;
wire [7:0] sd_dout;
wire sd_valid;

assign clk_sel = (init_finished) ? clk : clk_500k; // clock for the SD controller
assign usr_led = P;

clk_divider#(200) clk_divider0(.clk(clk), .reset(~reset_n), .clk_out(clk_500k));

debounce btn_db0(.clk(clk), .btn_input(usr_btn[0]), .btn_output(btn_level[0]));
debounce btn_db1(.clk(clk), .btn_input(usr_btn[1]), .btn_output(btn_level[1]));
debounce btn_db2(.clk(clk), .btn_input(usr_btn[2]), .btn_output(btn_level[2]));
debounce btn_db3(.clk(clk), .btn_input(usr_btn[3]), .btn_output(btn_level[3]));

LCD_module lcd0(.clk(clk), .reset(~reset_n), .row_A(row_A), .row_B(row_B),
                .LCD_E(LCD_E), .LCD_RS(LCD_RS), .LCD_RW(LCD_RW), .LCD_D(LCD_D));

sd_card sd_card0(.cs(spi_ss), .sclk(spi_sck), .mosi(spi_mosi), .miso(spi_miso),
                 .clk(clk_sel), .rst(~reset_n), .rd_req(rd_req), .block_addr(rd_addr),
                 .init_finished(init_finished), .dout(sd_dout), .sd_valid(sd_valid));


// Enable one cycle of btn_pressed per each button hit
always @(posedge clk) begin
  if (~reset_n) prev_btn <= 4'h0;
  else prev_btn <= btn_level;
end

assign btn = (btn_level & ~prev_btn);


// ------------------------------------------------------------------------
// FSM of the SD card reader that reads the super block (512 bytes)
always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end

always @(*) begin // FSM next-state logic
    case (P)
        S_MAIN_INIT: // wait for SD card initialization
            if (init_finished == 1) P_next <= S_MAIN_IDLE;
            else P_next <= S_MAIN_INIT;
        S_MAIN_IDLE: // wait for button click
            if (btn[2]) P_next <= S_MAIN_WATF;
            else P_next <= S_MAIN_IDLE;
        S_MAIN_WATF: // issue a rd_req to the SD controller until it's ready
            P_next <= S_MAIN_FIND;
        S_MAIN_FIND: // wait for the input data to enter the buffer
            if (buffer == "DLAB_TAG") P_next <= S_MAIN_READ;
            else if (sd_counter == 512) P_next <= S_MAIN_WATF;
            else P_next <= S_MAIN_FIND;
        S_MAIN_WATR: // issue a rd_req to the SD controller until it's ready
            P_next <= S_MAIN_READ;
        S_MAIN_READ: // wait for the input data to enter the buffer
            if (buffer == "DLAB_END") P_next <= S_MAIN_SHOW;
            else if (sd_counter == 512) P_next <= S_MAIN_WATR;
            else P_next <= S_MAIN_READ;
        S_MAIN_SHOW:
            if (btn[2]) P_next <= S_MAIN_IDLE;
            else P_next = S_MAIN_SHOW;
        default:
            P_next <= S_MAIN_IDLE;
    endcase
end
// End of the FSM of the SD card reader
// ------------------------------------------------------------------------


always @(*) begin
    rd_req <= (P == S_MAIN_WATF || P == S_MAIN_WATR);
end

always @(posedge clk) begin
    if (~reset_n || P == S_MAIN_IDLE)
        rd_addr <= 32'h2000;
    else if (P == S_MAIN_WATF || P == S_MAIN_WATR)
        rd_addr <= rd_addr + 1;

    if (~reset_n || P == S_MAIN_WATF || P == S_MAIN_WATR)
        sd_counter <= 0;
    else if (sd_valid)
        sd_counter <= sd_counter + 1;

    if (~reset_n)
        buffer <= 64'h0;
    else if ((P == S_MAIN_FIND || P == S_MAIN_READ) && sd_valid)
        buffer <= {buffer[55:0], sd_dout};
end

always @(posedge clk) begin
    if (~reset_n || P == S_MAIN_WATF)
        ans_cnt <= 16'hFFFF;  // -1 for DLAB_TAG
    else if (P == S_MAIN_READ && sd_valid) begin
        if (!("a" <= (buffer[39:32]|8'h20) && (buffer[39:32]|8'h20) <= "z")
         &&  ("a" <= (buffer[31:24]|8'h20) && (buffer[31:24]|8'h20) <= "z")
         &&  ("a" <= (buffer[23:16]|8'h20) && (buffer[23:16]|8'h20) <= "z")
         &&  ("a" <= (buffer[15: 8]|8'h20) && (buffer[15: 8]|8'h20) <= "z")
         && !("a" <= (buffer[ 7: 0]|8'h20) && (buffer[ 7: 0]|8'h20) <= "z"))
            ans_cnt <= ans_cnt + 1;
    end
end


// LCD Display function.
always @(posedge clk) begin
    if (~reset_n) begin
        row_A <= "SD card cannot  ";
        row_B <= "be initialized! ";
    end else if (P == S_MAIN_IDLE) begin
        row_A <= "Hit BTN2 to read";
        row_B <= "the SD card ... ";
    end else if (P == S_MAIN_FIND) begin
        row_A <=  "Finding DLAB_TAG";
        row_B <= {"Cursor at 0x",
                 ((rd_addr[15:12] > 9) ? "7" : "0") + rd_addr[15:12],
                 ((rd_addr[11: 8] > 9) ? "7" : "0") + rd_addr[11: 8],
                 ((rd_addr[ 7: 4] > 9) ? "7" : "0") + rd_addr[ 7: 4],
                 ((rd_addr[ 3: 0] > 9) ? "7" : "0") + rd_addr[ 3: 0]};
    end else if (P == S_MAIN_SHOW) begin
        row_A <= {"Found ",
                 ((ans_cnt[15:12] > 9)? "7" : "0") + ans_cnt[15:12],
                 ((ans_cnt[11: 8] > 9)? "7" : "0") + ans_cnt[11: 8],
                 ((ans_cnt[ 7: 4] > 9)? "7" : "0") + ans_cnt[ 7: 4],
                 ((ans_cnt[ 3: 0] > 9)? "7" : "0") + ans_cnt[ 3: 0],
                  " words"};
        row_B <= "in the text file";
    end
end

endmodule  // Lab 8