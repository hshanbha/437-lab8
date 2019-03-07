`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/07/2019 09:54:19 AM
// Design Name: 
// Module Name: start
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module start(
    input sys_clkn,
    input sys_clkp,
    output flag,
    output CVM300_CLK_IN
 );
    reg state = 1'b0;
    reg CLK_IN;
    reg [3:0] ClkDiv = 3'b0;
    
    ClockGenerator clock (  .sys_clkn(sys_clkn),
                                      .sys_clkp(sys_clkp), 
                                      .ClkDivThreshold(ClkDiv),                
                                      .FSM_Clk(CLK_IN));
    
    assign flag = state;
    
    initial begin
        CLK_IN <= 1'b0;
        #6000000 
        state <= 1'b1;
        ClkDiv <= 3'b011;
    end
    
    
    
    
endmodule
