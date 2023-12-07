module io_deglitch(
    clk,
    rst_l,
    in,
    out);
    
	 parameter COUNT_WIDTH = 3;
	 parameter COUNT_MAX = 2**COUNT_WIDTH-1;
	 parameter COUNT_MIN = 0;
    input clk;
    input rst_l;
    input in;
    output out;
    
    reg out;

    reg [COUNT_WIDTH-1:0] delay_posedge_count;
    reg [COUNT_WIDTH-1:0] delay_negedge_count;

    always @(posedge clk or negedge rst_l)
    if(~rst_l) begin
        delay_negedge_count[COUNT_WIDTH-1:0] = 0;
        delay_posedge_count[COUNT_WIDTH-1:0] = 0;
    end
    else begin
        if (in == 1) begin
            delay_negedge_count[COUNT_WIDTH-1:0] = 0;
            delay_posedge_count[COUNT_WIDTH-1:0] = delay_posedge_count[COUNT_WIDTH-1:0] < COUNT_MAX ? 
                                                delay_posedge_count[COUNT_WIDTH-1:0]+1 : delay_posedge_count[COUNT_WIDTH-1:0];
        end
        else begin
            delay_posedge_count[COUNT_WIDTH-1:0] = 0;
            delay_negedge_count[COUNT_WIDTH-1:0] = delay_negedge_count[COUNT_WIDTH-1:0] < COUNT_MAX ? 
                                                delay_negedge_count[COUNT_WIDTH-1:0]+1 : delay_negedge_count[COUNT_WIDTH-1:0];
        end
    end

    always @(posedge clk)
    if ((out == 0) && (delay_posedge_count[COUNT_WIDTH-1:0] == COUNT_MAX)) begin
        out <= 1'b1;
    end
    else begin
        if ((out == 1) && (delay_negedge_count[COUNT_WIDTH-1:0] == COUNT_MAX)) begin
            out <= 1'b0;
        end
    end


endmodule