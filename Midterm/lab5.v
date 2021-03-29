`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab5(
    input clk,
    input reset_n,
    input [3:0] usr_btn,
    output [3:0] usr_led,
    output LCD_RS,
    output LCD_RW,
    output LCD_E,
    output [3:0] LCD_D
);

localparam [2:0] S_INIT = 0,
                 S_ASK1 = 1,
                 S_INP1 = 2,
                 S_ASK2 = 3,
                 S_INP2 = 4,
                 S_LENG = 5,
                 S_SHOW = 6;

wire [3:0] btn;
wire [127:0] wirA, wirB1, wirB2;
wire [127:0] row_A, row_B;
reg [127:0] inpA;
reg [127:0] regA = "welcome! 0816146"; // Initialize the text of the first row. 
reg [127:0] regB = "Press btn3 start"; // Initialize the text of the second row.
reg [0:8*72-1] str0 = "0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz";  // 0-9 + a-z + repeat at least 15 char
reg [0:8*32-1] str1, str2;
reg [5:0] cptr, dptr1, dptr2;
reg [2:0] P, P_next;
reg [6:0] cnt;
wire clearB;

assign usr_led = {^cptr, ^dptr1, ^dptr2, ^regB};

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

assign row_A = regA;
assign row_B = regB;

debounce btn_db0(.clk(clk), .btn_input(usr_btn[0]), .btn_output(btn[0]));
debounce btn_db1(.clk(clk), .btn_input(usr_btn[1]), .btn_output(btn[1]));
debounce btn_db2(.clk(clk), .btn_input(usr_btn[2]), .btn_output(btn[2]));
debounce btn_db3(.clk(clk), .btn_input(usr_btn[3]), .btn_output(btn[3]));

mB mB1(.clear(clearB), .cnt(cnt), .str(str1), .dptr(dptr1), .wirB(wirB1));
mB mB2(.clear(clearB), .cnt(cnt), .str(str2), .dptr(dptr2), .wirB(wirB2));

assign clearB = (P == S_ASK1 || P == S_ASK2);


always @(posedge clk) begin
  if (~reset_n) P <= S_INIT;
  else P <= P_next;
end

// FSM next-state logic
always @(posedge btn[3], negedge reset_n) begin
    if (~reset_n)
        P_next <= S_INIT;
    else case (P)
        S_INIT: P_next <= S_ASK1;
        S_ASK1: P_next <= S_INP1;
        S_INP1: P_next <= S_ASK2;
        S_ASK2: P_next <= S_INP2;
        S_INP2: P_next <= S_LENG;
        S_LENG: P_next <= S_SHOW;
        S_SHOW: P_next <= S_ASK1;
    endcase
end

// LCD Text
always @(posedge clk) begin
    case (P)
        S_INIT: begin
            regA <= "welcome! 0816146";
            regB <= "Press btn3 start";
        end
        
        S_ASK1: begin
            regA <= "press btn 3 to  ";
            regB <= "enter string #1 ";
        end
        S_ASK2: begin
            regA <= "press btn 3 to  ";
            regB <= "enter string #2 ";
        end
        
        S_INP1: begin
            regA <= wirA;
            regB <= wirB1;
        end
        S_INP2: begin
            regA <= wirA;
            regB <= wirB2;
        end

        S_LENG: begin
            regA <= "The length of   ";
            regB <= "LCS = 0x3       ";
        end
        S_SHOW: begin
            regA <= "The LCS is      ";
            regB <= "Lorem ipsum.    ";
        end
    endcase
end

// Button control, scrolling and choose
always @(posedge clk) begin
    if (P == S_ASK1) begin
        cptr <= 0;
        dptr1 <= 0;
    end else if (P == S_ASK2) begin
        cptr <= 0;
        dptr2 <= 0;
    end else begin
        if (btn[2]) begin
            if (cptr == 10 + 26)
                cptr <= 0;
            else
                cptr <= cptr + 1;
        end else if (btn[0]) begin
            if (cptr == 0)
                cptr <= 10 + 26 - 1;
            else
                cptr <= cptr - 1;
        end else if (btn[1]) begin
            if (P == S_INP1)
                dptr1 <= dptr1 + 1;
            if (P == S_INP2)
                dptr2 <= dptr2 + 1;
        end else begin
            if (P == S_INP1)
                str1[dptr1*8 + 8 + (cnt%8)] <= str0[cptr*8 + (cnt%8)];
            if (P == S_INP2)
                str2[dptr2*8 + 8 + (cnt%8)] <= str0[cptr*8 + (cnt%8)];
        end
    end
end

always @(posedge clk) begin
    cnt <= cnt + 1;
end

always @(posedge clk) begin
    inpA[cnt] <= str0[(36-15)*8 + cptr*8 + 127 - cnt];
end

assign wirA = inpA;

endmodule  // This lab


module mB(
    input clear,
    input  [6:0]   cnt,
    input  [0:8*32-1] str,
    input  [5:0]   dptr,
    output [127:0] wirB);
    
    reg [127:0] regB = "HeyThere       ^";
    
    assign wirB = regB;
    
    always @(cnt) begin
        if (clear)
            regB <= "               ^";
        else if (dptr == 0) begin
            // DUNNO
        end else if (dptr < 8) begin
            regB[128 - dptr*8 + (cnt%(dptr*8))] <= str[dptr*8-1 - (cnt%(dptr*8))];
        end else begin
            regB[64           + (cnt%64)]       <= str[dptr*8-1 - (cnt%64)];
        end
    end
endmodule


module debounce(
    input clk,
    input btn_input,
    output btn_output
    );

    reg [23:0] cnt = 24'h000000;
    reg sig  = 0;
    reg prev = 0;

    assign btn_output = sig;

    always @(posedge clk) begin
        if (sig == 1) begin
            sig <= 0;
            prev <= 1;
        end else if (~prev && cnt == 24'haabbcc)
            sig <= 1;
        else if (prev && cnt == 0)
            prev <= 0;
        else if ( btn_input && ~prev)
            cnt <= cnt + 1;
        else if (~btn_input && cnt)
            cnt <= cnt - 1;
    end
endmodule