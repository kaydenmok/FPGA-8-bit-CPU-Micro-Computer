# Custom 8-Bit FPGA Computer

A custom 8-bit computer designed from the ground up in **SystemVerilog** and implemented on a **Digilent Basys 3 FPGA**.

The system combines a custom CPU and 16-bit instruction set with a Python assembler, banked memory, a hardware stack, memory-mapped I/O, seven-segment display output, and bidirectional UART communication.

Assembly programs are written using the custom ISA, translated into machine code by the assembler, and loaded directly into the FPGA's instruction memory.

---

## Features

* Custom **8-bit CPU architecture**
* Custom **16-bit instruction set architecture**
* 8 general-purpose 8-bit registers
* Arithmetic and bitwise ALU operations
* Zero, carry/borrow, and negative flags
* Conditional and unconditional branching
* Hardware stack with `PUSH`, `POP`, `CALL`, and `RET`
* Nested subroutine support
* Banked data memory with a shared global address space
* Memory-mapped I/O
* Bidirectional UART with FIFO buffering and overflow detection
* Seven-segment display output
* Switch, push-button, and LED interfaces
* Custom Python assembler
* Automated assembly-to-Vivado workflow
* SystemVerilog testbenches and waveform verification
* Successfully synthesized and deployed on a Basys 3 FPGA

---

## System Architecture

The computer uses separate instruction and data memories and connects hardware peripherals through a memory-mapped I/O interface.

```text
        program.asm
             │
             ▼
       Python Assembler
             │
             ▼
         program.mem
             │
             ▼
┌─────────────────────────┐
│   Instruction Memory    │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│        CPU Core         │
│                         │
│  Program Counter        │
│  Instruction Decoder    │
│  Control Unit           │
│  Register File          │
│  ALU + Flags            │
│  Stack / SP             │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│      Data Memory        │
│    + Memory Banking     │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│    Memory-Mapped I/O    │
└────────────┬────────────┘
             │
       ┌─────┼─────────┐
       ▼     ▼         ▼
      UART  LEDs    7-Segment
```

The processor uses an **8-bit datapath** with fixed-width **16-bit instructions**. An 8-bit Program Counter addresses instruction memory, while eight general-purpose registers hold operands, results, addresses, and temporary program state.

Instructions are decoded into opcode and operand fields before the **control unit** generates the signals required for ALU operations, register writes, memory access, branching, and stack operations. The ALU performs arithmetic and logical operations and generates **zero, carry/borrow, and negative flags** for conditional execution.

The architecture uses separate instruction and data memories, following a **Harvard-style organization**. It also uses fixed-width instructions and register-based operations commonly associated with RISC-style designs, while the CPU architecture and ISA were designed specifically for this project.

---

## Memory, Stack, and I/O

The CPU uses banked data memory to expand the available memory space while keeping 8-bit addresses.

A shared global region remains accessible across banks for common system resources such as the stack and memory-mapped peripherals.

The hardware stack supports `PUSH`, `POP`, `CALL`, and `RET`, allowing temporary storage and nested subroutine calls without dedicating a general-purpose register to return addresses.

Peripherals are accessed through **memory-mapped I/O**, allowing the CPU to interact with hardware using normal load and store instructions.

Supported interfaces include:

* LEDs
* Switches
* Push buttons
* Seven-segment display
* UART

---

## UART Communication

A bidirectional UART interface allows the FPGA computer to communicate with an external PC through a serial terminal.

The UART subsystem includes dedicated transmit and receive logic, status reporting, **FIFO buffering**, and receive overflow detection.

Incoming bytes are stored in the receive FIFO so the CPU does not need to process each character immediately. Software can instead check UART status and retrieve buffered data when ready.

UART is integrated through the memory-mapped I/O system and is used extensively by the serial calculator demo for command input, ASCII processing, and numerical output.

---

## Python Assembler

A custom assembler written in Python translates the project's assembly language into the CPU's 16-bit machine-code format.

```text
program.asm
     │
     ▼
assembler.py
     │
     ▼
program.mem
     │
     ▼
Vivado Instruction Memory
```

For example:

```text
LOAD R2, 92
        ↓
1000001001011100
```

The assembler handles instruction parsing, register encoding, labels, immediates, addresses, and machine-code generation.

The workflow automatically generates the `program.mem` file used by the Vivado project, connecting the software toolchain directly to the processor hardware.

---

## Demos

### FPGA Calculator

A hardware-based calculator uses the Basys 3 switches and push buttons for input and displays results through the LEDs and seven-segment display.

The demo demonstrates:

* Arithmetic execution
* Conditional branching
* Hardware input
* Memory-mapped I/O
* Seven-segment and LED output

### UART Calculator

An interactive serial calculator accepts commands and numerical input from a PC terminal and returns results through UART.

The demo combines many of the computer's major features, including:

* UART transmit and receive
* FIFO-buffered input
* ASCII command parsing
* Arithmetic algorithms
* Conditional branching
* `CALL` and `RET`
* Hardware stack usage
* Memory banking
* Decimal-to-ASCII conversion
* Memory-mapped I/O

Implemented commands include:

`ADD` • `SUBTRACT` • `MULTIPLY` • `DIVIDE` • `MODULO` • `GCD` • `AND` • `OR` • `STATUS` • `HELP` • `HISTORY`

The UART calculator serves as the primary system-level demonstration of the completed CPU.

---

## Verification

The processor was developed incrementally, with individual hardware modules tested before integration into the complete system.

SystemVerilog testbenches and waveform simulation were used to verify:

* ALU and processor flags
* Register file
* Program Counter
* Instruction decoder
* Control unit
* Instruction memory
* Data memory
* Memory banking
* Stack operations
* CPU core
* Peripheral interfaces

The complete computer was then synthesized and deployed to the Basys 3 FPGA for hardware validation.

---

## Documentation

Additional documentation provides a deeper technical explanation of the project. These files can be found under the [`docs/`](docs/) folder.

- **Architecture & Design Breakdown** — Detailed explanation of the CPU architecture, major components, memory system, peripherals, and how the system operates.

- **Custom 8-Bit CPU Instruction Set Architecture** — Complete reference for the custom instruction set, including opcodes, instruction formats, assembly syntax, operations, and 16-bit instruction encoding.

- **FPGA I/O Memory Map** — Reference for the computer's memory-mapped I/O addresses, including LEDs, switches, pushbuttons, 7-segment display, UART, shared memory, and global stack region.

---

## Technologies

| Area            | Tools                                        |
| --------------- | -------------------------------------------- |
| FPGA            | Digilent Basys 3                             |
| Hardware Design | SystemVerilog                                |
| FPGA Toolchain  | AMD/Xilinx Vivado                            |
| Software        | Python, Custom Assembly                      |
| Verification    | SystemVerilog Testbenches, Vivado Simulation |
| Development     | Git, GitHub, Visual Studio Code              |

---

## Future Development

The CPU, memory system, assembler, stack, peripherals, and UART interface form the completed core version of the computer.

Possible future development will focus on expanding the system with:

* VGA video output
* Graphics-oriented memory and I/O
* VGA-based applications and games

# Author

Kayden Mokrytzki University of Guelph Computer Engineering Student