`timescale 1ns/1ps
`include "src/io_deglitch.v"
`include "src/clk_divisor.v"

module ns213_bmu_cpld_top
(
    input FPGA_CLK_50M,
    //input CPLD_RST_N,

    output CPLD_LED0_N,
    output CPLD_LED1_N,
    output CPLD_LED2_N,

    input BMC_GPIO0, // 故障切换BIOS信号，默认为1hz方波，故障需换bios时2min没有波形
    input BMC_GPIO1,
    input BMC_GPIO2,
    input BMC_GPIO3,

    input GPIO_RSVD1,// unsed
    input GPIO_RSVD2,// unsed
    input QSPI_CSN0,
    
    output QSPI_CSN0_FPGA,
    output QSPI_CSN1_FPGA,
    
    input R_BMC_I2C_SCL1,
    inout R_BMC_I2C_SDA1,

    output R_BMC_PCIE_RST_N, // BMC_PCIE复位
    output R_BMC_PHY_RST_N, // PHY复位
    input R_BMC_RSTN_EXT,   // BMC复位
    output R_BMC_RSTN_FPGA,
    inout R_CPU_POR_N,

    output USB_SWITCH_EN,

    input R_RESERVE0,
    input R_RESERVE1,
    input R_RESERVE2,
    input R_RESERVE3,
    input R_RESERVE4,
    input R_RESERVE5,
    input R_RESERVE6,
    input R_RESERVE7,
    input R_RESERVE8,
    input R_RESERVE9,
    input R_RESERVE10,
    input R_RESERVE11,
    input R_RESERVE12,
    input R_RESERVE13,
    input R_RESERVE14,
    input R_RESERVE15,
    input R_RESERVE16,
    input R_RESERVE17,
    input R_RESERVE18,
    output R_RESERVE19,

    input VCORE_EN,
    output P1V8_EN,
    output P1V1_EN,
    output P3V3_EN,
    input VCORE_PWRGD,
    input P1V8_PWRGD,
    input P3V3_PWRGD,
    input P1V1_PWRGD,


// PORT0
   inout R_FPGA_GPIO0,
    inout R_FPGA_GPIO1,
    inout R_FPGA_GPIO2,
    inout R_FPGA_GPIO3,
    inout R_FPGA_GPIO4,
    inout R_FPGA_GPIO5,
    inout R_FPGA_GPIO6,
    inout R_FPGA_GPIO7,

// PORT1
    inout R_FPGA_GPIO8,
    inout R_FPGA_GPIO9,
    inout R_FPGA_GPIO10,
    inout R_FPGA_GPIO11,
    inout R_FPGA_GPIO12,
    inout R_FPGA_GPIO13,
    inout R_FPGA_GPIO14,
    inout R_FPGA_GPIO15
);

	`define POR_BY_SOFT 1'b0
	`define DELAY_6MS	11'd6
	`define DELAY_10MS	11'd10 
	`define DELAY_50MS	11'd50 
	`define DELAY_100MS	11'd100 
	`define DELAY_2S	9'd2
	`define DELAY_10S	9'd10
	`define DELAY_20S	9'd20
	`define DELAY_120S	9'd120
	`define DELAY_150S	9'd150
	`define DELAY_200S	9'd200

    parameter 		ST_BIOS_MAIN        = 0,
					ST_BIOS_SECOND	    = 1,
					ST_UPDATE_MAIN   	= 2,
					ST_UPDATE_SECOND   	= 3;


	wire 	clk, rst_l;
	wire 	one_ms_pulse;
	wire 	one_s_pulse;
	wire 	one_us_pulse;
	wire 	ALL_PWRGD_w;

	wire 	timer_delay_VCORE_PWRGD;
	wire 	timer_delay_P1V8_PWRGD;
	wire 	timer_delay_P3V3_PWRGD;
	wire 	timer_delay_P1V1_PWRGD;
	wire 	timer_delay_100MS_P1V1_PWRGD;
	wire 	timer_delay_2S_P1V1_PWRGD;
	wire 	isHearBeat;

    assign 	clk = FPGA_CLK_50M;
    assign 	rst_l = P1V8_PWRGD;
    //assign 	rst_l = CPLD_RST_N;
	assign 	cnt_en = 1'b1; 
	assign 	one_pulse = 1'b1;

    assign 	USB_SWITCH_EN = timer_delay_150S_P1V1_PWRGD;
    assign 	R_BMC_RSTN_FPGA = R_BMC_RSTN_EXT;
    //assign 	R_BMC_RSTN_FPGA = 1'bz;//R_BMC_RSTN_EXT & R_CPU_POR_N;
    

	wire 	clk_divisor_out;

    wire [7:0] PORT0;
    assign {R_FPGA_GPIO7,R_FPGA_GPIO6,R_FPGA_GPIO5,R_FPGA_GPIO4,
            R_FPGA_GPIO3,R_FPGA_GPIO2,R_FPGA_GPIO1,R_FPGA_GPIO0} = PORT0;
    wire [7:0] PORT1;
    assign {R_FPGA_GPIO15,R_FPGA_GPIO14,R_FPGA_GPIO13,R_FPGA_GPIO12,
            R_FPGA_GPIO11,R_FPGA_GPIO10,R_FPGA_GPIO9,R_FPGA_GPIO8} = PORT1;

    wire [7:0] UPDATE_BIOS;

    wire [3:0] debug;
    // bit 3,2,1,0
    //assign {R_RESERVE19, CPLD_LED2_N, CPLD_LED1_N, CPLD_LED0_N} = ~debug;
    
    i2c i2c_nca9555(
        .clk(clk),
        .SCL(R_BMC_I2C_SCL1),
        .SDA(R_BMC_I2C_SDA1),
        .RST(rst_l),
        .LEDG(debug),
        .PORT0(PORT0),
        .PORT1(PORT1),
        .UPDATEBIOS(UPDATE_BIOS)
    );

    phy_reset_io_deglitch phy_reset_deglitch(
        .clk(one_ms_pulse),
        .rst_l(rst_l),
        .in(R_CPU_POR_N),
        .out(R_BMC_PHY_RST_N)
    );
	clk_divisor clk_divisor_1s(
        .sys_clk(clk),
        .clkout(clk_divisor_out)
	);

