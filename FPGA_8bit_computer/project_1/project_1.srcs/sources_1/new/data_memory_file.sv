`timescale 1ns / 1ps
// DATA MEMORY 
//
// This module stores normal program data.
// Unlike instructino memory, which stores 16-bit instructions,
// data memory stores 8-bit values because this is an 8-bit CPU.
//
// Address range:
// 0 - 255
//
// Each address stores:
// 8 bits
//
// Example:
// 
// memory[10] = 25
//
// If address = 10
// read_data will output 25
//
// Writing only happens on the rising edge of the clock when
// write_enable is HIGH.
//
// Reading is combinational, meaning read_data changes immediately when the
// address changes. 
//
// UART CALCULATOR DEMO HELP COMMAND STRINGS :
// Addresses 112 - 207
// Must contain all functions of the UART demo for when H (help) is recieved from the terminal
// EXAMPLE:
// H HELP
// A ADD
// D SUB
// S STATUS
// Etc...

module data_memory_file(
    input logic         clk,
    
    // Selects one of the 256 memory locations
    input logic [7:0]   address,
    
    // Value to store into memory
    input logic [7:0]   write_data,
    
    // HIGH = write write_data into memory[address].
    input logic         write_enable,
    
    // Value currently stored at memory[address].
    output logic [7:0]  read_data
    );
    
    // 256 locations each with an 8-bit value
    logic [7:0] memory [255:0];
    
    // ================ MEMORY READ ======================
    assign read_data = memory[address];
    
    // ================ MEMORY WRITE =====================
    always_ff @(posedge clk) begin
        
        if (write_enable) begin
            memory[address] <= write_data;
        end
    end 
    
    // ===================================================
    
    // =============== ASCII UART DEMO ===================

    initial begin
        memory[112] = "H";
        memory[113] = "-";
        memory[114] = "H";
        memory[115] = "E";
        memory[116] = "L";
        memory[117] = "P";
        memory[118] = 8'd13; // (move cursor to start of line)
        memory[119] = 8'd10; // (make a new line)

        memory[120] = "S";
        memory[121] = "-";
        memory[122] = "S";
        memory[123] = "T";
        memory[124] = "A";
        memory[125] = "T";
        memory[126] = "U";
        memory[127] = "S";
        memory[128] = 8'd13;
        memory[129] = 8'd10;

        memory[130] = "+";
        memory[131] = "-";
        memory[132] = "I";
        memory[133] = "N";
        memory[134] = "C";
        memory[135] = 8'd13;
        memory[136] = 8'd10;

        memory[137] = "-";
        memory[138] = "-";
        memory[139] = "D";
        memory[140] = "E";
        memory[141] = "C";
        memory[142] = 8'd13;
        memory[143] = 8'd10;

        memory[144] = "M";
        memory[145] = "-";
        memory[146] = "S";
        memory[147] = "E";
        memory[148] = "L";
        memory[149] = "E";
        memory[150] = "C";
        memory[151] = "T";
        memory[152] = 8'd13;
        memory[153] = 8'd10;

        memory[154] = "A";
        memory[155] = "-";
        memory[156] = "A";
        memory[157] = "D";
        memory[158] = "D";
        memory[159] = 8'd13;
        memory[160] = 8'd10;

        memory[161] = "B";
        memory[162] = "-";
        memory[163] = "S";
        memory[164] = "U";
        memory[165] = "B";
        memory[166] = 8'd13;
        memory[167] = 8'd10;

        memory[168] = "&";
        memory[169] = "-";
        memory[170] = "A";
        memory[171] = "N";
        memory[172] = "D";
        memory[173] = 8'd13;
        memory[174] = 8'd10;

        memory[175] = "|";
        memory[176] = "-";
        memory[177] = "O";
        memory[178] = "R";
        memory[179] = 8'd13;
        memory[180] = 8'd10;

        memory[181] = "X";
        memory[182] = "-";
        memory[183] = "X";
        memory[184] = "O";
        memory[185] = "R";
        memory[186] = 8'd13;
        memory[187] = 8'd10;

        memory[188] = "N";
        memory[189] = "-";
        memory[190] = "N";
        memory[191] = "O";
        memory[192] = "T";
        memory[193] = 8'd13;
        memory[194] = 8'd10;

        memory[195] = "Y";
        memory[196] = "-";
        memory[197] = "H";
        memory[198] = "I";
        memory[199] = "S";
        memory[200] = "T";
        memory[201] = "O";
        memory[202] = "R";
        memory[203] = "Y";
        memory[204] = 8'd13;
        memory[205] = 8'd10;

        memory[206] = 8'd0; // Finish!
    end
            
            

endmodule
