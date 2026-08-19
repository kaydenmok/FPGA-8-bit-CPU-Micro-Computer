from pathlib import Path

# ====================== OPCODE TABLE ======================
#
# Each assembly instruction maps to the same 5-bit opcode
# used by isa_pkg.sv inside the CPU
#
# ========================================================== 

OPCODES = {
    "ADD":   0b00000,
    "SUB":   0b00001,
    "AND":   0b00010,
    "OR":    0b00011,
    "XOR":   0b00100,

    "NOT":   0b00101,
    "INC":   0b00110,
    "DEC":   0b00111,
    "SHL":   0b01000,
    "SHR":   0b01001,
    "TEST":  0b01010,

    "JMP":   0b01011,
    "JZ":    0b01100,
    "JNZ":   0b01101,
    "JC":    0b01110,
    "JN":    0b01111,

    "LOAD":  0b10000,
    "STORE": 0b10001,
    "LOADI": 0b10010,
    "MOV":   0b10011,

    "NOP":   0b10100,
    "HALT":  0b10101,

    "IN":    0b10110,
    "OUT":   0b10111,

    "PUSH":  0b11000,
    "POP":   0b11001,

    "CALL":  0b11010,
    "RET":   0b11011
}

R_TYPE = {"ADD", "SUB", "AND", "OR", "XOR", "TEST"}
U_TYPE = {"NOT", "INC", "DEC", "SHL", "SHR"}
T_TYPE = {"PUSH", "POP"}
B_TYPE = {"JMP", "JZ", "JNZ", "JC", "JN", "CALL"}
SYSTEM_TYPE = {"NOP", "HALT", "RET"}

# Token is the function input which is a string ("R3" for example)
def parse_register(token: str) -> int:
    """
    Converts a register such as R3 to the number 3.
    Only R0 through R7 are valid because the CPU has 
    eight general-purpose registers.
    """

    # Take the uppercase version of the token and remove whitespace
    token = token.strip().upper()

    # Check if the token starts with "R" to ensure it's a register
    if not token.startswith("R"):
        raise ValueError(f"Invalid register: {token}")

    try:
        register_number = int(token[1:]) # Convert the part after "R" to an integer
        # Check if register number is a real numberin the valid range (0-7)
    except ValueError as error:
        raise ValueError(f"Invalid register number: {token}") from error
    if not (0 <= register_number <= 7):
        raise ValueError(f"Register number out of range: {token}")

    return register_number


def parse_number(token: str) -> int:
    """
    Convert a decimal, hexademical, or binary value into a integer

    Examples:
        92 -> decimal -> 92
        0x5A -> hexadecimal -> 90
        0b101010 -> binary -> 42
    """
    try:
        if token.startswith("0X"):
            # Convert hexadecimal (base 16) to decimal integer
            return int(token, 16)
            # Convert binary (base 2) to decimal integer
        elif token.startswith("0B"):
            return int(token, 2)
            # Convert decimal to integer
        else:
            return int(token)
            # Catch ValueError if the token is not a valid number
    except ValueError as error:
        raise ValueError(f"Invalid number: {token}") from error


