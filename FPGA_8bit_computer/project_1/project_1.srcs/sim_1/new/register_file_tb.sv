`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2026 08:59:45 PM
// Design Name: 
// Module Name: register_file_tb
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


module register_file_tb;
    
    // Testbench versions of the register-file signals
    logic clk;
    logic reset;

    logic [2:0] read_addr_a;
    logic [2:0] read_addr_b;

    logic [2:0] write_addr;
    logic [7:0] write_data;
    logic       write_enable;

    logic [7:0] read_data_a;
    logic [7:0] read_data_b;
    
    // Instantiate the design being tested
    register_file dut (
        .clk(clk),
        .reset(reset),
        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),
        .write_addr(write_addr),
        .write_data(write_data),
        .write_enable(write_enable),
        .read_data_a(read_data_a),
        .read_data_b(read_data_b)           
    );
    
    // Generate clock (5ns per flip)
    always #5 clk = ~clk;
    
    initial begin
    
        // Initalize every testbench signal to prevent unknown values
        clk          = 1'b0;
        // Force all registers to be 0 at start
        reset        = 1'b1;
        read_addr_a  = 3'd0;
        read_addr_b  = 3'd0;
        write_addr   = 3'd0;
        write_data   = 8'h00;
        write_enable = 1'b0;
        // Wait 12 ns
        #12;
        
        // Release reset before next rising edge
        reset =  1'b0;    
        
        //  == == == TEST 1 == == == == == == ==
        // Write 0x25 into R1
        
        write_addr    = 3'd1;
        write_data    = 8'h25;
        write_enable  = 1'b1;
        
        // Wait long enough for one rising edge to occur
        #10;
        
        // == == == TEST 2 == == == == == == == == 
        // Write 0xA7 into R2
        
        write_addr    = 3'd2;
        write_data    = 8'hA7;
        // Note write enable is still HIGH so not needed
        
        #10;
        
        write_enable = 1'b0;
        
        // == == == TEST 3 == == == == == == == == ==
        // Read R1 and R2 at the same time
        
        read_addr_a = 3'd1;
        read_addr_b = 3'd2;
        // reads are combination (instant) delay makes it visible in waveform
        #10;   
        
        // Expected:
        // read_data_a = 0x25
        // read_data_b = 0xA7
        
        // == == == TEST 4 == == == == == == == == ==
        // Reverse the read
        
        read_addr_a = 3'd2;
        read_addr_b = 3'd1;
        #10;
        
        // Expected:
        // read_data_a = 0xA7
        // read_data_b = 0x25
        
        // == == == TEST 5 == == == == == == == == ==
        // Read untouched registers
        
        read_addr_a = 3'd3;
        read_addr_b = 3'd7;
        #10;
        // Expected:
        // 0x00 for both
        
        // == == == TEST 6 == == == == == == == == ==
        // Reset all registers
        
        reset = 1'b1;
        #10;
        reset = 1'b0;
        
        read_addr_a = 3'd1;
        read_addr_b = 3'd2;
        #10;
        
        // both should be 0x00
        
        $finish;
     end
        
endmodule
