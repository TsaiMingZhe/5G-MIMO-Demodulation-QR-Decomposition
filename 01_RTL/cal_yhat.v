module cal_yhat (input en, input i_clk, input i_rst, input [191:0]e, input [191:0]y, output reg [39:0]y_hat);
    reg		    add_en;
    reg [1:0]   state, next_state;
    reg [47:0]  mult1_a, mult1_b, mult2_a, mult2_b;
    reg [99:0]  o_mult1, o_mult2, sum;
    wire[99:0]  o_inn1, o_inn2, sum_m1m2;

    inner_product_H innY1(mult1_a, mult1_b, o_inn1);
    inner_product_H innY2(mult2_a, mult2_b, o_inn2);
    assign sum_m1m2 = {o_mult1[99:50] + o_mult2[99:50], o_mult1[49:0] + o_mult2[49:0]};
    always @(*) begin
        case (state)
            `idle : next_state = (en) ? `mult_QY_1 : `idle;
            `mult_QY_1 : next_state = `mult_QY_2;
            `mult_QY_2 : next_state = (en) ? `mult_QY_1 : `idle;
            default : next_state = state;
        endcase        
    end
    always @(*) begin
        case (state)
            `mult_QY_1 : begin 
                mult1_a = e[47:0];    mult1_b = y[47:0];
                mult2_a = e[95:48];   mult2_b = y[95:48];
            end
            `mult_QY_2 : begin
                mult1_a = e[143:96];    mult1_b = y[143:96];
                mult2_a = e[191:144];   mult2_b = y[191:144];                
            end
            default : begin
                mult1_a = 0;   mult1_b = 0;
                mult2_a = 0;   mult2_b = 0;                 
            end
        endcase
    end
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= `idle;
            sum <= 0;
            o_mult1 <= 0;
            o_mult2 <= 0;
	        add_en <= 0;
	    y_hat <= 0;
        end else begin
            state <= next_state;
            sum <= (state == `mult_QY_2) ? sum_m1m2: (add_en) ? {sum[99:50] + sum_m1m2[99:50], sum[49:0] + sum_m1m2[49:0]} : sum;
            o_mult1 <= o_inn1;
            o_mult2 <= o_inn2;
	        add_en <= (state == `mult_QY_2);
	        y_hat <= {sum[97:78] + sum[77], sum[47:28] + sum[27]};
        end
    end
endmodule

module inner_product_H (input [47:0]i_data1, input [47:0]i_data2, output [99:0]o_data);//in1 = e in2 = h
    wire signed [23:0]      a, b, c, d;
    wire signed [48:0]      amcd, dmab, cmba;
	wire signed [24:0] cd, ab, ba;
	wire signed [49:0]  Re, Im;

    assign {b, a} = i_data1;
    assign {d, c} = i_data2;
    assign amcd = a * cd;
    assign dmab = d*ab;
    assign cmba = c*ba;
	assign cd = c-d;
    assign ab = a+b;
    assign ba = a-b;
    assign Re = amcd + dmab;
    assign Im = cmba - amcd;
    assign o_data = {Im, Re};
	

endmodule