// seqruce step
	assign	ALL_PWRGD_w = VCORE_EN;
	assign	P1V8_EN = timer_delay_VCORE_PWRGD;
	assign	P3V3_EN = timer_delay_P1V8_PWRGD;
	assign	P1V1_EN = timer_delay_P3V3_PWRGD;
`ifdef POR_BY_SOFT
	assign	R_BMC_PCIE_RST_N = timer_delay_P1V1_PWRGD;
`else
	assign	R_BMC_PCIE_RST_N = 1'bz;
`endif
  
  //1 us timer
	timer_1us u_timer_1us(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(cnt_en),
	.cnt_pulse(one_pulse),
	.timeout(one_us_pulse)
	 );
//1 ms timer
	timer_1ms u_timer_1ms(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(cnt_en),
	.cnt_pulse(one_us_pulse),
	.timeout(one_ms_pulse)
	 );
//1 s timer
	timer_1s u_timer_1s(
	
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(cnt_en),
	.cnt_pulse(one_ms_pulse),
	.timeout(one_s_pulse)
	 );
  
//timer_delay_VCORE_PWRGD
	timer_n_ms u1_timer_n_ms(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & VCORE_PWRGD),
	.cnt_size(`DELAY_6MS),
	.cnt_pulse(one_ms_pulse),
	.timeout(timer_delay_VCORE_PWRGD)
	 );	
//timer_delay_P1V8_PWRGD
	timer_n_ms u2_timer_n_ms(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & P1V8_PWRGD),
	.cnt_size(`DELAY_6MS),
	.cnt_pulse(one_ms_pulse),
	.timeout(timer_delay_P1V8_PWRGD)
	 );	
//timer_delay_P3V3_PWRGD
	timer_n_ms u3_timer_n_ms(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & P3V3_PWRGD),
	.cnt_size(`DELAY_6MS),
	.cnt_pulse(one_ms_pulse),
	.timeout(timer_delay_P3V3_PWRGD)
	 );	
//timer_delay_P1V1_PWRGD
	timer_n_ms u4_timer_n_ms(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & P1V1_PWRGD),
	.cnt_size(`DELAY_10MS),
	.cnt_pulse(one_ms_pulse),
	.timeout(timer_delay_P1V1_PWRGD)
	 );	

//timer_delay_100MS_P1V1_PWRGD
	timer_n_ms u41_timer_n_ms(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & P1V1_PWRGD),
	.cnt_size(`DELAY_100MS),
	.cnt_pulse(one_ms_pulse),
	.timeout(timer_delay_100MS_P1V1_PWRGD)
	 );
