`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// UART TRANSMITTER MODULE
//
// Sends one 8-bit byte serially using UART.
//
// UART format:
//     1 Start Bit
//     8 Data Bits
//     No Parity
//     1 Stop Bit
//
// 8-N-1 format
//
// UART idles HIGH.
// Data bits are transmitted least-significant bit first.
//
// Example:
// data_in = 8'h41 = ASCII 'A'
//
// Frame:
//
// Idle | Start | 1 0 0 0 0 0 1 0 | Stop
//   1      0                        1
//
//////////////////////////////////////////////////////////////////////////////////

module uart_transmitter(

    input  logic       clk,
    input  logic       reset,

    // Byte to transmit.
    input  logic [7:0] data_in,

    // One-clock pulse telling UART to begin transmission.
    input  logic       start,

    // Serial UART output.
    output logic       tx,

    // HIGH while a UART frame is being transmitted.
    output logic       busy
);


///////////////////////////////////////////////////////////////////////////////
// UART CONFIGURATION
//
// Basys 3 clock = 100 MHz
// UART baud rate = 115200
//
// 100,000,000 / 115,200 = approx 868
///////////////////////////////////////////////////////////////////////////////

localparam integer CLKS_PER_BIT = 868;


// ============================ INTERNAL SIGNALS ================================

// Counts FPGA clocks for each UART bit.
logic [9:0] baud_counter;

// Tracks position inside the 10-bit UART frame.
//
// 0     = Start bit
// 1 - 8 = Data bits 0 - 7
// 9     = Stop bit
logic [3:0] bit_index;

// Holds the byte for the entire transmission.
logic [7:0] transmit_data;


// ============================ TRANSMISSION LOGIC ==============================

always_ff @(posedge clk) begin

    if (reset) begin

        // UART line idles HIGH.
        tx            <= 1'b1;
        busy          <= 1'b0;
        baud_counter  <= 10'd0;
        bit_index     <= 4'd0;
        transmit_data <= 8'd0;

    end

    else begin

        // ========================================================
        // START NEW TRANSMISSION
        // ========================================================

        if (!busy && start) begin

            // Save the byte being transmitted.
            transmit_data <= data_in;

            busy         <= 1'b1;
            baud_counter <= 10'd0;
            bit_index    <= 4'd0;

            // Frame position 0 = start bit.
            tx <= 1'b0;

        end


        // ========================================================
        // TRANSMISSION ACTIVE
        // ========================================================

        else if (busy) begin

            // Hold current UART bit for exactly CLKS_PER_BIT clocks.
            if (baud_counter < CLKS_PER_BIT - 1) begin
                baud_counter <= baud_counter + 10'd1;
            end

            else begin
                baud_counter <= 10'd0;


                // =================================================
                // START BIT FINISHED
                //
                // Next bit is data bit 0.
                // =================================================

                if (bit_index == 4'd0) begin
                    bit_index <= 4'd1;
                    tx <= transmit_data[0];
                end


                // =================================================
                // DATA BITS
                //
                // bit_index 1 currently represents data bit 0,
                // bit_index 2 represents data bit 1, etc.
                // =================================================

                else if (bit_index < 4'd8) begin

                    bit_index <= bit_index + 4'd1;
                    tx <= transmit_data[bit_index];

                end


                // =================================================
                // DATA BIT 7 FINISHED
                //
                // Begin stop bit.
                // =================================================

                else if (bit_index == 4'd8) begin

                    bit_index <= 4'd9;
                    tx <= 1'b1;
                end

                // =================================================
                // STOP BIT FINISHED
                // =================================================

                else begin
                    busy      <= 1'b0;
                    bit_index <= 4'd0;

                    // Return to UART idle.
                    tx <= 1'b1;
                end
            end
        end

        // ========================================================
        // IDLE
        // ========================================================

        else begin
            tx <= 1'b1;

        end
    end
end

endmodule