`timescale 1ns / 1ps

module JTEG_Test_File(
    input [3:0] button,
    input wire [4:0] okUH,
    output wire [2:0] okHU,
    inout wire [31:0] okUHU,
    inout wire okAA,
    output [7:0] led,
    input sys_clkn,
    input sys_clkp, 
    output CVM300_SPI_EN,
    output CVM300_SPI_IN,
    input CVM300_SPI_OUT,
    output CVM300_SPI_CLK,
    inout CVM300_SYS_RES_N, 
    output PMOD_A1,
    output PMOD_B1,
    output CVM300_CLK_IN
);
    
    //reg [3:0] button_reg;
    
    wire okClk, TrigerEvent; 
    assign TrigerEvent = button[1];
    wire [31:0] cmd;
    wire [31:0] register_cpy;
    wire [31:0] data_write_cpy;
    wire [31:0] data_read_cpy;
    wire [8:0] State_cpy;
    wire [31:0] temp_data_cpy;
    wire [31:0] temp_data_cpy_1;
    wire [31:0] Reset_Counter;
               //These are FrontPanel wires needed to IO communication    
    wire [112:0] okHE;  //These are FrontPanel wires needed to IO communication    
    wire [64:0] okEH;  //These are FrontPanel wires needed to IO communication  
   // wire [23:0] ClkDivThreshold = 100;   
    wire FSM_Clk, ILA_Clk; 
    wire CLK_IN;   
    assign CVM300_CLK_IN = CLK_IN;
     ClockGenerator ClockGenerator1 (  .sys_clkn(sys_clkn),
                                      .sys_clkp(sys_clkp),                                      
                                      //.ClkDivThreshold(ClkDivThreshold),
                                      .FSM_Clk(FSM_Clk),                                      
                                      .ILA_Clk(ILA_Clk),
                                      .Clk_In(CLK_IN) );
                                      
    assign PMOD_A1 = CVM300_CLK_IN;
    assign PMOD_B1 = FSM_Clk;
    //Instantiate the module that we like to test
    SPI_Transmit Spispoo(
        .button(button),
        .led(led),
        .sys_clkn(sys_clkn),
        .sys_clkp(sys_clkp), 
        .CVM300_SPI_EN(CVM300_SPI_EN),
        .CVM300_SPI_IN(CVM300_SPI_IN),
        .CVM300_SPI_OUT(CVM300_SPI_OUT),
        .CVM300_SPI_CLK(CVM300_SPI_CLK),
        .CVM300_SYS_RES_N(CVM300_SYS_RES_N),
        .cmd(cmd),
        .register_cpy(register_cpy),//register_cpy),
        .data_write_cpy(data_write_cpy),
        .data_read_cpy(data_read_cpy),
        .temp_data_cpy(temp_data_cpy),
       // .temp_data_cpy_1(temp_data_cpy_1),
        .FSM_Clk(FSM_Clk),
        .State_cpy(State_cpy)
        //.CVM300_CLK_IN(CVM300_CLK_IN)
    );
    BTPipeExample(
    .okUH(okUH),
    .okHU(okHU),
    .okUHU(okUHU),
    .Reset_Counter(Reset_Counter),
    .okAA(okAA),
    .button(button),
    .led(led),
    .sys_clkn(sys_clkn),
    .sys_clkp(sys_clkp)
    );
    okHost hostIF (
            .okUH(okUH),
            .okHU(okHU),
            .okUHU(okUHU),
            .okClk(okClk),
            .okAA(okAA),
            .okHE(okHE),
            .okEH(okEH)
        );
    
        localparam  endPt_count = 6;
        wire [endPt_count*65-1:0] okEHx;  
        okWireOR # (.N(endPt_count)) wireOR (okEH, okEHx);
    
         

        // ok stuff
     
        okWireIn wire15 (   .okHE(okHE), 
                        .ep_addr(8'h05), 
                        .ep_dataout(Reset_Counter)); 
    
    //  output which part of fsm to start in (write, read, burst read)
        okWireIn wire10 (   .okHE(okHE), 
                            .ep_addr(8'h00), 
                            .ep_dataout(cmd));
                            
        // a copy of which register to write to if writing                
        okWireIn wire13 (   .okHE(okHE), 
                            .ep_addr(8'h03), 
                            .ep_dataout(register_cpy));
                            
         //  a copy of what data to write if writing                 
        okWireIn wire14 (   .okHE(okHE), 
                            .ep_addr(8'h04), 
                            .ep_dataout(data_write_cpy));
        
        //a copy of what data is read          
        okWireOut wire21 (  .okHE(okHE), 
                            .okEH(okEHx[ 1*65 +: 65 ]),
                            .ep_addr(8'h21), 
                            .ep_datain(data_read_cpy));
    
        // a copy of the temperature read
        okWireOut wire20 (  .okHE(okHE), 
                            .okEH(okEHx[ 0*65 +: 65 ]),
                            .ep_addr(8'h20), 
                            .ep_datain(temp_data_cpy));
                            
         // a copy of the temperature read
//        okWireOut wire22 (  .okHE(okHE), 
//                            .okEH(okEHx[ 2*65 +: 65 ]),
//                            .ep_addr(8'h22), 
//                            .ep_datain(temp_data_cpy_1));
    
    
   wire SPI_EN, SPI_OUT, SPI_CLK, SPI_IN;
   assign SPI_EN = CVM300_SPI_EN;
   assign SPI_OUT = CVM300_SPI_OUT;
   assign SPI_CLK = CVM300_SPI_CLK;
   assign SPI_IN = CVM300_SPI_IN;

    //Instantiate the ILA module
    ila_0 ila_sample12 ( 
        .clk(ILA_Clk),
        .probe0({temp_data_cpy, data_write_cpy, register_cpy, cmd, SPI_IN, SPI_OUT, SPI_EN, SPI_CLK,State_cpy}),                             
        .probe1({FSM_Clk, TrigerEvent})
        );                        
endmodule