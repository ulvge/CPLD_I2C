module delay_deglitch(
    clk,
    rst_l,
    in,
    out);
    
	 parameter COUNT_WIDTH = 16;
	 
    input clk;
    input rst_l;
    input in;
    output out;
    
    reg in_stage1, in_stage2, in_stage3, in_stage4, in_stage5;
    reg out;
    
    //register 5 stages;
    always @(posedge clk or negedge rst_l)
    if(~rst_l)
    	in_stage1 <= 1'b1;
    else
    	in_stage1 <= in;
    
    always @(posedge clk or negedge rst_l)
    if(~rst_l)
    	in_stage2 <= 1'b1;
    else
    	in_stage2 <= in_stage1;
    	
    always @(posedge clk or negedge rst_l)
    if(~rst_l)
    	in_stage3 <= 1'b1;
    else
    	in_stage3 <= in_stage2;
    
    always @(posedge clk or negedge rst_l)
    if(~rst_l)
    	in_stage4 <= 1'b1;
    else
    	in_stage4 <= in_stage3;
    
    always @(posedge clk or negedge rst_l)
    if(~rst_l)
    	in_stage5 <= 1'b1;
    else
    	in_stage5 <= in_stage4;

    //delay_timer
    reg [COUNT_WIDTH-1:0] delay_count_q;
    
    //1复位时，in_stage5=1，out=1;所以^,delay_count_run=0;  只要in_stage5恢复到0，立马重新赋值16'hffff
    //2经过几个clk传递后，in_stage5=0，out，还是之前复位时的值=1;所以^,delay_count_run=1
    wire delay_count_run = in_stage5 ^ out;
    
    //1复位时，delay_count_run=0;delay_count_d = 16'hffff
    //2delay_count_run=1;此时delay_count_q 开始--
    //ffff 65,535/ 50M = 1.3ms
    wire [COUNT_WIDTH-1:0] delay_count_d = (delay_count_run? delay_count_q[COUNT_WIDTH-1:0] - 1'b1 : 16'hffff);
    
    always @(posedge clk or negedge rst_l)
    if(~rst_l)
    	delay_count_q <= 0;
    else
    	delay_count_q <= delay_count_d;
    
    //out regisger
    //3 delay_count_q-- == 0时，输出去抖之后的in_stage5;否则，保持out(复位时的值)
    wire out_d = (delay_count_d[COUNT_WIDTH-1:0] == 0)? in_stage5 : out;
    
    always @(posedge clk or negedge rst_l)
    if(~rst_l)
    	out <= 1'b1;
    else
    	out <= out_d;
    
endmodule