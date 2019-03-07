`timescale 1ns / 1ps

module BTPipeExample(
    input   wire    [4:0] okUH,
    output  wire    [2:0] okHU,
    inout   wire    [31:0] okUHU,
    input wire [31:0] Reset_Counter,
    inout   wire    okAA,
    input [3:0] button,
    output [7:0] led,
    input sys_clkn,
    input sys_clkp
    );
    
    wire okClk;            //These are FrontPanel wires needed to IO communication    
    wire [112:0]    okHE;  //These are FrontPanel wires needed to IO communication    
    wire [64:0]     okEH;  //These are FrontPanel wires needed to IO communication     
    //This is the OK host that allows data to be sent or recived    
    okHost hostIF (
        .okUH(okUH),
        .okHU(okHU),
        .okUHU(okUHU),
        .okClk(okClk),
        .okAA(okAA),
        .okHE(okHE),
        .okEH(okEH)
    );
        
    //Depending on the number of outgoing endpoints, adjust endPt_count accordingly.
    //In this example, we have 1 output endpoints, hence endPt_count = 1.
    localparam  endPt_count = 1;
    wire [endPt_count*65-1:0] okEHx;  
    okWireOR # (.N(endPt_count)) wireOR (okEH, okEHx);    
    
    //Instantiate the ClockGenerator module, where three signals are generate:
    //High speed CLK signal, Low speed FSM_Clk signal     
    wire [23:0] ClkDivThreshold = 2;   
    wire FSM_Clk, ILA_Clk; 
    ClockGenerator ClockGenerator1 (  .sys_clkn(sys_clkn),
                                      .sys_clkp(sys_clkp),                                      
                                      .ClkDivThreshold(ClkDivThreshold),
                                      .FSM_Clk(FSM_Clk),                                      
                                      .ILA_Clk(ILA_Clk) );
                                                                                  
    localparam STATE_INIT                = 8'd0;
    localparam STATE_RESET               = 8'd1;   
    localparam STATE_DELAY               = 8'd2;
    localparam STATE_RESET_FINISHED      = 8'd3;
    localparam STATE_ENABLE_WRITING      = 8'd4;
    localparam STATE_COUNT               = 8'd5;
    localparam STATE_FINISH              = 8'd6;
   
    reg [31:0] counter = 8'd0;
    reg [15:0] counter_delay = 16'd0;
    reg [7:0] State = STATE_INIT;
    reg [7:0] led_register = 0;
    reg [3:0] button_reg, write_enable_counter;  
    reg write_reset, read_reset, write_enable;
    
    wire [31:0] DATA_Counter;    
    wire FIFO_read_enable, FIFO_BT_BlockSize_Full, FIFO_full, FIFO_empty, BT_Strobe;
    wire [31:0] FIFO_data_out;
    
    assign led[0] = ~FIFO_empty; 
    assign led[1] = ~FIFO_full;
    assign led[2] = ~FIFO_BT_BlockSize_Full;
    assign led[3] = ~FIFO_read_enable;  
    assign led[7] = ~read_reset;
    assign led[6] = ~write_reset;
    initial begin
        write_reset <= 1'b0;
        read_reset <= 1'b0;
        write_enable <= 1'b1;    
    end
                                         
    always @(posedge FSM_Clk) begin     
        button_reg <= ~button;   // Grab the values from the button, complement and store them in register                
        if (Reset_Counter[0] == 1'b1) State <= STATE_RESET;
        
        case (State)
            STATE_INIT:   begin                              
                write_reset <= 1'b1;
                read_reset <= 1'b1;
                write_enable <= 1'b0;
                if (Reset_Counter[0] == 1'b1) State <= STATE_RESET;                
            end
            
            STATE_RESET:   begin
                counter <= 0;
                counter_delay <= 0;
                write_reset <= 1'b1;
                read_reset <= 1'b1;
                write_enable <= 1'b0;                
                if (Reset_Counter[0] == 1'b0) State <= STATE_RESET_FINISHED;             
            end                                     
 
           STATE_RESET_FINISHED:   begin
                write_reset <= 1'b0;
                read_reset <= 1'b0;                 
                State <= STATE_DELAY;                                   
            end   
                          
            STATE_DELAY:   begin
                if (counter_delay == 16'b0000_1111_1111_1111)  State <= STATE_ENABLE_WRITING;
                else counter_delay <= counter_delay + 1;
            end
            
             STATE_ENABLE_WRITING:   begin
                //write_enable <= 1'b1;
                write_enable_counter <= 1'b0;
                State <= STATE_COUNT;
             end
                                  
             STATE_COUNT:   begin
                counter <= counter + 1;                
                if (write_enable_counter == 5) begin
                    write_enable <= 1'b1;
                    write_enable_counter <= 0;
                end else begin
                    write_enable_counter <= write_enable_counter +1;                    
                    write_enable <= 0;
                end                                    
                if (counter == 1024*8)  State <= STATE_FINISH;         
             end
            
             STATE_FINISH:   begin                         
                 write_enable <= 1'b0;                                                           
            end

        endcase
    end    
       
    fifo_generator_0 FIFO_for_Counter_BTPipe_Interface (
        .wr_clk(FSM_Clk),
        .wr_rst(write_reset),
        .rd_clk(okClk),
        .rd_rst(read_reset),
        .din(counter),
        .wr_en(write_enable),
        .rd_en(FIFO_read_enable),
        .dout(FIFO_data_out),
        .full(FIFO_full),
        .empty(FIFO_empty),       
        .prog_full(FIFO_BT_BlockSize_Full)        
    );
      
    okBTPipeOut CounterToPC (
        .okHE(okHE), 
        .okEH(okEHx[ 0*65 +: 65 ]),
        .ep_addr(8'ha0), 
        .ep_datain(FIFO_data_out), 
        .ep_read(FIFO_read_enable),
        .ep_blockstrobe(BT_Strobe), 
        .ep_ready(FIFO_BT_BlockSize_Full)
    );                                      
    
                                  
endmodule
