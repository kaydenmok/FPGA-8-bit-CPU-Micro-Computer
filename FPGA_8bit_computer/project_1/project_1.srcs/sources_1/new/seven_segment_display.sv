`timescale 1ns / 1ps
// FOUR-DIGIT SEVEN-SEGMENT DISPLAY
//
// Displays one 8-bit value in hexadecimal.
//
// Example:
//
// input value = 8'hAC
//
// Display:
//
// 0 0 A C
//
// The Basys 3 seven-segment display is multiplexed.
// Only one digit is enabled at a time, but the module rapidly
// cycles through all four digits so they appear continuously lit.


module seven_segment_display(
    input logic       clk,
    input logic       reset,
    
    // 0 - Hexadecimal
    // 1 - Timer
    input logic       display_mode,
    
    // 8bit value written by the CPU 
    input logic [7:0] value,
    
    // Seven segment outputs: a, b, c, d, e, f, g
    // Decides which segments light up
    output logic [6:0] seg,
    
    // Digit enables for the four display digits
    // Anode (+) to choose each digit an3, an2, an1, an0
    output logic [3:0] an,
    
    // Decimal Point output
    output logic       dp
    );
    
    // Counter used to slow the 100 MHz FPGA clock down enough
    // for display multiplexing
    logic [17:0]       refresh_counter;
    
    // Selects which digit is currectly active
    logic [1:0]        digit_select;
    
    // Four bit value currently being converted to a hex digit
    logic [3:0]        current_digit;
    
    logic [3:0] seconds_ones;
    logic [3:0] seconds_tens;
    logic [3:0] tenths;

    always_comb begin
        seconds_tens = (value / 100) % 10;
        seconds_ones = (value / 10) % 10;
        tenths       = value % 10;
    end
    
    // ============================== REFRESH COUNTER ====================================
    
    always_ff @(posedge clk) begin
        if (reset) begin
            refresh_counter <= 18'd0;
        end
        else begin
            refresh_counter <= refresh_counter + 1'b1;
        end
    end
    // Use the upper counter bits so the digit selection changes
    // much more slowly than the 100 MHz system clock.
    // Has to count up to 65,536 clock cycles about 2.62 ms for all four digits to refresh
    assign digit_select = refresh_counter[17:16];
    
    // ============================== DIGIT SELECTION ====================================
    
    always_comb begin
        // Safe defaults 
        an            = 4'b1111;
        current_digit = 4'h0;
        dp            = 1'b1;  // Active low: 1 = OFF
        
        if (display_mode == 1'b0) begin
        // =================== HEX MODE =======================
        // 8'hAC -> 00AC
        
        case (digit_select)
            2'b00: begin
                an            = 4'b1110;
                current_digit = value[3:0];
            end
            
            // Second digit
            2'b01: begin
                an            = 4'b1101;
                current_digit = value[7:4];
            end
            
            // Third digit: show zero for now
            2'b10: begin
                an            = 4'b1011;
                current_digit = 4'h0;
            end
            
            // Four digit: show zero for now
            2'b11: begin
                an            = 4'b0111;
                current_digit = 4'h0;
            end
            
            default: begin
                an            = 4'b1111;
                current_digit = 4'h0;
            end
        endcase
     end
     
     else begin
        // ================== TIMER MODE =======================
        // value = number of tenths of a second
        // Example: value = 24 - > 2.4 seconds
        
        case (digit_select)
            // Tenths
            2'b00: begin
                an            = 4'b1110;
                current_digit = tenths;
            end
            
            // Seconds tens digit
            2'b01: begin
                an            = 4'b1101;
                current_digit = seconds_ones;
                dp            = 1'b0; // Decimal point ON
            end
            
            // Seconds tens digit
            2'b10: begin
                an            = 4'b1011;
                current_digit = seconds_tens;
            end

            // Leftmost digit unused
            2'b11: begin
                an            = 4'b0111;
                current_digit = 4'h0;
            end

            default: begin
                an            = 4'b1111;
                current_digit = 4'h0;
                dp            = 1'b1;
            end
        endcase
    end
end
         
     
     // ============================== DIGIT SELECTION ====================================
     
     always_comb begin
        case (current_digit)

            // seg[6:0] = {g, f, e, d, c, b, a}
            // 0 = segment ON, 1 = segment OFF
            //
            //       a
            //     -----
            //  f |     | b
            //    |  g  |
            //     -----
            //  e |     | c
            //    |     |
            //     -----
            //       d
            //

            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;

            default: seg = 7'b1111111;

        endcase
    end
endmodule
