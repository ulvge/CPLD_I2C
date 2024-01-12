module check_1hz(
    clk,
    rst_l,
    in,
    out);
    
	 parameter COUNT_WIDTH = 12;
	 parameter COUNT_MAX = 800;
    input clk;
    input rst_l;
    input in;
    output out;
    
    reg out;

    reg [COUNT_WIDTH-1:0] count_low;
    reg [COUNT_WIDTH-1:0] count_hi;

    always @(posedge clk or negedge rst_l)
    if(~rst_l) begin
        count_hi[COUNT_WIDTH-1:0] = COUNT_MAX;
        count_low[COUNT_WIDTH-1:0] = COUNT_MAX;
    end
    else begin
        if (in == 1) begin
            count_low[COUNT_WIDTH-1:0] = 0;
            count_hi[COUNT_WIDTH-1:0] = count_hi[COUNT_WIDTH-1:0] < COUNT_MAX ? 
                                                count_hi[COUNT_WIDTH-1:0]+1 : count_hi[COUNT_WIDTH-1:0];
        end
        else begin
            count_low[COUNT_WIDTH-1:0] = count_low[COUNT_WIDTH-1:0] < COUNT_MAX ? 
                                                count_low[COUNT_WIDTH-1:0]+1 : count_low[COUNT_WIDTH-1:0];
            count_hi[COUNT_WIDTH-1:0] = 0;
        end
    end

    always @(posedge clk)
    if ((count_low[COUNT_WIDTH-1:0] < COUNT_MAX) && (count_hi[COUNT_WIDTH-1:0] < COUNT_MAX)) begin
        out <= 1'b1;
    end
    else begin
        out <= 1'b0;
    end


endmodule