module projection (input i_clk, input i_rst, input [191:0]in_h, input [191:0]e, input [39:0]Rij, output reg [191:0]out_h);
    integer i;
    wire[19:0]  c, d;
    wire[23:0]  a[3:0], b[3:0];
    wire[23:0]  h[7:0];
    reg [47:0]  row_Im[3:0], row_Re[3:0];//s5.22
    reg [47:0]  amcd[3:0], dmab[3:0], cmba[3:0];
    reg [47:0]  Re[3:0], Im[3:0];
    assign {h[7], h[6], h[5], h[4], h[3], h[2], h[1], h[0]} = in_h;//s1.22
    assign {b[3], a[3], b[2], a[2], b[1], a[1], b[0], a[0]} = e;//s7.16
    assign {d, c} = Rij;//s3.16, s3.16
    always @(*) begin
        for (i = 0;i < 4;i = i + 1) begin
            amcd[i] = $signed(a[i]) * $signed($signed(c) - $signed(d));     //s9.38
            dmab[i] = $signed(d) * $signed($signed(a[i]) - $signed(b[i]));  
            cmba[i] = $signed(c) * $signed($signed(a[i]) + $signed(b[i]));  
            Re[i] = $signed(amcd[i]) + $signed(dmab[i]);                    
            Im[i] = $signed(cmba[i]) - $signed(amcd[i]);                    
        end
        row_Re[0] = $signed({{8{h[0][23]}}, h[0], 16'b0}) - $signed(Re[0]);//{8, s1.22, 16} - s9.38
        row_Im[0] = $signed({{8{h[1][23]}}, h[1], 16'b0}) - $signed(Im[0]); 
        row_Re[1] = $signed({{8{h[2][23]}}, h[2], 16'b0}) - $signed(Re[1]);
        row_Im[1] = $signed({{8{h[3][23]}}, h[3], 16'b0}) - $signed(Im[1]);
        row_Re[2] = $signed({{8{h[4][23]}}, h[4], 16'b0}) - $signed(Re[2]);
        row_Im[2] = $signed({{8{h[5][23]}}, h[5], 16'b0}) - $signed(Im[2]);
        row_Re[3] = $signed({{8{h[6][23]}}, h[6], 16'b0}) - $signed(Re[3]);
        row_Im[3] = $signed({{8{h[7][23]}}, h[7], 16'b0}) - $signed(Im[3]); 
    end
    always @(posedge i_clk or posedge i_rst) begin
        out_h <= (i_rst) ? 0 : {row_Im[3][39:16], row_Re[3][39:16], 
                                row_Im[2][39:16], row_Re[2][39:16], 
                                row_Im[1][39:16], row_Re[1][39:16], 
                                row_Im[0][39:16], row_Re[0][39:16]};
    end
endmodule
