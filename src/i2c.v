//Implement the parts functions of NCA9555

`include "src/io_deglitch.v"
`include "src/global_define.v"
module i2c(clk, SCL, SDA, RST, LEDG, PORT0, PORT1, UPDATEBIOS);
    input SCL, RST;//asynchronous reset input
    input clk;
    inout SDA;
    output [3:0] LEDG;

    inout [7:0] PORT0;
    inout [7:0] PORT1;
    output [7:0] UPDATEBIOS;

    parameter [6:0] device_address = 7'h58; // 8'hB0
    parameter [2:0] STATE_IDLE      = 3'h0,//idle
                    STATE_DEV_ADDR  = 3'h1,//the slave addr match
                    STATE_READ      = 3'h2,//the op=read 
                    STATE_IDX_PTR   = 3'h3,//get the index of inner-register
                    STATE_WRITE     = 3'h4;//write the data in the reg 

    reg             start_detected;
    reg             start_isNeedClear;

    reg             stop_detected;
    reg             stop_isNeedClear;

    reg [3:0]       bit_counter;//(from 0 to 8)9counters-> one byte=8bits and one ack=1bit
    reg [7:0]       input_shift;
    reg             isGetAckFromMaster; // when read
    reg [2:0]       state;
    // reg
    reg [7:0]       r0_port_0_read; //input， only read
    reg [7:0]       r1_port_1_read; //input， only read
    reg [7:0]       r2_port_0_write; // output default 1
    reg [7:0]       r3_port_1_write; // output default 1
    reg [7:0]       r4_port_0_pr; // polarity_inversion not support
    reg [7:0]       r5_port_1_pr; // polarity_inversion not support
    reg [7:0]       r6_port_0_config = 8'hFF; // 1:input;0:output
    reg [7:0]       r7_port_1_config = 8'hFF;
    reg [7:0]       r8_version = `VERSION;
    reg [7:0]       r9_update_bios = 8'hFF; // update BIOS Related
    //delay  release_sda
	 parameter RELEASE_SDA_COUNT_WIDTH = 7;
	 //parameter RELEASE_SDA_COUNT_MAX = 2**RELEASE_SDA_COUNT_WIDTH-1;
	 parameter RELEASE_SDA_COUNT_MAX = 7'd100;
	 parameter RELEASE_SDA_COUNT_MIN = 0;
	reg 	        [RELEASE_SDA_COUNT_WIDTH:0] release_sda_counter;
    reg             release_sda_start;
    wire             release_sda_delay_over;

    reg [7:0]       output_shift;
    reg             SDA_output_control;
    reg [7:0]       index_pointer;

    wire            start_rst = ~RST | start_isNeedClear;//detect the START for one cycle
    wire            stop_rst = ~RST | stop_isNeedClear;//detect the STOP for one cycle
    wire            lsb_bit = (bit_counter == 4'h7) && !start_detected;//the 8bits one byte data
    wire            ack_bit = (bit_counter == 4'h8) && !start_detected;//the 9bites ack 
    wire            address_detect = (input_shift[7:1] == device_address);//the input address match the slave
    wire            read_write_bit = input_shift[0];// the write or read operation 0=write and 1=read
    wire            write_strobe = (state == STATE_WRITE) && ack_bit;//write state and finish one byte=8bits

	`define DLY_0_1us	3'd5
	`define DLY_1us	    7'd50

    `define tHIGH_0_6us (`DLY_0_1us * 6)    // # 30
    `define tHIGH_4us (`DLY_1us * 4)    // # 200
    //assign    SCL_reg = SCL;
    wire SCL_reg;
    // SCL deglitch
    io_deglitch SCL_deglitch(
        .clk(clk),
        .rst_l(RST),
        .in(SCL),
        .out(SCL_reg)
    );

    //assign    SDA_reg = SDA; 
    // SDA deglitch
    wire SDA_reg;
    io_deglitch SDA_deglitch(
        .clk(clk),
        .rst_l(RST),
        .in(SDA),
        .out(SDA_reg)
    );

    assign          SDA = (SDA_output_control | release_sda_delay_over) ? 1'bz : 1'b0;

    assign PORT0[0] = (r6_port_0_config[0] == 1'b0) ? r2_port_0_write[0] : 1'bz;
    assign PORT0[1] = (r6_port_0_config[1] == 1'b0) ? r2_port_0_write[1] : 1'bz;
    assign PORT0[2] = (r6_port_0_config[2] == 1'b0) ? r2_port_0_write[2] : 1'bz;
    assign PORT0[3] = (r6_port_0_config[3] == 1'b0) ? r2_port_0_write[3] : 1'bz;
    assign PORT0[4] = (r6_port_0_config[4] == 1'b0) ? r2_port_0_write[4] : 1'bz;
    assign PORT0[5] = (r6_port_0_config[5] == 1'b0) ? r2_port_0_write[5] : 1'bz;
    assign PORT0[6] = (r6_port_0_config[6] == 1'b0) ? r2_port_0_write[6] : 1'bz;
    assign PORT0[7] = (r6_port_0_config[7] == 1'b0) ? r2_port_0_write[7] : 1'bz;

    assign PORT1[0] = (r7_port_1_config[0] == 1'b0) ? r3_port_1_write[0] : 1'bz;
    assign PORT1[1] = (r7_port_1_config[1] == 1'b0) ? r3_port_1_write[1] : 1'bz;
    assign PORT1[2] = (r7_port_1_config[2] == 1'b0) ? r3_port_1_write[2] : 1'bz;
    assign PORT1[3] = (r7_port_1_config[3] == 1'b0) ? r3_port_1_write[3] : 1'bz;
    assign PORT1[4] = (r7_port_1_config[4] == 1'b0) ? r3_port_1_write[4] : 1'bz;
    assign PORT1[5] = (r7_port_1_config[5] == 1'b0) ? r3_port_1_write[5] : 1'bz;
    assign PORT1[6] = (r7_port_1_config[6] == 1'b0) ? r3_port_1_write[6] : 1'bz;
    assign PORT1[7] = (r7_port_1_config[7] == 1'b0) ? r3_port_1_write[7] : 1'bz;
    
    assign UPDATEBIOS[0] = r9_update_bios[0];
    assign UPDATEBIOS[1] = r9_update_bios[1];
    assign UPDATEBIOS[2] = r9_update_bios[2];
    //-----------------for LED------------------------
    reg [3:0] LEDG;
    //---------------------------------------------
    //---------------detect the start--------------
    //---------------------------------------------
    always @ (posedge start_rst or negedge SDA_reg) 
    begin
        if (start_rst) begin
            start_detected <= 1'b0;
            LEDG[1] <= !LEDG[1];
        end
        else
            start_detected <= SCL_reg;//在SDA下降沿时，如果start_detected = SCL_reg==1 ？ 1 ：0
    end

    always @ (negedge RST or posedge SCL_reg)
    begin
        if (~RST)
            start_isNeedClear <= 1'b0;
        else
            start_isNeedClear <= start_detected; //在SCL上升沿,检测SCL.将上次的检测结果备份
    end
    //the START just last for one cycle of SCL_reg

    //---------------------------------------------
    //---------------detect the stop---------------
    //---------------------------------------------
    always @ (posedge stop_rst or posedge SDA_reg)
    begin   
        if (stop_rst) begin
            stop_detected <= 1'b0;
            LEDG[2] <= !LEDG[2];
        end
        else
            stop_detected <= SCL_reg;
    end

    always @ (negedge RST or posedge SCL_reg)
    begin   
        if (~RST)
            stop_isNeedClear <= 1'b0;
        else
            stop_isNeedClear <= stop_detected;
    end
    //the STOP just last for one cycle of SCL_reg
    //don't need to check the RESTART,due to: a START before it is STOP,it's START; 
    //                                        a START before it is START,it's RESTART;
    //the RESET and START combine can be recognise the RESTART,but it's doesn't matter

    //---------------------------------------------
    //---------------latch the data---------------
    //---------------------------------------------
    always @ (negedge SCL_reg)
    begin
        if (ack_bit || start_detected)
            bit_counter <= 4'h0; // reset the counter
        else
            bit_counter <= bit_counter + 4'h1;
    end
    //counter to 9(from 0 to 8), one byte=8bits and one ack 
    always @ (posedge SCL_reg)
        if (!ack_bit)
            input_shift <= {input_shift[6:0], SDA_reg};
    //at posedge SCL_reg the data is stable,the input_shift get one byte=8bits



    //---------------------------------------------
    //------------slave-to-master transfer---------
    //---------------------------------------------
    always @ (posedge SCL_reg)
        if (ack_bit)
            isGetAckFromMaster <= ~SDA_reg;//the ack SDA_reg is low. is valid when read mode only
    //the 9th bits= ack if the SDA_reg=1'b0 it's a ACK, 


    //---------------------------------------------
    //------------state machine--------------------
    //---------------------------------------------
    always @ (negedge RST or negedge SCL_reg)
    begin
        if (~RST)
            state <= STATE_IDLE;
        else if (start_detected) begin
            state <= STATE_DEV_ADDR;
            LEDG[0] <= !LEDG[0];
        end
        else if (ack_bit)//at the 9th cycle and change the state by ACK
        begin
            case (state)
                STATE_IDLE:
                    state <= STATE_IDLE;

                STATE_DEV_ADDR:
                    if (!address_detect) begin//addr don't match
                        state <= STATE_IDLE;
                    end
                    else if (read_write_bit) begin // addr match and operation is read
                        state <= STATE_READ;
                    end
                    else//addr match and operation is write
                        state <= STATE_IDX_PTR;

                STATE_READ:
                    if (isGetAckFromMaster)//get the master ack 
                        state <= STATE_READ;
                    else//no master ack ready to STOP
                        state <= STATE_IDLE;

                STATE_IDX_PTR:
                    state <= STATE_WRITE;//get the index and ready to write 

                STATE_WRITE:
                    state <= STATE_WRITE;//when the state is write the state 
                endcase
        end
        //if don't write and master send a stop,need to jump idle
        //the stop_detected is the next cycle of ACK
        else if(stop_detected)
            state <= STATE_IDLE;
    end

    //---------------------------------------------
    //------------Register transfers---------------
    //---------------------------------------------

    //-------------------for index----------------
    always @ (negedge RST or negedge SCL_reg)
    begin
        if (~RST)
            index_pointer <= 8'h00;
        else if (stop_detected)
            index_pointer <= 8'h00;
        else if (ack_bit)//at the 9th bit -ack, the input_shift has one bytes
        begin
            if (state == STATE_IDX_PTR) //at the state get the inner-register index
                index_pointer <= input_shift;
            else//ready for next read/write;bulk transfer of a block of data 
                index_pointer <= index_pointer + 8'h01;
        end
    end

    //----------------for master write---------------------------
    //we only define 4 registers for operation
    always @ (negedge RST or negedge SCL_reg)
    begin
        if (~RST)
        begin
            r2_port_0_write <= 8'hFF;
            r3_port_1_write <= 8'hFF;
            r4_port_0_pr <= 8'h00;
            r5_port_1_pr <= 8'h00;
            r6_port_0_config <= 8'hFF;
            r7_port_1_config <= 8'hFF;
        end//the moment the input_shift has one byte=8bits
        else if (write_strobe)
            case (index_pointer)
                8'h02: r2_port_0_write <= input_shift;
                8'h03: r3_port_1_write <= input_shift;
                // 8'h04: r4_port_0_pr <= input_shift;
                // 8'h05: r5_port_1_pr <= input_shift;
                8'h06: r6_port_0_config <= input_shift;
                8'h07: r7_port_1_config <= input_shift;
                8'h09: r9_update_bios <= input_shift;
            endcase
    end

    //------------------------for master read-----------------------
    always @ (negedge SCL_reg)
    begin
        if (lsb_bit)//at one byte that can be load the output_shift
        begin   
            case (index_pointer)
                8'h00: begin
                    r0_port_0_read <= PORT0;
                    output_shift <= r0_port_0_read;
                end
                8'h01: begin
                    r1_port_1_read <= PORT1;
                    output_shift <= r1_port_1_read;
                end
                8'h02: output_shift <= r2_port_0_write;
                8'h03: output_shift <= r3_port_1_write;
                // 8'h04: output_shift <= r4_port_0_pr;
                // 8'h05: output_shift <= r5_port_1_pr;
                8'h06: output_shift <= r6_port_0_config;
                8'h07: output_shift <= r7_port_1_config;
                8'h08: output_shift <= r8_version;
                8'h09: output_shift <= r9_update_bios;
            endcase
        end
        else
            output_shift <= {output_shift[6:0], 1'b0};
            //once the shift it,after 8 times the output_shift=8'b0
            //the 9th bit is 0 for the RESTART for address match slave ACK 
    end

    //---------------------------------------------
    //------------Output driver--------------------
    //---------------------------------------------

    always @ (negedge RST or negedge SCL_reg)
    begin
        if (~RST) begin
            release_sda_start <= 1'b0;
            SDA_output_control <= 1'b1;
        end
        else if (start_detected) begin
            release_sda_start <= 1'b0;
            SDA_output_control <= 1'b1;
        end
        else if (lsb_bit)
            begin
                release_sda_start <= 1'b0;
                SDA_output_control <=
                    !(((state == STATE_DEV_ADDR) && address_detect) ||
                    (state == STATE_IDX_PTR) ||
                    (state == STATE_WRITE)); 
                // LEDG[1] <= !LEDG[1];
                //when operation is wirte 
                //addr match gen ACK,the index get gen ACK,and write data gen ACK
            end
        else if (ack_bit)
            begin
                // Deliver the first bit of the next slave-to-master
                // transfer, if applicable.
                if (((state == STATE_READ) && isGetAckFromMaster) ||
                    ((state == STATE_DEV_ADDR) && address_detect && read_write_bit))  begin
                        release_sda_start <= 1'b0;
                        SDA_output_control <= output_shift[7];
                        // LEDG[2] <= !LEDG[2];
                        //for the RESTART and send the addr ACK for 1'b0
                        //for the read and master ack both slave is pull down
                    end
                else begin
                    release_sda_start <= 1'b1;
                    //SDA_output_control <= 1'b1;
                end
            end
        else if (state == STATE_READ) begin//for read send output shift to SDA_reg
            release_sda_start <= 1'b0;
            SDA_output_control <= output_shift[7];
        end
        else begin
            release_sda_start <= 1'b0;
            SDA_output_control <= 1'b1;
        end
    end


    //delay
    always@(posedge clk or negedge RST)
        if(~RST)
            release_sda_counter[RELEASE_SDA_COUNT_WIDTH-1:0] <= RELEASE_SDA_COUNT_MIN;
        else if(release_sda_start) begin
            release_sda_counter[RELEASE_SDA_COUNT_WIDTH-1:0] <= release_sda_counter[RELEASE_SDA_COUNT_WIDTH-1:0] == RELEASE_SDA_COUNT_MAX ?
                                                            release_sda_counter[RELEASE_SDA_COUNT_WIDTH-1:0] : release_sda_counter[RELEASE_SDA_COUNT_WIDTH-1:0] + 1;
        end
        else begin
            release_sda_counter[RELEASE_SDA_COUNT_WIDTH-1:0] <= RELEASE_SDA_COUNT_MIN;
        end

    assign release_sda_delay_over = release_sda_counter[RELEASE_SDA_COUNT_WIDTH-1:0] == RELEASE_SDA_COUNT_MAX ? 1'b1 : 1'b0;


endmodule