def encode_instruction(mnemonic: str, operands: list[str]) -> int:
    """
    Translate one assembly instruction into one 16-bit value.
    """

    mnemonic = mnemonic.upper()  # Convert the mnemonic (example ADD) to uppercase for consistency

    if mnemonic not in OPCODES:
        raise ValueError(f"Unknown instruction: {mnemonic}")

    opcode = OPCODES[mnemonic]  # Get the opcode for the mnemonic

    # -----------------------------------------------------------------------------------
    # R-TYPE format:
    # [15:11] opcode | [10:8] Destination | [7:5] SourceA | [4:2] SourceB | [1:0] Extra
    # Example: ADD R3, R1, R2
    #-------------------------------------------------------------------------------------

    if mnemonic in R_TYPE:
        # ensure exactly three operands for R-TYPES
        # [ADD] = mnemonic [R3, R1, R2] = operands
        if len(operands) != 3:
            raise ValueError(
                f"{mnemonic} requires: destination, sourceA, sourceB"
            )

        destination = parse_register(operands[0])
        source_a    = parse_register(operands[1])
        source_b    = parse_register(operands[2])

        # Return the encoded instruction as a 16-bit integer
        # Shifting the opcode and operands into their respective bit positions

        # Example:
        # opcode      = 00001   |    opcode      << 11 = 00001 00000 00000
        # destination = 011     |    destination << 8  = 00000 01100 00000
        # source_a    = 001     |    source_a    << 5  = 00000 00001 00000
        # source_b    = 010     |    source_b    << 2  = 00000 00000 01000

        # The OR operation merges all parts into a final 16 bit instruction
        return (opcode << 11) | (destination << 8) | (source_a << 5) | (source_b << 2)

    # -----------------------------------------------------------------------------------
    # U-TYPE format:
    # [15:11] opcode | [10:8] Destination | [7:5] SourceA | [4:0] Extra
    # Example: NOT R3, R1
    # PUSH and POP implemented here as they can work with the same format as U-TYPE instructions
    #-------------------------------------------------------------------------------------

    if mnemonic in U_TYPE or mnemonic in T_TYPE:

        if mnemonic == "PUSH":
            # ensure exactly one operand for PUSH and POP
            if len(operands) != 1:
                raise ValueError(
                    f"{mnemonic} requires: source register"
                )

            destination = 0 # PUSH only needs a source register
            source_a = parse_register(operands[0])

            return (opcode << 11) | (destination << 8) | (source_a << 5)

        if mnemonic == "POP":
            # ensure exactly one operand for PUSH and POP
            if len(operands) != 1:
                raise ValueError(
                    f"{mnemonic} requires: destination register"
                )

            destination = parse_register(operands[0])
            source_a = 0  # For POP only destination is needed

            return (opcode << 11) | (destination << 8) | (source_a << 5)
        
        # ensure exactly two operands for U-TYPES
        if len(operands) != 2:
            raise ValueError(
                f"{mnemonic} requires: destination, sourceA"
            )

        destination = parse_register(operands[0])
        source_a    = parse_register(operands[1])

        return (opcode << 11) | (destination << 8) | (source_a << 5)

    # -----------------------------------------------------------------------------------
    # B-TYPE format:
    # [15:11] opcode | [10:3] Branch Address | [2:0] Extra
    # Example: JMP 12
    #-------------------------------------------------------------------------------------

    if mnemonic in B_TYPE:
        
        # ensure exactly one operand for B-TYPES
        if len(operands) != 1:
            raise ValueError(
                f"{mnemonic} requires: branch address"
            )

        branch_address = parse_number(operands[0])

        # Ensure the branch address is within the valid range (0-255)
        # This is because our design has 256 bytes of RAM

        if not (0 <= branch_address <= 255):
            raise ValueError(f"Branch address out of range: {branch_address}")

        return (opcode << 11) | (branch_address << 3)

    # -----------------------------------------------------------------------------------
    # LOADI format:
    # [15:11] opcode | [10:8] Destination | [7:0] Immediate Value
    # Example: LOADI R3, 42
    #-------------------------------------------------------------------------------------

    if mnemonic == "LOADI":
        # ensure exactly two operands for LOADI
        if len(operands) != 2:
            raise ValueError(
                f"{mnemonic} requires: destination, immediate value"
            )

        destination = parse_register(operands[0])
        immediate_value = parse_number(operands[1])

        if not (0 <= immediate_value <= 255):
            raise ValueError(f"Immediate value must be between 0 and 255")

        return ((opcode << 11) | (destination << 8) | (immediate_value))

    # -----------------------------------------------------------------------------------
    # MOV format:
    # [15:11] opcode | [10:8] Destination | [7:5] SourceA | [4:0] Extra
    # Example: MOV R2, R5
    # -------------------------------------------------------------------------------------

    if mnemonic == "MOV":
        if len(operands) != 2:
            raise ValueError(
                f"{mnemonic} requires: destination, sourceA"
            )

        destination = parse_register(operands[0])
        source_a = parse_register(operands[1])

        return (opcode << 11) | (destination << 8) | (source_a << 5)

    # -----------------------------------------------------------------------------------
    # LOAD and STORE format:
    # [15:11] opcode | [10:8] Register | [7:0] Memory Address
    # Example: LOAD R2, 30      STORE R2, 48
    #-------------------------------------------------------------------------------------

    if mnemonic in {"LOAD", "STORE"}:
        if len(operands) != 2:
            raise ValueError(
                f"{mnemonic} requires: register, memory address"
            )

        register = parse_register(operands[0])
        memory_address = parse_number(operands[1])

        if not (0 <= memory_address <= 255):
            raise ValueError(f"Memory address must be between 0 and 255")

        return (opcode << 11) | (register << 8) | (memory_address)

    # -----------------------------------------------------------------------------------
    # System Instructions only have an opcode
    #-------------------------------------------------------------------------------------

    if mnemonic in SYSTEM_TYPE:
        if len(operands) != 0:
            raise ValueError(
                f"{mnemonic} does not take any operands"
            )

        return (opcode << 11)

    # Not implemented Error appears
    raise NotImplementedError(
        f"Encoding for instruction {mnemonic} is not implemented yet.") 



