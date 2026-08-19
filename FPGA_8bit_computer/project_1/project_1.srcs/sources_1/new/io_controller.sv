`timescale 1ns / 1ps

// I/O CONTROLLER
// This module handles memory-mapped input/output from the FPGA board
//
// The CPU uses the 8-bit address bus for both:
// 1. Normal RAM
// 2. Hardware peripherals
//
// The address determines what device the CPU is accessing
// 
// Memory map:
// 0x00 - 0xEF : Data RAM
//
// 0xF0 : LEDs 7-0
// 0xF1 : LEDs 15-8
//
// 0xF2 : Switches 7-0
// 0xF3 : Switches 15-8
//
// 0xF4 : Pushbuttons
//
// 0xF5 : 7-Segment 4-digit display
//
// 0xF6 : UART Tranmsmitter Data
// 0xF7 : UART Status
// 0xF8 : UART Receiver
//
// EXAMPLES:
// STORE R1, 0xF0 -----> LEDs 7-0 Shine the value of R1
//
// LOAD R1, 0xF2 ------> R1 gets value of switches 7-0


module io_controller(
    
    // CPU signals
    input logic        clk,
    input logic        reset,
    
    input logic [7:0]  address,
    input logic [7:0]  write_data,
    input logic        write_enable,
    input logic        read_enable,
    
    // Physical FPGA inputs
    input logic [15:0] switches,
    input logic [3:0]  buttons,
    
    // UART inputs
    input logic        uart_tx_busy,
    input logic [7:0]  uart_rx_data,
    input logic        uart_rx_valid,
    
    // Physical FPGA outputs
    output logic [15:0] leds,
    
    // Data returned back to the CPU during LOAD
    output logic [7:0] read_data,
    
    // Tells the CPU whether this address belongs to I/O
    output logic       io_selected,
    
    // 7-segment display
    output logic [7:0] display_value,
    
    // UART outputs
    output logic [7:0] uart_tx_data,
    output logic       uart_tx_start
    );
    
    // INTERNAL SIGNALS
    
    // UART receiver FIFO 
    // The fifo can hold up to 8 received bytes.
    // This prevents a new UART byte from immediately overwriting a byte that the CPU
    // has yet to read.
    logic [7:0]        rx_fifo [0:7];
    
    // Points to the FIFO location where the next received byte is stored.
    logic [2:0]        rx_write_pointer;
    // Points to the oldest FIFO byte waiting for the CPU
    logic [2:0]        rx_read_pointer;
    
    // Number of bytes currently stored in the FIFO.
    //
    // Needs 4 bits because the value can range 0 to 8.
    logic [3:0]        rx_count;
    
    // Detect when a new byte arrives when FIFO is full and the CPU is not reading it
    // This tells us that UART data is being lost as it cannot be stored.
    logic              rx_overflow;
    
    
    // ========================== I/O ADDRESS DETECTION =============================
    // Any address from F0 (240) to FF (256) is consider I/O space
    // The first four bits of these addresses will always be 1111_XXXX
    // Therefore, we only need to check the upper four bits
    assign io_selected = (address[7:4] == 4'hF);
    
    
    // ============================= OUTPUT REGISTERS ================================
    // LEDS must remember the last value written by the CPU
    // This is why they use registers rather than simply being connected directly to write_data
    
    always_ff @(posedge clk) begin
        
        if (reset) begin
            leds          <= 16'b0;
            display_value <= 8'b0;
            
            uart_tx_data  <= 8'b0;
            uart_tx_start <= 1'b0;
        end
        
        // UART should normally stay LOW
        // It is only pulsed HIGH for one clock cycle to start writing
        else begin
            uart_tx_start <= 1'b0;
        
        if (write_enable && io_selected) begin
            
            case(address)
              
                // Bottom 8 LEDS
                8'hF0: begin
                    leds[7:0]     <= write_data;
                end
                
                // Top 8 LEDS
                8'hF1: begin
                    leds[15:8]    <= write_data;
                end
                
                // 7-Segment Display
                8'hF5: begin
                    display_value <= write_data;
                end
                
                // UART transmitter
                // Writing a byte to address F6 stores the byte and generates
                // a start pulse.
                // Only begin a new transmission if UART is free.
                8'hF6: begin
                
                    if (!uart_tx_busy) begin
                        uart_tx_data  <= write_data;
                        uart_tx_start <= 1'b1;
                    end
                end
                        
                default: begin
                   // Do nothing
                end
            endcase
            end
        end
    end
    
    // ============================== UART RX FIFO =================================
    //
    // The UART receiver produces uart_rx_valid for one clock cycle. 
    // whenever a complete byte has been received.
    //  
    // Instead of requiring the CPU to notice that one-clock pulse, the received byte is 
    // placedd into this FIFO (first-in, first-out order).
    // 
    // This allows several UART bytes to arrive before the CPU gets around to reading
    // them.
    
    always_ff @(posedge clk) begin
        if (reset) begin
            
            rx_write_pointer <= 3'd0;
            rx_read_pointer  <= 3'd0;
            rx_count         <= 4'd0;
            
            rx_overflow      <= 1'b0;
        end
        
        else begin
            // RECEIVE AND READ AT THE SAME TIME
            //
            // A new UART byte arrives on the same clock that the CPU 
            // reads an existing byte.
            //
            // One byte enters and one byte leaves, so rx_count does not
            // need to change.
            
            if (uart_rx_valid && read_enable && io_selected && address == 8'hF8 && rx_count > 0) begin
            
            // Store the newly received byte. 
            rx_fifo[rx_write_pointer] <= uart_rx_data;
            rx_write_pointer++;
            
            // Remove the oldest byte
            rx_read_pointer++;
            
            // rx_count stays the same
        end
        
        // RECEIVE BYTE
        //
        // Store a newly received UART byte if there is room available inside the FIFO
        
        else if (uart_rx_valid && rx_count < 4'd8) begin
            rx_fifo[rx_write_pointer] <= uart_rx_data;
            rx_write_pointer++;
            rx_count++;
            
        end
        
        // FIFO OVERFLOW
        // A new UART byte arrived but FIFO is full and CPU did not remove any bytes
        else if (uart_rx_valid && rx_count == 4'd8) begin
            rx_overflow <= 1'b1;
        end
        
        // CPU READ BYTE
        // Reading address F8 removes the oldest byte from the FIFO
        
        else if (read_enable && io_selected && address == 8'hF8 && rx_count > 0) begin
            rx_read_pointer++;
            rx_count--;
        end
        
        // CLEAR OVERFLOW FLAG
        // Writing toe the UART status register clears the overflow flag
        // Example: 
        // STORE R0, 0xF7
        // The actual value written does not matter.
        
        if (write_enable && io_selected && address == 8'hF7) begin
            rx_overflow <= 1'b0;
        end
    end
end
            
    // ============================= INPUT  REGISTERS ================================
    // Switches and Buttons already physically hold their state,
    // We do not need to stoe them in internal registers.
    //
    // The CPU reads whichever input corresponds to the current address
    //
    // The FIFO for UART stores bytes until the CPU reads them.
    
    always_comb begin
        
        // Default value if an unused I/O address is read.
        read_data = 8'b0;
        
        if (read_enable && io_selected) begin
        
            case(address)
                
                // Bottom 8 switches
                8'hF2: begin
                    read_data = switches[7:0];
                end
                
                // Top 8 switches
                8'hF3: begin
                    read_data = switches[15:8];
                end
                
                // Five buttons packed into the lower five bits.
                //
                // Center Button used for reset
                // read_data[0] = up
                // read_data[1] = down
                // read_data[2] = left
                // read_data[3] = right
                //
                // Upper four bits are unused                
                8'hF4: begin
                    read_data = {4'b0000, buttons};
                end
                
                // UART status register / Control
                // bit 0: TX busy signal
                //   0 = UART transmitter ready, 1 = UART currently transmitting
                //
                // bit 1: RX data available
                //   0 = RX FIFO empty, 1 = at least one received byte is waiting
                //
                // bit 2: RX FIFO full
                //   0 = FIFO has space, 1 = all 8 FIFO locations are occupied
                //
                // bit 3: RX overflow
                //   0 = not losing data, 1 = losing new data
                //
                // WRITE: clear RX overflow flag
                
                8'hF7: begin
                    read_data = {4'b0000, 
                    rx_overflow, (rx_count == 4'd8), (rx_count > 4'd0), uart_tx_busy};
                end
                
                // UART RECEIVER DATA
                // Returns the oldest byte currently stored in the FIFO
                // If the FIFO is empty, return 0.
                //
                // The sequential FIFO logic above advances the read pointer
                // after the CPU performs this read. 
                
                8'hF8: begin
                    if(rx_count > 4'd0) begin
                        read_data = rx_fifo[rx_read_pointer];
                    end
                    
                    else begin
                        read_data = 8'd0;
                    end
                end 
                default: begin
                    read_data = 8'b0;
                end              
            endcase
         end
      end 
      
endmodule
