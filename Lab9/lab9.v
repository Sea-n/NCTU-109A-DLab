`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module lab9(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [1:0] S_MAIN_INIT = 2'b00, S_MAIN_CALC = 2'b01, S_MAIN_SHOW = 2'b10;

// Declare system variables
reg  [127:0] passwd_hash = 128'hEF775988943825D2871E1CFA75473EC0;
wire btn_level, btn;
reg  prev_btn;
reg  [1:0] P, P_next;

reg  [127:0] row_A;
reg  [127:0] row_B;
reg  [63:0]  txt  [0:2];
wire [127:0] hash0, hash1, hash2;
wire [63:0]  ans0, ans1, ans2;
reg  [63:0]  ans_reg;
reg  [87:0]  cnt;  // Store as ASCII / 10ns
reg  done = 0;


LCD_module lcd0(.clk(clk), .reset(~reset_n), .row_A(row_A), .row_B(row_B),
                .LCD_E(LCD_E), .LCD_RS(LCD_RS), .LCD_RW(LCD_RW), .LCD_D(LCD_D));

md5 m0(.clk(clk), .in_txt(txt[0]), .hash(hash0), .out_txt(ans0));
md5 m1(.clk(clk), .in_txt(txt[1]), .hash(hash1), .out_txt(ans1));
md5 m2(.clk(clk), .in_txt(txt[2]), .hash(hash2), .out_txt(ans2));


// Debounced Button
debounce btn_db2(.clk(clk), .btn_input(usr_btn[2]), .btn_output(btn_level));

always @(posedge clk) begin
    if (~reset_n) prev_btn <= 0;
    else prev_btn <= btn_level;
end
assign btn = (btn_level & ~prev_btn);

// ------------------------------------------------------------------------
// Start of the FSM
always @(posedge clk) begin
    if (~reset_n) P <= S_MAIN_INIT;
    else P <= P_next;
end

always @(*) begin // FSM next-state logic
    case (P)
        S_MAIN_INIT:
            if (btn) P_next <= S_MAIN_CALC;
            else P_next <= S_MAIN_INIT;
        S_MAIN_CALC:
            if (done) P_next <= S_MAIN_SHOW;
            else P_next <= S_MAIN_CALC;
        S_MAIN_SHOW:
            if (btn) P_next <= S_MAIN_INIT;
            else P_next <= S_MAIN_SHOW;
        default:
            P_next <= S_MAIN_INIT;
    endcase
end
// End of the FSM
// ------------------------------------------------------------------------


// Timer
always @(posedge clk) begin
    if (P == S_MAIN_INIT)
        cnt <= "00000000000";
    else if (P == S_MAIN_CALC) begin
        if (cnt[ 0 +: 4] == 4'h9) begin cnt[ 0 +: 4] <= 4'h0;
        if (cnt[ 8 +: 4] == 4'h9) begin cnt[ 8 +: 4] <= 4'h0;
        if (cnt[16 +: 4] == 4'h9) begin cnt[16 +: 4] <= 4'h0;
        if (cnt[24 +: 4] == 4'h9) begin cnt[24 +: 4] <= 4'h0;
        if (cnt[32 +: 4] == 4'h9) begin cnt[32 +: 4] <= 4'h0;
        if (cnt[40 +: 4] == 4'h9) begin cnt[40 +: 4] <= 4'h0;
        if (cnt[48 +: 4] == 4'h9) begin cnt[48 +: 4] <= 4'h0;
        if (cnt[56 +: 4] == 4'h9) begin cnt[56 +: 4] <= 4'h0;
        if (cnt[64 +: 4] == 4'h9) begin cnt[64 +: 4] <= 4'h0;
        if (cnt[72 +: 4] == 4'h9) begin cnt[72 +: 4] <= 4'h0;
        if (cnt[80 +: 4] == 4'h9) begin cnt[80 +: 4] <= 4'h0;
        end else cnt[80 +: 4] <= cnt[80 +: 4] + 1;
        end else cnt[72 +: 4] <= cnt[72 +: 4] + 1;
        end else cnt[64 +: 4] <= cnt[64 +: 4] + 1;
        end else cnt[56 +: 4] <= cnt[56 +: 4] + 1;
        end else cnt[48 +: 4] <= cnt[48 +: 4] + 1;
        end else cnt[40 +: 4] <= cnt[40 +: 4] + 1;
        end else cnt[32 +: 4] <= cnt[32 +: 4] + 1;
        end else cnt[24 +: 4] <= cnt[24 +: 4] + 1;
        end else cnt[16 +: 4] <= cnt[16 +: 4] + 1;
        end else cnt[ 8 +: 4] <= cnt[ 8 +: 4] + 1;
        end else cnt[ 0 +: 4] <= cnt[ 0 +: 4] + 1;
    end
end

// Check md5 output
always @(posedge clk) begin
    if (P == S_MAIN_INIT) done <= 0;
    else if (hash0 == passwd_hash) begin done <= 1; ans_reg <= ans0; end
    else if (hash1 == passwd_hash) begin done <= 1; ans_reg <= ans1; end
    else if (hash2 == passwd_hash) begin done <= 1; ans_reg <= ans2; end
end

// Next permutation
integer idx;
always @(posedge clk) begin
    if (P == S_MAIN_INIT) begin
        txt[0] <= "00000000";
        txt[1] <= "33333333";
        txt[2] <= "66666666";
    end else if (P == S_MAIN_CALC) begin
        for (idx=0; idx<=2; idx=idx+1) begin
            if (txt[idx][ 0 +: 4] == 4'h9) begin txt[idx][ 0 +: 4] <= 4'h0;
            if (txt[idx][ 8 +: 4] == 4'h9) begin txt[idx][ 8 +: 4] <= 4'h0;
            if (txt[idx][16 +: 4] == 4'h9) begin txt[idx][16 +: 4] <= 4'h0;
            if (txt[idx][24 +: 4] == 4'h9) begin txt[idx][24 +: 4] <= 4'h0;
            if (txt[idx][32 +: 4] == 4'h9) begin txt[idx][32 +: 4] <= 4'h0;
            if (txt[idx][40 +: 4] == 4'h9) begin txt[idx][40 +: 4] <= 4'h0;
            if (txt[idx][48 +: 4] == 4'h9) begin txt[idx][48 +: 4] <= 4'h0;
            if (txt[idx][56 +: 4] == 4'h9) begin txt[idx][56 +: 4] <= 4'h0;
            end else txt[idx][56 +: 4] <= txt[idx][56 +: 4] + 1;
            end else txt[idx][48 +: 4] <= txt[idx][48 +: 4] + 1;
            end else txt[idx][40 +: 4] <= txt[idx][40 +: 4] + 1;
            end else txt[idx][32 +: 4] <= txt[idx][32 +: 4] + 1;
            end else txt[idx][24 +: 4] <= txt[idx][24 +: 4] + 1;
            end else txt[idx][16 +: 4] <= txt[idx][16 +: 4] + 1;
            end else txt[idx][ 8 +: 4] <= txt[idx][ 8 +: 4] + 1;
            end else txt[idx][ 0 +: 4] <= txt[idx][ 0 +: 4] + 1;
        end
    end
end


// LCD Display function.
always @(posedge clk) begin
    if (P == S_MAIN_INIT) begin
        row_A <= "Press  BTN2  to ";
        row_B <= "start calcualte ";
    end else if (P == S_MAIN_CALC) begin
        row_A <= "Calculating.....";
        row_B <= "                ";
    end else if (P == S_MAIN_SHOW) begin
        row_A <= {"Passwd: ", ans_reg};
        row_B <= {"Time:    ", cnt[40 +: 40], " ms"};
    end
end

endmodule  // Lab 9
