module cal_e (input div_en, input i_clk, input i_rst, input [191:0]h_column, input [19:0]Rii, output reg [191:0]e, output reg e_valid);
    reg         div_en_r;
    wire        div_0[7:0];
    wire[33:0]  Q[7:0];
    wire[19:0]  R[7:0];
    wire[23:0]  h_re[3:0], h_im[3:0];
    assign {h_im[3], h_re[3], h_im[2], h_re[2], h_im[1], h_re[1], h_im[0], h_re[0]} = h_column;
    DW_div_pipe_inst divh1_re(i_clk, ~i_rst, div_en, {h_re[0], 16'b0}, Rii, Q[0], R[0], div_0[0]);
    DW_div_pipe_inst divh1_im(i_clk, ~i_rst, div_en, {h_im[0], 16'b0}, Rii, Q[1], R[1], div_0[1]);
    DW_div_pipe_inst divh2_re(i_clk, ~i_rst, div_en, {h_re[1], 16'b0}, Rii, Q[2], R[2], div_0[2]);
    DW_div_pipe_inst divh2_im(i_clk, ~i_rst, div_en, {h_im[1], 16'b0}, Rii, Q[3], R[3], div_0[3]);
    DW_div_pipe_inst divh3_re(i_clk, ~i_rst, div_en, {h_re[2], 16'b0}, Rii, Q[4], R[4], div_0[4]);
    DW_div_pipe_inst divh3_im(i_clk, ~i_rst, div_en, {h_im[2], 16'b0}, Rii, Q[5], R[5], div_0[5]);
    DW_div_pipe_inst divh4_re(i_clk, ~i_rst, div_en, {h_re[3], 16'b0}, Rii, Q[6], R[6], div_0[6]);
    DW_div_pipe_inst divh4_im(i_clk, ~i_rst, div_en, {h_im[3], 16'b0}, Rii, Q[7], R[7], div_0[7]);
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            e <= 0;
            e_valid <= 0;
            div_en_r <= 0;
        end else begin
            e <= {Q[7][23:0], Q[6][23:0], Q[5][23:0], Q[4][23:0], Q[3][23:0], Q[2][23:0], Q[1][23:0], Q[0][23:0]};
            e_valid <= div_en_r;
            div_en_r <= div_en;
        end
    end 
endmodule

module DW_div_pipe_inst(inst_clk, inst_rst_n, inst_en, inst_a, inst_b, quotient_inst, remainder_inst, divide_by_0_inst );
    parameter inst_a_width = 40;
    parameter inst_b_width = 20;
    parameter inst_tc_mode = 1;
    parameter inst_rem_mode = 1;
    parameter inst_num_stages = 2;
    parameter inst_stall_mode = 1;
    parameter inst_rst_mode = 1;
    parameter inst_op_iso_mode = 0;
    input inst_clk;
    input inst_rst_n;
    input inst_en;
    input [inst_a_width-1 : 0] inst_a;
    input [inst_b_width-1 : 0] inst_b;
    output [33 : 0] quotient_inst;
	
	wire  [39:0] quotient_inst_;
	assign quotient_inst = quotient_inst_[33:0] ;
	
    output [inst_b_width-1 : 0] remainder_inst;
    output divide_by_0_inst;
    DW_div_pipe #(inst_a_width,   inst_b_width,   inst_tc_mode,  inst_rem_mode, inst_num_stages,   inst_stall_mode,   inst_rst_mode,   inst_op_iso_mode) 
    U1 (.clk(inst_clk),   .rst_n(inst_rst_n),   .en(inst_en), .a(inst_a),   .b(inst_b),   .quotient(quotient_inst_), .remainder(remainder_inst),   .divide_by_0(divide_by_0_inst) );
endmodule
