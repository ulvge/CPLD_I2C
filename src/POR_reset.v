
// COUNT，如果in为1，则增加计数器，计数器达到最大值之前，一直输出低。达到最大值后，输出高。
module POR_RESET(
    clk,
    rst_l,
    in,
    out);
    
	 parameter COUNT_WIDTH = 24;
	 //parameter COUNT_MAX =  1000000; // 20ms
	 parameter COUNT_MAX =  5000000; // 100ms
    input clk;
    input rst_l;
    input in;
    output out;
    
    reg out;

    reg [COUNT_WIDTH-1:0] count;

    always @(posedge clk or negedge rst_l)
    if(~rst_l) begin
        count[COUNT_WIDTH-1:0] = COUNT_MAX;
    end
    else begin
        if (in == 1) begin
            count[COUNT_WIDTH-1:0] = 0;
        end
        else begin
            count[COUNT_WIDTH-1:0] = count[COUNT_WIDTH-1:0] < COUNT_MAX ? 
                                                count[COUNT_WIDTH-1:0]+1 : count[COUNT_WIDTH-1:0];
        end
    end

    always @(posedge clk)
    if (count[COUNT_WIDTH-1:0] < COUNT_MAX) begin
        out <= 1'b0;
    end
    else begin
        out <= 1'b1;
    end


endmodule