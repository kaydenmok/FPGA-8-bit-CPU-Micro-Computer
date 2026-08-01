`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2026 09:51:47 PM
// Design Name: 
// Module Name: io_controller_tb
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


module io_controller_tb;

    // TESTBENCH SIGNALS
    logic        clk;
    logic        reset;

    logic [7:0]  address;
    logic [7:0]  write_data;
    logic        write_enable;
    logic        read_enable;

    logic [15:0] switches;
    logic [4:0]  buttons;

    logic [15:0] leds;
    logic [7:0]  read_data;
    logic        io_selected;
    
    // DEVICE UNDER TEST
    io_controller dut (
        .clk          (clk),
        .reset        (reset),
        .address      (address),
        .write_data   (write_data),
        .write_enable (write_enable),
        .read_enable  (read_enable),
        .switches     (switches),
        .buttons      (buttons),
        .leds         (leds),
        .read_data    (read_data),
        .io_selected  (io_selected)
    );
    
    // CLOCK
    
    // 10 ns clock periods
    initial begin
        clk = 1'b0;
        
        forever begin
            #5 clk = ~clk;
        end
    end 
    
    // AUTOMATIC CHECKS
    task automatic check(
        input logic condition,
        input string message
    );
    
        begin
            if (condition) begin
                $display("PASS: %s", message);
            end
            else begin
                $error("FAIL %s", message);
            end
        end
    endtask
    
    
    // TEST SEQUENCE
    initial begin
        reset          = 1'b1;
        address        = 8'h00;
        write_data     = 8'h00;
        
        write_enable   = 1'b0;
        read_enable    = 1'b0;
        
        switches       = 16'h0000;
        buttons        = 5'b00000;
        
        // Hold reset for two clock cycles.
        // Safe measure to ensure everything resets
        repeat(2) @(posedge clk);
        
        @(negedge clk);
        reset = 1'b0;
        
        #1;
        
        // ========================================================
        // TEST 1: NORMAL RAM ADDRESS
        // ========================================================

        address = 8'h20;

        #1;

        check(
            io_selected == 1'b0,
            "RAM address 0x20 does not select I/O"
        );
        
        // ========================================================
        // TEST 2: WRITE BOTTOM 8 LEDs
        //
        // Address F0 = LEDs 7-0
        // ========================================================

        address      = 8'hF0;
        write_data   = 8'b10101010;
        write_enable = 1'b1;

        #1;

        check(
            io_selected == 1'b1,
            "Address 0xF0 selects I/O"
        );

        // LED register updates on rising clock edge.
        @(posedge clk);
        #1;

        check(
            leds[7:0] == 8'b10101010,
            "Address 0xF0 writes bottom 8 LEDs"
        );

        write_enable = 1'b0; 
       
        // ========================================================
        // TEST 3: WRITE TOP 8 LEDs
        //
        // Address F1 = LEDs 15-8
        // ========================================================
        
        @(negedge clk);

        address      = 8'hF1;
        write_data   = 8'b00001111;
        write_enable = 1'b1;


        @(posedge clk);
        #1;

        check(
            leds[15:8] == 8'b00001111,
            "Address 0xF1 writes top 8 LEDs"
        );


        // Make sure bottom LEDs were NOT changed.
        check(
            leds[7:0] == 8'b10101010,
            "Writing upper LEDs does not change lower LEDs"
        );

        write_enable = 1'b0; 
        
        
        // ========================================================
        // TEST 4: READ BOTTOM 8 SWITCHES
        //
        // Address F2 = SW7-0
        // ========================================================
        
        // falling edge as write_data happens on rising edge
        @(negedge clk);

        switches[7:0] = 8'b00101010;   // Decimal 42

        address     = 8'hF2;
        read_enable = 1'b1;

        #1;

        check(
            read_data == 8'b00101010,
            "Address 0xF2 reads bottom 8 switches"
        );
        
        // ========================================================
        // TEST 5: READ TOP 8 SWITCHES
        //
        // Address F3 = SW15-8
        // ========================================================

        switches[15:8] = 8'b11001100;

        address = 8'hF3;

        #1;

        check(
            read_data == 8'b11001100,
            "Address 0xF3 reads top 8 switches"
        );
        
        // ========================================================
        // TEST 6: READ BUTTONS
        //
        // Address F4 = pushbuttons
        // ========================================================

        buttons = 5'b10101;

        address = 8'hF4;

        #1;

        check(
            read_data == 8'b00010101,
            "Address 0xF4 reads pushbuttons"
        );
        
        // ========================================================
        // TEST 7: UNUSED I/O ADDRESS
        // ========================================================

        address = 8'hF8;

        #1;

        check(
            io_selected == 1'b1,
            "Reserved 0xF8 address is inside I/O region"
        );

        check(
            read_data == 8'h00,
            "Unused I/O address returns zero"
        );
        
        
        
        $display("ALL TEST PASSED");
        
        $finish;
    end
    
    initial begin
        #500;
        $error("Simulation timeout.");
        $finish;
    end
    
endmodule

