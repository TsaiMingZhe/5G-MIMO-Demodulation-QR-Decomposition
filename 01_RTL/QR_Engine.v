`timescale 1ns/1ps
module QR_Engine (input i_clk, input i_rst, input i_trig, input [47:0]i_data, output o_rd_vld, output o_last_data, output [159:0]o_y_hat, output [319:0]o_r);
    reg         o_rd_vld_r, o_rd_vld_w, o_last_data_r;
    reg [319:0] o_r_r;
////state & counter
    integer i;
    reg [2:0]   state, next_state;
    reg [3:0]   loadh_cnt, out10_cnt;
    reg [7:0]	load200_cnt;
    reg [4:0]   cal20_cnt;
    reg [47:0]  Y[3:0];
    reg [39:0]  y_hat_reg[3:0];
    reg [191:0] h_reg[1:0], h_reg_w, in_pj_reg, Y_reg;
    reg [19:0]  Rii_reg[3:0];
    reg [39:0]  Rij_reg[5:0];
////enable
    reg		    y_en, Rij_valid;
    wire        cal_en;
    wire 	    finish_flag;//test
    assign finish_flag = (state == `last_trig) & (out10_cnt == 10);
////H write to register
    wire [47:0] element[3:0];
    wire        wen[3:0];
    assign wen[0] = (state == `load_h) & ~loadh_cnt[3] & ~loadh_cnt[2];
    assign wen[1] = (state == `load_h) & ~loadh_cnt[3] & loadh_cnt[2];
    assign wen[2] = (state == `load_h) & loadh_cnt[3] & ~loadh_cnt[2];
    assign wen[3] = (state == `load_h) & loadh_cnt[3] & loadh_cnt[2];
    Register row1(i_clk, i_rst, wen[0], loadh_cnt[1:0], i_data, element[0]);
    Register row2(i_clk, i_rst, wen[1], loadh_cnt[1:0], i_data, element[1]);
    Register row3(i_clk, i_rst, wen[2], loadh_cnt[1:0], i_data, element[2]);
    Register row4(i_clk, i_rst, wen[3], loadh_cnt[1:0], i_data, element[3]);
