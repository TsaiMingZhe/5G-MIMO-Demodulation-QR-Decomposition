module cal_inner (input inner_en, input i_clk, input i_rst, input [191:0]e, input [191:0]h, output reg [39:0]Rij);
    integer i;
    wire[23:0]  a[3:0], b[3:0];//s7.16
    wire[23:0]  c[3:0], d[3:0];//s1.22
    reg [47:0]  Rij_Re, Rij_Im;
    reg [47:0]  amcd[3:0], dmab[3:0], cmba[3:0], Re[3:0], Im[3:0];//s4.28
    assign {b[3], a[3], b[2], a[2], b[1], a[1], b[0], a[0]} = e;
    assign {d[3], c[3], d[2], c[2], d[1], c[1], d[0], c[0]} = h;
    always @(*) begin
        for (i = 0;i < 4;i = i + 1) begin
            amcd[i] = $signed(a[i]) * $signed($signed(c[i]) - $signed(d[i]));//s9.38
            dmab[i] = $signed(d[i]) * $signed($signed(a[i]) + $signed(b[i]));
            cmba[i] = $signed(c[i]) * $signed($signed(a[i]) - $signed(b[i]));
            Re[i] = $signed(amcd[i]) + $signed(dmab[i]);
            Im[i] = $signed(cmba[i]) - $signed(amcd[i]);
        end
        Rij_Re = Re[0] + Re[1] + Re[2] + Re[3];
        Rij_Im = Im[0] + Im[1] + Im[2] + Im[3];
    end
    always @(posedge i_clk or posedge i_rst) begin
        Rij <= (i_rst) ? 0 : {Rij_Im[47:28] + Rij_Im[27], Rij_Re[47:28] + Rij_Re[27]};
    end 
endmodule
