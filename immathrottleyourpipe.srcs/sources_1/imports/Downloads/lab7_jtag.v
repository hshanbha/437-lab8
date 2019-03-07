`timescale 1ns / 1ps

module SPI_Transmit(
    input sys_clkn,
    input sys_clkp, 
    inout CVM300_SYS_RES_N,
    output CVM300_FRAME_REQ,
    output CVM300_CLK_IN
    );
    
    reg SPI_EN;
    reg SPI_IN;
    reg SYS_RES;
    reg FRAME_REQ;
    reg CLK_IN;
    reg Clk;
    reg [31:0] counter;
    reg [8:0] state = 9'd0;
    reg flag;
    reg init_flag = 1'b0;

    localparam STATE_INIT = 8'd0; 
    assign CVM300_RES_N = SYS_RES;
    assign CVM300_FRAME_REQ = FRAME_REQ;
    assign CVM300_CLK_IN = CLK_IN;
    
    ClockGenerator clkin (  .sys_clkn(sys_clkn),
                             .sys_clkp(sys_clkp), 
                             .ClkDivThreshold(3'd3),                
                             .FSM_Clk(CLK_IN));
                             
    start init (    .sys_clkn(sys_clkn),
                    .sys_clkp(sys_clkp), 
                    .flag(flag),
                    .CVM300_CLK_IN(CLK_IN));
    
        
    initial  begin
        SYS_RES <= 1'b0;
        FRAME_REQ <= 1'b0;
        CLK_IN <= 1'b0;
        counter <= 1'b0;
    end
    
    always @(*) begin
       
    end   

    
                               
    always @(negedge CLK_IN) begin 
        case(state) 
        
        STATE_INIT: begin 
            if(flag == 1'b0) state <= STATE_INIT;
            else state <= state + 1'b1;
        end
        
        9'd1: begin 
            counter <= counter + 1'b1;
            if(counter == 32'd400000000) state <= state +1'b1;
            else state <= 9'd1;
        end
        
        9'd2: begin
            SYS_RES <= 1'b1;
            counter <= 1'b0;
            state <= state + 1'b1;
        end
        
        9'd3: begin
            counter <= counter + 1'b1;
            if(counter == 32'd400000000) state <= state + 1'b1;
            else state <= 9'd3;
        end
        
        default: begin
            init_flag <= 1'b1;
        end
        endcase
    end        
    
    always @(posedge CLK_IN) begin
        case(state)
        
        9'd4: begin
            FRAME_REQ <= 1'b1;
            state <= state + 1'b1;
        end
        
        9'd5: begin
            FRAME_REQ <= 1'b0;
            state <= state + 1'b1;
        end
        
        default: begin
            init_flag <= 1'b0;
        end
        endcase
     end
                   
endmodule