////submodule
    wire         Rii_valid, e_valid;
    wire [191:0] e;
    wire [191:0] column, o_proj;
    wire [39:0]  Rij, y_hat;
    wire [19:0]  Rii;
    assign cal_en = &loadh_cnt & (state !=`last_trig);
    assign column = (cal20_cnt > 5) ? o_proj : {element[3], element[2], element[1], element[0]};
    cal_Rii rii(cal_en, i_clk, i_rst, cal20_cnt,  column, Rii, Rii_valid);
    cal_e ex(Rii_valid, i_clk, i_rst, h_reg[1], Rii, e, e_valid);
    cal_inner eh(e_valid, i_clk, i_rst, e, h_reg[1], Rij);
    projection pj(i_clk, i_rst, in_pj_reg, e, Rij, o_proj);
    cal_yhat yprocess(y_en, i_clk, i_rst, e, Y_reg, y_hat);
////output assign
    assign o_rd_vld = o_rd_vld_r;
    assign o_last_data = o_last_data_r;
    assign o_y_hat = {y_hat_reg[3], y_hat_reg[2], y_hat_reg[1], y_hat_reg[0]};
    assign o_r = {o_r_r[79:60], o_r_r[319:240], o_r_r[199:160], o_r_r[59:40], o_r_r[239:200], o_r_r[159:120], o_r_r[39:20], o_r_r[119:80], o_r_r[19:0]};
////always block
    always @(*) begin//FSM
        case (state)
            `init : next_state = `load_h;
            `load_h : next_state = (&loadh_cnt[1:0]) ? `load_y : `load_h;
            `load_y : next_state = (load200_cnt == 199) ? `last_trig : `load_h;
	        `last_trig : next_state = (finish_flag) ? `init : `last_trig;
            default : next_state = state; 
        endcase
    end
    always @(*) begin
	o_rd_vld_w = (|load200_cnt[7:5]) & (cal20_cnt == 7);
        case (cal20_cnt)
            0, 2, 3, 4 : h_reg_w = column;
            6, 7, 8, 12, 13, 18 : h_reg_w = o_proj;
            default : h_reg_w = h_reg[0];
        endcase
        case (cal20_cnt)
	        1 : y_en = (load200_cnt > 20);
            1, 3, 9, 15 : y_en = 1;
            default : y_en = 0;
        endcase
        case (cal20_cnt)
            5, 6, 7, 11, 12, 17 : Rij_valid = 1; 
            default : Rij_valid = 0;
        endcase
    end
    always @(posedge i_clk or posedge i_rst) begin //counter
        if (i_rst) begin
	        load200_cnt <= 0;
            loadh_cnt <= 0;
            cal20_cnt <= 0;
	    out10_cnt <= 0;
        end else begin
	        load200_cnt <= (state == `init) ? 0 : load200_cnt + 1;
            loadh_cnt <= (state == `load_h | state == `last_trig) ? loadh_cnt + 1 : (state == `init) ? 0 : loadh_cnt;
            cal20_cnt <= (load200_cnt < 18) ? 0 : (cal_en | cal20_cnt == 19) ? 0 : (o_last_data_r) ? 0 : cal20_cnt + 1;
	    out10_cnt <= (state == `init) ? 0 : (o_rd_vld_w) ? out10_cnt + 1 : out10_cnt;
        end
    end
    always @(posedge i_clk or posedge i_rst) begin//state, output, data register
        if (i_rst) begin
            state <= `init;
            o_rd_vld_r <= 0;
            o_last_data_r <= 0;
            o_r_r <= 0;
            h_reg[0] <= 0;          h_reg[1] <= 0;
	        in_pj_reg <= 0;
	        Y_reg <= 0;
	        for (i = 0;i < 4;i = i + 1) begin 
                y_hat_reg[i] <= 0;
                Y[i] <= 0;
                Rii_reg[i] <= 0;
            end
            for (i = 0;i < 6;i = i + 1) Rij_reg[i] <= 0;
        end else begin
            state <= next_state;
            o_rd_vld_r <= o_rd_vld_w;
            o_last_data_r <= finish_flag;
            o_r_r[79:0] <= (cal20_cnt == 1) ? {Rii_reg[3], Rii_reg[2], Rii_reg[1], Rii_reg[0]} : o_r_r[79:0];//Rii store
            o_r_r[319:80] <= (cal20_cnt == 18) ? {Rij_reg[5], Rij_reg[4], Rij_reg[3], Rij_reg[2], Rij_reg[1], Rij_reg[0]} : o_r_r[319:80];//Rij store
            Y[3] <= (state == `load_y) ? i_data : Y[3];
            for (i = 1;i < 4;i = i + 1) Y[i-1] <= (state == `load_y) ? Y[i] : Y[i-1];
            h_reg[0] <= h_reg_w;    h_reg[1] <= (cal20_cnt == 9) ? h_reg[1] : h_reg[0];
            case (cal20_cnt)
                4, 5, 6, 10, 11, 16 : in_pj_reg <= h_reg[1];
                default : in_pj_reg <= in_pj_reg;
            endcase
            case (cal20_cnt) 
                0 : begin
                    if (load200_cnt > 25) begin
                        y_hat_reg[3] <= y_hat;          y_hat_reg[2] <= y_hat_reg[3];
                        y_hat_reg[1] <= y_hat_reg[2];   y_hat_reg[0] <= y_hat_reg[1];
                    end else begin
                        y_hat_reg[3] <= y_hat_reg[3];   y_hat_reg[2] <= y_hat_reg[2];
                        y_hat_reg[1] <= y_hat_reg[1];   y_hat_reg[0] <= y_hat_reg[0];
                    end
                end
                6 : begin
                    if (load200_cnt > 25) begin
                        y_hat_reg[3] <= y_hat;          y_hat_reg[2] <= y_hat_reg[3];
                        y_hat_reg[1] <= y_hat_reg[2];   y_hat_reg[0] <= y_hat_reg[1];
                    end else begin
                        y_hat_reg[3] <= y_hat_reg[3];   y_hat_reg[2] <= y_hat_reg[2];
                        y_hat_reg[1] <= y_hat_reg[1];   y_hat_reg[0] <= y_hat_reg[0];
                    end
                end
                8, 14 : begin
                        y_hat_reg[3] <= y_hat;          y_hat_reg[2] <= y_hat_reg[3];
                        y_hat_reg[1] <= y_hat_reg[2];   y_hat_reg[0] <= y_hat_reg[1];
                end
                default : begin
                        y_hat_reg[3] <= y_hat_reg[3];   y_hat_reg[2] <= y_hat_reg[2];
                        y_hat_reg[1] <= y_hat_reg[1];   y_hat_reg[0] <= y_hat_reg[0];
                end
            endcase
            if (Rii_valid) begin
                Rii_reg[3] <= Rii;   Rii_reg[2] <= Rii_reg[3];   Rii_reg[1] <= Rii_reg[2];   Rii_reg[0] <= Rii_reg[1];
            end else begin
                Rii_reg[3] <= Rii_reg[3];   Rii_reg[2] <= Rii_reg[2];   Rii_reg[1] <= Rii_reg[1];   Rii_reg[0] <= Rii_reg[0];
            end
            if (Rij_valid) begin
                Rij_reg[5] <= Rij;
                for (i = 1;i < 6;i = i + 1) Rij_reg[i-1] <= Rij_reg[i];
            end else begin
                for (i = 0;i < 6;i = i + 1) Rij_reg[i] <= Rij_reg[i];
            end
            Y_reg <= (cal20_cnt == 3) ? {Y[3], Y[2], Y[1], Y[0]} : Y_reg;
        end
    end
endmodule