//timer_delay_2S_P1V1_PWRGD
	timer_n_s u1_timer_n_s(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & P1V1_PWRGD),
	.cnt_size(`DELAY_2S),
	.cnt_pulse(one_s_pulse),
	.timeout(timer_delay_2S_P1V1_PWRGD)
	 );
//timer_delay_150S_P1V1_PWRGD
	timer_n_s u2_timer_n_s(                                      
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & P1V1_PWRGD),
	.cnt_size(`DELAY_150S),
	.cnt_pulse(one_s_pulse),
	.timeout(timer_delay_150S_P1V1_PWRGD)
	 );

//timer_delay_POWER_ON_2MIN
	timer_n_s u81_timer_n_s(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & R_CPU_POR_N),
	.cnt_size(`DELAY_120S),
	.cnt_pulse(one_s_pulse),
	.timeout(timer_delay_POWER_ON_2MIN)
	 );


    check_1hz check_1hz_deglitch(
        .clk(one_ms_pulse),
        .rst_l(rst_l),
        .in(BMC_GPIO0),
        .out(isHearBeat)
    );

// control state machine
    
    assign is_update_main = UPDATE_BIOS[0]; // 默认是高
    assign is_update_second = UPDATE_BIOS[1]; // 默认是高
    assign is_update_done = UPDATE_BIOS[2]; // 默认是高
	reg 	[9:0] current_state;
    reg CPU_POR_RST_EN;
	always@( posedge clk or negedge rst_l) 
	if(~rst_l)
        current_state <= ST_BIOS_MAIN;
    else begin
        CPU_POR_RST_EN = 1'b0;
    case(current_state)
        ST_BIOS_MAIN: begin
            if(timer_delay_POWER_ON_2MIN & !isHearBeat) begin
                current_state = ST_BIOS_SECOND;
                CPU_POR_RST_EN = 1'b1;
            end
            else if(timer_delay_POWER_ON_2MIN & !is_update_second)
                current_state = ST_UPDATE_SECOND;
            else
                current_state = current_state;
            end
        ST_BIOS_SECOND: begin
            if(!is_update_main)
                current_state = ST_UPDATE_MAIN;
            else
                current_state = ST_BIOS_SECOND;
            end
        ST_UPDATE_MAIN: begin
            if(!is_update_done) begin
                current_state = ST_BIOS_MAIN;
                CPU_POR_RST_EN = 1'b1;
            end
            else
                current_state = ST_UPDATE_MAIN;
            end
        ST_UPDATE_SECOND: begin
            if(!is_update_done) begin
                current_state = ST_BIOS_MAIN;
                CPU_POR_RST_EN = 1'b1;
            end
            else
                current_state = ST_UPDATE_SECOND;
            end
        default:
                current_state = ST_BIOS_MAIN;
    endcase
    end


    wire CPU_POR_RST_OUT;
    POR_RESET POR_RESET_deglitch(
        .clk(clk),
        .rst_l(rst_l),
        .in(CPU_POR_RST_EN),
        .out(CPU_POR_RST_OUT)
    );
    
    assign  QSPI_CSN0_FPGA = (current_state == ST_BIOS_MAIN | current_state == ST_UPDATE_MAIN) ? QSPI_CSN0 : 1'b1;
    assign 	QSPI_CSN1_FPGA = (current_state == ST_BIOS_SECOND | current_state == ST_UPDATE_SECOND) ? QSPI_CSN0 : 1'b1;
    
    // 刚上电的时候,2s内。timer_delay_100MS_P1V1_PWRGD
    // 2s后,timer_delay_2S_P1V1_PWRGD释放
    // 2s后，如果有CPU_POR_RST_OUT，按CPU_POR_RST_OUT
    //assign 	R_CPU_POR_N = timer_delay_2S_P1V1_PWRGD ? 1'bz : timer_delay_100MS_P1V1_PWRGD;
    assign 	R_CPU_POR_N = !timer_delay_2S_P1V1_PWRGD ? timer_delay_100MS_P1V1_PWRGD :
                        !CPU_POR_RST_OUT ? 1'b0 : 1'bz;


    assign {CPLD_LED1_N, CPLD_LED0_N}  = current_state == ST_BIOS_MAIN ? ~2'b00 :
                                          current_state == ST_UPDATE_MAIN ? ~2'b01 :
                                          current_state == ST_BIOS_SECOND ? ~2'b10 :
                                          current_state == ST_UPDATE_SECOND ? ~2'b11 : ~2'b00;

    // assign CPLD_LED0_N = is_update_main ? 1'b0 : 1'b1;
    // assign CPLD_LED1_N = is_update_second ? 1'b0 : 1'b1;
    // assign CPLD_LED2_N = is_update_done ? 1'b0 : 1'b1;
endmodule
