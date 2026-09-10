`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2026 09:12:07 PM
// Design Name: 
// Module Name: top
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


module top(
    input logic        clk,
    input logic [15:0] sw,
    input logic        btnC,
    input logic        btnU,
    input logic        btnD,
    input logic        btnL,
    input logic        btnR,
    
    input logic        uart_rx,
    output logic       uart_tx,
    
    output logic [15:0] led,
    output logic [6:0]  seg,
    output logic [3:0]  an,
    output logic        dp
    );
    
    // ========================== INTERNAL SIGNALS =================================
    
    logic       reset;
    
    // Pack the four buttons into the 5bit format expected by cpu_core / io_controller
    logic [3:0] buttons;
    
    logic [7:0] display_value;
    logic       display_mode;
    
    // Debug signals from cpu_core outputs 
    logic        halt;
    logic [7:0]  debug_pc;
    logic [15:0] debug_instruction; 
    logic [7:0]  debug_alu_result;
    logic [7:0]  debug_source_a_data;
    logic [7:0]  debug_source_b_data;
    
    // UART SIGNALS
    
    // Byte CPU wants to transmit.
    logic [7:0] uart_tx_data;
    
    // one clock pulse telling transmitter to start
    logic       uart_tx_start;
    
    // HIGH while transmitter is currently sending a byte.
    logic       uart_tx_busy;
    
    // Most recently received UART byte
    logic [7:0] uart_rx_data;
    
    // One-clock pulse when receiver completes a byte.
    logic       uart_rx_valid;
    
    // ============================ BUTTON MAPPING ===================================
    
    // Same format from io_controller
    
    // btnC reserved for reset
    assign buttons[0] = btnU;
    assign buttons[1] = btnD;
    assign buttons[2] = btnL;
    assign buttons[3] = btnR;
    
    // ================================== RESET =======================================
    
    // For now button Center is used for reset
    
    assign reset = btnC;
    
    // ================================== CPU CORE =====================================
    
    cpu_core cpu (

        .clk                 (clk),
        .reset               (reset),

        // Physical FPGA inputs
        .switches            (sw),
        .buttons             (buttons),

        // Physical FPGA output
        .leds                (led),
        .display_value       (display_value),
        .display_mode        (display_mode),

        // Debug outputs
        .halt                (halt),
        .debug_pc            (debug_pc),
        .debug_instruction   (debug_instruction),
        .debug_alu_result    (debug_alu_result),
        .debug_source_a_data (debug_source_a_data),
        .debug_source_b_data (debug_source_b_data),
        
        // UART inputs
        .uart_tx_busy        (uart_tx_busy),
        .uart_rx_data        (uart_rx_data),
        .uart_rx_valid       (uart_rx_valid),
        
        // UART outputs
        .uart_tx_data        (uart_tx_data),
        .uart_tx_start       (uart_tx_start)


    );
    // ============================ 7SEG DISPLAY ====================================
    seven_segment_display display_unit (
        .clk          (clk),
        .reset        (reset),
        .value        (display_value),
        .display_mode (display_mode),
        .seg          (seg),
        .an           (an),
        .dp           (dp)
    );
        
        
    // ========================== UART TRANSMITTER =================================


    uart_transmitter uart_tx_unit (

        .clk     (clk),
        .reset   (reset),

        .data_in (uart_tx_data),
        .start   (uart_tx_start),

        .tx      (uart_tx),
        .busy    (uart_tx_busy)

    );


    
    // =========================== UART RECEIVER ===================================

    uart_receiver uart_rx_unit (

        .clk        (clk),
        .reset      (reset),

        .rx         (uart_rx),

        .data_out   (uart_rx_data),
        .data_valid (uart_rx_valid)
    );

endmodule

/*
    
    // Detect one risinig edge of the center button.
    always_ff @(posedge clk) begin
        // If btnU is pressed, reset the stored previous state of btnC
        // This prevents accidental pulses when switches modes or resetting.
        if (btnU) begin
            btnC_previous <= 1'b0;
        end
        else begin
            // Otherwise, remember current btnU value
            btnC_previous <= btnC;
        end
    end
    
    // Generate a one clock cycle pulse when btnC goes 0 to 1
    // Used to safetly trigger one action even if button is held
    assign save_pulse = btnC & ~btnC_previous;
    
    // Store switch value into A or B 
    always_ff @(posedge clk) begin
        if (btnU) begin
            // btnU acts like a "reset" sets inputs to 0
            a_reg <= 8'h00;
            b_reg <= 8'h00;
        end
        // If a rising edge pulse on btnC occurs, save the switch value
        else if (save_pulse) begin
            // sw[12] chooses whether to load into A or B
            if (sw[12] == 1'b0)
                a_reg <= sw[7:0];
            else
                b_reg <= sw[7:0];
            end
        end
    
    // Connect ALU's input/outputs to local signals 
    alu alu_instance (
       .a(a_reg),
       .b(b_reg),
       .operation(sw[11:8]),
       .result(alu_result),
       .zero(alu_zero),
       .carry(alu_carry),
       .negative(alu_negative)
   );
   
   always_comb begin
        led = 16'h0000;
        
        led[7:0] = alu_result;
        led[8]   = alu_zero;
        led[9]   = alu_carry;
        led[10]  = alu_negative;
        
        led[14]  = sw[12];
        led[15]  = save_pulse;
    end  

endmodule
*/