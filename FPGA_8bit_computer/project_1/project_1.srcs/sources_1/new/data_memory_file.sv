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
    
    // Selects one of the 256 memory locations in one of the 4 banks
    input logic [7:0]   address,
    input logic [1:0]   bank_select,
    
    // Value to store into memory
    input logic [7:0]   write_data,
    
    // HIGH = write write_data into memory[address].
    input logic         write_enable,
    
    // Value currently stored at memory[address].
    output logic [7:0]  read_data
    );
    
    // 4 sets of 256 locations each able to hold an 8-bit value
    // 200-255 is globally shared in all 4 banks
    logic [7:0] memory [1023:0];
    
    // physical address used to get memory address and bank number
    logic [9:0] physical_address;
    
    // ============== BANKING LOGIC ======================
 
    always_comb begin
        if (address < 8'd200) begin
            physical_address = {bank_select, address};
        end
        else begin
            physical_address = {2'b00, address};
        end
    end
    
    // ================ MEMORY READ ======================
    assign read_data = memory[physical_address];
    
    // ================ MEMORY WRITE =====================
    always_ff @(posedge clk) begin
        
        if (write_enable) begin
            memory[physical_address] <= write_data;
        end
    end 
    
    // ===================================================
    
    // =============== ASCII UART DEMO ===================

initial begin
    memory[100] = "H";
    memory[101] = "-";
    memory[102] = "H";
    memory[103] = "E";
    memory[104] = "L";
    memory[105] = "P";
    memory[106] = 8'd13;
    memory[107] = 8'd10;

    memory[108] = "%";
    memory[109] = "-";
    memory[110] = "M";
    memory[111] = "O";
    memory[112] = "D";
    memory[113] = 8'd13;
    memory[114] = 8'd10;

    memory[115] = "G";
    memory[116] = "-";
    memory[117] = "G";
    memory[118] = "C";
    memory[119] = "D";
    memory[120] = 8'd13;
    memory[121] = 8'd10;

    memory[122] = "M";
    memory[123] = "-";
    memory[124] = "S";
    memory[125] = "T";
    memory[126] = "A";
    memory[127] = "T";
    memory[128] = "U";
    memory[129] = "S";
    memory[130] = 8'd13;
    memory[131] = 8'd10;

    memory[132] = "A";
    memory[133] = "-";
    memory[134] = "A";
    memory[135] = "D";
    memory[136] = "D";
    memory[137] = 8'd13;
    memory[138] = 8'd10;

    memory[139] = "B";
    memory[140] = "-";
    memory[141] = "S";
    memory[142] = "U";
    memory[143] = "B";
    memory[144] = 8'd13;
    memory[145] = 8'd10;

    memory[146] = "*";
    memory[147] = "-";
    memory[148] = "M";
    memory[149] = "U";
    memory[150] = "L";
    memory[151] = 8'd13;
    memory[152] = 8'd10;

    memory[153] = "/";
    memory[154] = "-";
    memory[155] = "D";
    memory[156] = "I";
    memory[157] = "V";
    memory[158] = 8'd13;
    memory[159] = 8'd10;

    memory[160] = "&";
    memory[161] = "-";
    memory[162] = "A";
    memory[163] = "N";
    memory[164] = "D";
    memory[165] = 8'd13;
    memory[166] = 8'd10;

    memory[167] = "|";
    memory[168] = "-";
    memory[169] = "O";
    memory[170] = "R";
    memory[171] = 8'd13;
    memory[172] = 8'd10;

    memory[173] = "Y";
    memory[174] = "-";
    memory[175] = "H";
    memory[176] = "I";
    memory[177] = "S";
    memory[178] = "T";
    memory[179] = "O";
    memory[180] = "R";
    memory[181] = "Y";
    memory[182] = 8'd13;
    memory[183] = 8'd10;

    // End marker
    memory[184] = 8'd0;
end
            
            

endmodule
