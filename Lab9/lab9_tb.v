`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module lab9_tb();

reg  sys_clk = 0;
reg  reset = 0;
/*
reg  [3:0] btn = 4'b0;
wire [3:0] led = 4'b0;
wire LCD_RS, LCD_RW, LCD_E;
wire [3:0] LCD_D;
*/
reg  [0: 63] in_txt = "00000000";
wire [0:127] hash;
wire [0: 63] out_txt;

md5 uut(
    .clk(sys_clk),
    .in_txt(in_txt),
    .hash(hash),
    .out_txt(out_txt)
);


wire [0:31]              A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38, A39, A40, A41, A42, A43, A44, A45, A46, A47, A48, A49, A50, A51, A52, A53, A54, A55, A56, A57, A58, A59, A60, A61, A62, A63;
wire [0:31]  B0, B1, B2, B3, B4, B5, B6, B7, B8, B9, B10, B11, B12, B13, B14, B15, B16, B17, B18, B19, B20, B21, B22, B23, B24, B25, B26, B27, B28, B29, B30, B31, B32, B33, B34, B35, B36, B37, B38, B39, B40, B41, B42, B43, B44, B45, B46, B47, B48, B49, B50, B51, B52, B53, B54, B55, B56, B57, B58, B59, B60, B61, B62, B63;
wire [0:31]      C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16, C17, C18, C19, C20, C21, C22, C23, C24, C25, C26, C27, C28, C29, C30, C31, C32, C33, C34, C35, C36, C37, C38, C39, C40, C41, C42, C43, C44, C45, C46, C47, C48, C49, C50, C51, C52, C53, C54, C55, C56, C57, C58, C59, C60, C61, C62, C63;
wire [0:31]          D2, D3, D4, D5, D6, D7, D8, D9, D10, D11, D12, D13, D14, D15, D16, D17, D18, D19, D20, D21, D22, D23, D24, D25, D26, D27, D28, D29, D30, D31, D32, D33, D34, D35, D36, D37, D38, D39, D40, D41, D42, D43, D44, D45, D46, D47, D48, D49, D50, D51, D52, D53, D54, D55, D56, D57, D58, D59, D60, D61, D62, D63;
wire [0:63]  w,  w0, w1, w2, w3;

assign                                   A3=uut.A3, A4=uut.A4, A5=uut.A5, A6=uut.A6, A7=uut.A7, A8=uut.A8, A9=uut.A9, A10=uut.A10, A11=uut.A11, A12=uut.A12, A13=uut.A13, A14=uut.A14, A15=uut.A15, A16=uut.A16, A17=uut.A17, A18=uut.A18, A19=uut.A19, A20=uut.A20, A21=uut.A21, A22=uut.A22, A23=uut.A23, A24=uut.A24, A25=uut.A25, A26=uut.A26, A27=uut.A27, A28=uut.A28, A29=uut.A29, A30=uut.A30, A31=uut.A31, A32=uut.A32, A33=uut.A33, A34=uut.A34, A35=uut.A35, A36=uut.A36, A37=uut.A37, A38=uut.A38, A39=uut.A39, A40=uut.A40, A41=uut.A41, A42=uut.A42, A43=uut.A43, A44=uut.A44, A45=uut.A45, A46=uut.A46, A47=uut.A47, A48=uut.A48, A49=uut.A49, A50=uut.A50, A51=uut.A51, A52=uut.A52, A53=uut.A53, A54=uut.A54, A55=uut.A55, A56=uut.A56, A57=uut.A57, A58=uut.A58, A59=uut.A59, A60=uut.A60, A61=uut.A61, A62=uut.A62, A63=uut.A63;
assign  B0=uut.B0, B1=uut.B1, B2=uut.B2, B3=uut.B3, B4=uut.B4, B5=uut.B5, B6=uut.B6, B7=uut.B7, B8=uut.B8, B9=uut.B9, B10=uut.B10, B11=uut.B11, B12=uut.B12, B13=uut.B13, B14=uut.B14, B15=uut.B15, B16=uut.B16, B17=uut.B17, B18=uut.B18, B19=uut.B19, B20=uut.B20, B21=uut.B21, B22=uut.B22, B23=uut.B23, B24=uut.B24, B25=uut.B25, B26=uut.B26, B27=uut.B27, B28=uut.B28, B29=uut.B29, B30=uut.B30, B31=uut.B31, B32=uut.B32, B33=uut.B33, B34=uut.B34, B35=uut.B35, B36=uut.B36, B37=uut.B37, B38=uut.B38, B39=uut.B39, B40=uut.B40, B41=uut.B41, B42=uut.B42, B43=uut.B43, B44=uut.B44, B45=uut.B45, B46=uut.B46, B47=uut.B47, B48=uut.B48, B49=uut.B49, B50=uut.B50, B51=uut.B51, B52=uut.B52, B53=uut.B53, B54=uut.B54, B55=uut.B55, B56=uut.B56, B57=uut.B57, B58=uut.B58, B59=uut.B59, B60=uut.B60, B61=uut.B61, B62=uut.B62, B63=uut.B63;
assign             C1=uut.C1, C2=uut.C2, C3=uut.C3, C4=uut.C4, C5=uut.C5, C6=uut.C6, C7=uut.C7, C8=uut.C8, C9=uut.C9, C10=uut.C10, C11=uut.C11, C12=uut.C12, C13=uut.C13, C14=uut.C14, C15=uut.C15, C16=uut.C16, C17=uut.C17, C18=uut.C18, C19=uut.C19, C20=uut.C20, C21=uut.C21, C22=uut.C22, C23=uut.C23, C24=uut.C24, C25=uut.C25, C26=uut.C26, C27=uut.C27, C28=uut.C28, C29=uut.C29, C30=uut.C30, C31=uut.C31, C32=uut.C32, C33=uut.C33, C34=uut.C34, C35=uut.C35, C36=uut.C36, C37=uut.C37, C38=uut.C38, C39=uut.C39, C40=uut.C40, C41=uut.C41, C42=uut.C42, C43=uut.C43, C44=uut.C44, C45=uut.C45, C46=uut.C46, C47=uut.C47, C48=uut.C48, C49=uut.C49, C50=uut.C50, C51=uut.C51, C52=uut.C52, C53=uut.C53, C54=uut.C54, C55=uut.C55, C56=uut.C56, C57=uut.C57, C58=uut.C58, C59=uut.C59, C60=uut.C60, C61=uut.C61, C62=uut.C62, C63=uut.C63;
assign                        D2=uut.D2, D3=uut.D3, D4=uut.D4, D5=uut.D5, D6=uut.D6, D7=uut.D7, D8=uut.D8, D9=uut.D9, D10=uut.D10, D11=uut.D11, D12=uut.D12, D13=uut.D13, D14=uut.D14, D15=uut.D15, D16=uut.D16, D17=uut.D17, D18=uut.D18, D19=uut.D19, D20=uut.D20, D21=uut.D21, D22=uut.D22, D23=uut.D23, D24=uut.D24, D25=uut.D25, D26=uut.D26, D27=uut.D27, D28=uut.D28, D29=uut.D29, D30=uut.D30, D31=uut.D31, D32=uut.D32, D33=uut.D33, D34=uut.D34, D35=uut.D35, D36=uut.D36, D37=uut.D37, D38=uut.D38, D39=uut.D39, D40=uut.D40, D41=uut.D41, D42=uut.D42, D43=uut.D43, D44=uut.D44, D45=uut.D45, D46=uut.D46, D47=uut.D47, D48=uut.D48, D49=uut.D49, D50=uut.D50, D51=uut.D51, D52=uut.D52, D53=uut.D53, D54=uut.D54, D55=uut.D55, D56=uut.D56, D57=uut.D57, D58=uut.D58, D59=uut.D59, D60=uut.D60, D61=uut.D61, D62=uut.D62, D63=uut.D63;
assign  w =uut.w,  w0=uut.w0, w1=uut.w1, w2=uut.w2, w3=uut.w3;


always
    #4 sys_clk <= ~sys_clk;

always #8
    if (in_txt[56 +: 8] == "9") begin in_txt[56 +: 8] <= "0";
        if (in_txt[48 +: 8] == "9") begin in_txt[48 +: 8] <= "0";
            if (in_txt[40 +: 8] == "9") begin in_txt[40 +: 8] <= "0";
                if (in_txt[32 +: 8] == "9") begin in_txt[32 +: 8] <= "0";
                    if (in_txt[24 +: 8] == "9") begin in_txt[24 +: 8] <= "0";
                        if (in_txt[16 +: 8] == "9") begin in_txt[16 +: 8] <= "0";
                            if (in_txt[8 +: 8] == "9") begin in_txt[8 +: 8] <= "0";
                                if (in_txt[0 +: 8] == "9") begin in_txt[0 +: 8] <= "0";
                                end else in_txt[0 +: 8] <= in_txt[0 +: 8] + 1;
                            end else in_txt[8 +: 8] <= in_txt[8 +: 8] + 1;
                        end else in_txt[16 +: 8] <= in_txt[16 +: 8] + 1;
                    end else in_txt[24 +: 8] <= in_txt[24 +: 8] + 1;
                end else in_txt[32 +: 8] <= in_txt[32 +: 8] + 1;
            end else in_txt[40 +: 8] <= in_txt[40 +: 8] + 1;
        end else in_txt[48 +: 8] <= in_txt[48 +: 8] + 1;
    end else in_txt[56 +: 8] <= in_txt[56 +: 8] + 1;

initial begin
    #2_000_000_000 reset = 1;
    #2_000_000_000 $finish;
end


endmodule
