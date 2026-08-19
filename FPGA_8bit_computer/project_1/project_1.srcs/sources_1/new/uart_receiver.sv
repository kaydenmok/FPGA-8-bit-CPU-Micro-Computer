`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// UART RECEIVER
// 
// Receives one UART byte using the standard 8-N-1 format:
// 1 Start bit
// 8 data bits
// No parity
// 1 stop bit
//
// UART data is received least-signigicant bit first
// The RX line normally sits HIGH while idle
//
// FLOW: Detect start bit, sample each data bit at the correct time, check stop bit
//       Output the byte, and signal the CPU that the byte is ready
//
// When a complete byte has been received:
//
//     data_out   = received byte
//     data_valid = HIGH for one clock cycle
//
// Example if the ASCII "A" is sent
// 'A' = 0x41 = 01000001
// UART sends
// 
// Start  |  b0 -  b7  | Stop
//   0    |  10000010  |  1
//////////////////////////////////////////////////////////////////////////////////


module uart_receiver(
    
    input logic        clk,
    input logic        reset,
    
    // Serial UART input from the external device.
    input logic        rx,
    
    // Complete received byte.
    output logic [7:0] data_out,
    
    // Pulses HIGH for one clock cycle whenever a complete valid UART byte has been recieved
    output logic       data_valid
    
    );
    
    ///////////////////////////////////////////////////////////////////////////////
    // UART CONFIGURATION
    //
    // Basys 3 clock = 100 MHz
    // UART baud rate = 115200 (one of the most common baud rates)
    // 
    // 100,000,000 / 115,200 = 868 
    //
    // Therefore each UART bit is held for approximately 868 FPGA clock cycles
    ///////////////////////////////////////////////////////////////////////////////
    localparam integer CLKS_PER_BIT = 868;
    
    
    
    // ============================= RECEIVER STATUS ================================
    typedef enum logic [2:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
        
    } state_t;
    
    state_t state;
    
    // ============================ INTERNAL SIGNALS ================================
    
    // Counts FPGA clock cycles so we know when to sample RX
    logic [9:0] baud_counter;
    
    // Tracks which data bit we are currently receiving.
    logic [2:0] bit_index;
    
    // Temporary storage for the byte currently being received.
    logic [7:0] received_data;
    
    logic rx_meta;
    logic rx_sync;

    // 2 flip flop synchronizer because rx comes from outside the FPGA clock domain
    always_ff @(posedge clk) begin
        if (reset) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end
        else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end
    
    
     // ============================ RECEIVER LOGIC ================================
     
     always_ff @(posedge clk) begin
        
        if (reset) begin
            state        <= IDLE;
            baud_counter <= 10'd0;
            bit_index    <= 3'd0;
            received_data<= 8'd0;
            data_valid   <= 1'b0;
            data_out     <= 1'b0;
        end
        
        else begin
            //data_valid should usually remain LOW
            // It becomes HIGH for only a clock cycle when a complete byte is received.
            data_valid <= 1'b0;
            
            case(state)
                // IDLE
                // UART usually sits HIGH 
                //
                // A LOW signal indicates the beginning of a possible start bit
                
                IDLE: begin
                    
                    baud_counter <= 10'd0;
                    bit_index    <= 3'd0;
                    
                    if (rx_sync == 1'b0) begin
                        state <= START_BIT;
                    end
                end
                
                // START BIT
                // Wait until approximately the middle of the start bit before checking it
                // Helps prevents false detection such as a short noise pulse.
                
                START_BIT: begin
                    if(baud_counter < (CLKS_PER_BIT / 2) - 1) begin
                        
                        baud_counter <= baud_counter + 10'b1;
                    end
                    
                    else begin
                        baud_counter <= 10'd0;
                        // A valid start bit should still be LOW at its midpoint
                        if (rx_sync == 1'b0) begin
                            state <= DATA_BITS;
                        end
                        
                        else begin
                            // False start bit
                            // Go back to idle
                            state <= IDLE;
                        end
                    end
                end
                
                // DATA BITS
                // Sample one data bit every full UART bit period
                // UART sends LSB first
                
                DATA_BITS: begin
                    if(baud_counter < CLKS_PER_BIT - 1) begin
                        baud_counter <= baud_counter + 10'b1;
                    end
                    
                    else begin
                        baud_counter <= 10'd0;
                        
                        // Store the current received bit 
                        received_data[bit_index] <= rx_sync;
                        
                        // Check if all 8 bits have been processed 
                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state <= STOP_BIT;
                        end
                        
                        else begin
                            bit_index <= bit_index + 3'd1;
                        end
                    end
                end
                
                // STOP_BIT
                // Wait one more UART bit period and verify that the stop bit is HIGH
                
                STOP_BIT: begin
                    if(baud_counter < CLKS_PER_BIT - 1) begin
                        baud_counter <= baud_counter + 10'b1;
                    end
                    
                    else begin
                        baud_counter <= 10'd0;
                        
                        if (rx_sync == 1'b1) begin
                            // Complete byte received successfully.
                            data_out  <= received_data;
                            
                            // Tell the rest of the computer that a new byte is available
                            data_valid <= 1'b1;
                        end
                        
                        // Whether the stop bit was valid or not
                        // Return to IDLE and wait for another byte
                        state <= IDLE;
                    end
                end
                
                
                // SAFE DEFAULT
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end                                      
endmodule