def clean_line(line: str) -> str:
    """
    Remove comments and whitespace from a line of assembly code.
    """
    # Remove comments (anything after a semicolon)
    line = line.split(';')[0]
    # Strip leading and trailing whitespace
    return line.strip()

def is_label(line: str) -> bool:
    """
    Check if a line is a label (ends with a colon).
    """
    line = clean_line(line)
    return line.endswith(':')

def parse_line(line:str) -> tuple[str,list[str]] | None:
    """
    Convert a line such as ADD R3, R1, R2
    Into: ("ADD", ["R3", "R1", "R2"])
    """
    # Clean the line by removing comments and whitespace
    line = clean_line(line)

    if not line:
        return None # Ignore empty lines

    parts = line.split(maxsplit=1) # Split into mnemonic and operands
    mnemonic = parts[0].upper() # Convert mnemonic to uppercase

    if len(parts) == 1:
        operands = [] # No operands
    else:
        operands = [operand.strip() for operand in parts[1].split(',')]
    
    return (mnemonic, operands)

def assemble_file(input_path: Path, output_path: Path) -> None:
    """
    Assemble every instruction in the input file and write
    one 16-bit instruction per line in the output file.

    Uses two passes:
        PASS 1: Find all labels and their corresponding instruction numbers.
        PASS 2: Assemble instructions and replace label operands with their corresponding instruction numbers.
    """

    output_lines: list[str] = []
    # Python dictionary to connect label to instruction number
    # Example: {"LOOP": 5, "END": 10}
    labels: dict[str, int] = {}

    # Read the input file and split it into lines, 
    # utf-8 encoding is used to support a wide range of characters including symbols and emojis
    source_lines = input_path.read_text(encoding="utf-8").splitlines() 



    # ========================= PASS 1: Find all labels ==========================

    instruction_address = 0
    # To be finished





    # ======================== PASS 2: Assemble instructions ==========================
    for line_number, source_line in enumerate(source_lines, start=1):
        parsed = parse_line(source_line)

        if parsed is None:
            continue # Ignore empty lines

        # Parse the line into a mnemonic and operands
        mnemonic, operands = parsed

        try:
            machine_code = encode_instruction(mnemonic, operands)
        except (ValueError, NotImplementedError) as error:
            raise ValueError(f"Error on line {line_number}: {error}") from error

        binary_instruction = f"{machine_code:016b}" # Format as 16-bit binary string
        output_lines.append(binary_instruction)

        # Print the line number, source line, and binary instruction in a formatted manner
        print(
            f"{line_number:}: "
            f"{source_line:} -> {binary_instruction}"
        )

    output_path.write_text("\n".join(output_lines), encoding="utf-8") 
    # Write the output file with utf-8 encoding

    print(f"\nAssembled {len(output_lines)} instructions.")
    print(f"Output written to: {output_path}")

def choose_program(assembler_folder: Path) -> Path:
    """
    Ask user which assembly program to assembler.
    Returns full path to the selected .asm file.
    """

    print()
    print("FPGA 8-Bit Assembler - Choose a program to assemble:")
    print("=" * 53)
    print("1. Calculator")
    print("2. Snake Game")
    print()

    choice = input("Choose a program: ")

    if choice == "1":
        input_path = assembler_folder / "calculator.asm"

    elif choice == "2":
        input_path = assembler_folder / "snake.asm"

    else:
        raise ValueError("Invalid selection. Please enter 1 or 2.")

    return input_path



def main() -> None:
    """
    Main function to assemble a file.
    """

    # Determine the folder where the assembler.py file is located
    assembler_folder = Path(__file__).parent

    # Ask the user which assembly program should be assembled.
    input_path = choose_program(assembler_folder)

    # Full path to Vivado Source Folder
    vivado_source_folder = Path(r"C:\Users\kayde\MicroCompAndAssembler\FPGA_8bit_computer\project_1\project_1.srcs\sources_1\new")

    # Assemble the input file and write the output to the Vivado source folder
    output_path = vivado_source_folder / "program.mem"

    if not input_path.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")

    assemble_file(input_path, output_path)

if __name__ == "__main__":
    main()