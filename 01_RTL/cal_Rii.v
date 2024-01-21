module cal_Rii (input cal_en, input i_clk, input i_rst, input [4:0]cal20_cnt, input [191:0]h_column, output reg [19:0]Rii, output reg Rii_valid);
    reg         next_iter;
    reg [1:0]   state, next_state;
    wire[47:0]  sum[3:0];
    wire[51:0]  total;
    wire[25:0]  o_sqrt;
    wire[23:0]  h_im[3:0], h_re[3:0];
    assign {h_im[3], h_re[3], h_im[2], h_re[2], h_im[1], h_re[1], h_im[0], h_re[0]} = h_column;
    assign sum[0] = ($signed(h_im[0]) * $signed(h_im[0])) + ($signed(h_re[0]) * $signed(h_re[0]));//4.44
    assign sum[1] = ($signed(h_im[1]) * $signed(h_im[1])) + ($signed(h_re[1]) * $signed(h_re[1]));//4.44
    assign sum[2] = ($signed(h_im[2]) * $signed(h_im[2])) + ($signed(h_re[2]) * $signed(h_re[2]));//4.44 
    assign sum[3] = ($signed(h_im[3]) * $signed(h_im[3])) + ($signed(h_re[3]) * $signed(h_re[3]));//4.44
    assign total = sum[0] + sum[1] + sum[2] + sum[3];//8.44
    DW_sqrt_pipe_inst sqrt(i_clk, ~i_rst, (state == `root1), total, o_sqrt);//4.22
    always @(*) begin
        case (state) 
            `idle : next_state = (cal_en | next_iter) ? `root1 : `idle;
            `root1 : next_state = `root2;
	        `root2 : next_state = (cal_en) ? `root1 : `idle;
	        default : next_state = state;
        endcase
        case (cal20_cnt)
            5, 11, 17 : next_iter = 1;
            default : next_iter = 0;
        endcase
    end
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)begin
            state <= `idle;
            Rii <= 0;
            Rii_valid <= 0;
        end else begin
            state <= next_state;
            Rii <= (state == `root2) ? o_sqrt[25:6] + o_sqrt[5] : Rii;
            Rii_valid <= (state == `root2);
        end
    end
endmodule
module DW_sqrt_pipe_inst( inst_clk, inst_rst_n, inst_en, inst_a, root_inst );
    parameter inst_width = 52;
    parameter inst_tc_mode = 1;
    parameter inst_num_stages = 2;
    parameter inst_stall_mode = 1;
    parameter inst_rst_mode = 1;
    parameter inst_op_iso_mode = 0;
    input inst_clk;
    input inst_rst_n;
    input inst_en;
    input [inst_width-1 : 0] inst_a;
    output [(inst_width+1)/2-1 : 0] root_inst;
    DW_sqrt_pipe #(inst_width, inst_tc_mode, inst_num_stages, inst_stall_mode, inst_rst_mode, inst_op_iso_mode) 
    U1 (.clk(inst_clk),   .rst_n(inst_rst_n), .en(inst_en),   .a(inst_a),   .root(root_inst) );
endmodule
