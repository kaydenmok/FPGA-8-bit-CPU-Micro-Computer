START:
BANK 0
LOADI R3, 0 ; Initalize R3 to 0 as it will be source A
LOADI R4, 0 ; Initalize R4 to 0 as it will be source B

JMP STARTUP_TEXT  ; Print startup text and skip functions

; ==================== FUNCTIONS =====================
; --- 1. WAIT FOR RX BYTE (Wait for external to send a byte) ---
WAIT_RX:
LOAD R0, 247     ; Ready UART status: 0000_0010
LOADI R1, 2      ; RX-ready mask 0000_0010
AND R0, R0, R1   ; Keep bit 1
JZ WAIT_RX       ; No byte yet -> keep waiting
RET

; --- 2. WAIT FOR TX READY (Wait for external ready to receive a byte) ---
WAIT_TX:
LOAD R0, 247     ; Ready UART status: 0000_0001
LOADI R1, 1      ; TX-ready mask 0000_0001
AND R0, R0, R1   ; Keep bit 0
JNZ WAIT_TX      ; Not ready yet -> keep waiting
RET

; --- 3. UPDATE SOURCE A AND B ---
UPDATE_SOURCES:
LOAD R3, 243    ; LOAD source A from switches
LOAD R4, 242    ; LOAD source B from switches
RET

; --- 4. CREATE A NEW LINE ---
CREATE_NEWLINE:
LOADI R7, 13        ; move cursor to start of line
CALL WAIT_TX    
STORE R7, 246       ; send to terminal

LOADI R7, 10        ; move cursor down a line
CALL WAIT_TX
STORE R7, 246       ; send to terminal
RET

; --- 5. TRANSLATE RESULTS TO ASCII ---
; Print an 8-bit number to UART as a decimal
; R3 = Hundreds digit
; R4 = Tens digit
; R2 = Remaining value / Ones
; Note R2 is modified by this function
PRINT_NUMBERS:
; Start digit counters at zero
LOADI R3, 0     ; HUNDREDS
LOADI R4, 0     ; TENS

; HUNDREDS | Keep subtracting 100 until subtraction borrows
HUNDREDS_LOOP:
LOADI R6, 100
SUB R2, R2, R6

; If subtraction succeeded, count another hundred
JC HUNDRED_PASS

; Subtraction went too far. 
; Restore the 100 that was just subtracted
ADD R2, R2, R6
JMP HUNDREDS_DONE

HUNDRED_PASS:
INC R3, R3
JMP HUNDREDS_LOOP
HUNDREDS_DONE:

; TENS | R2 now has a value 0-99, repeatedly subtract 10
TENS_LOOP:
LOADI R6, 10
SUB R2, R2, R6

JC TEN_PASS

; Went below zero so restore the 10
ADD R2, R2, R6
JMP TENS_DONE

TEN_PASS:
INC R4, R4
JMP TENS_LOOP
TENS_DONE:

; PRINT HUNDREDS | Dont print if zero
LOADI R6, 0 
SUB R5, R3, R6
JZ SKIP_HUNDREDS

; Converts hundreds to ASCII
LOADI R6, 48
ADD R5, R3, R6

CALL WAIT_TX
STORE R5, 246
SKIP_HUNDREDS:

; PRINT TENS | Print tens if hundreds != 0 or tens != 0
; Check if hundreds was non-zero
LOADI R6, 0
SUB R5, R3, R6
JNZ PRINT_TENS

; Hundreds = 0, so check tens
SUB R5, R4, R6
JZ SKIP_TENS

PRINT_TENS:
LOADI R6, 48
ADD R5, R4, R6

CALL WAIT_TX
STORE R5, 246

SKIP_TENS:

; PRINT ONES
; Ones are ALWAYS printed even 0
LOADI R6, 48
ADD R5, R2, R6
CALL WAIT_TX
STORE R5, 246
RET

; --- 6. SAVE LAST 3 RESULTS IN HISTORY ---
SAVE_HISTORY:
; RAM:
; 90 = Newest
; 91 = Previous
; 92 = Oldest
LOAD R5, 91     ; History 2 -> History 3
STORE R5, 92

LOAD R5, 90     ; History 1 -> History 2
STORE R5, 91

STORE R2, 90    ; New result -> History 1
RET

; --- 7. SEND ASCII CHARACTER (R6 value) ---
SEND_CHAR_R6:
CALL WAIT_TX
STORE R6, 246
RET

; --- 8. REUSEABLE MODULO CALCULATOR ---
; Used both for MOD and GDC calculations.
; R2 is Changed
; Check if B == 0, if so, MOD is undefined, return 0
CALC_MOD:
LOADI R6, 0
SUB R6, R4, R6
JZ MOD_ZERO

OR R2, R3, R3       ; Copy A into R2 so R2 becomes the remainder after repeated subtractions
MOD_LOOP:
SUB R2, R2, R4      ; Remainder -= B
JC MOD_PASS         ; Succesful subtraction / no borrow

ADD R2, R2, R4      ; Went below zero, restore one B subtraction
JMP MOD_DONE

MOD_PASS:
JMP MOD_LOOP

MOD_ZERO:
LOADI R2, 0          ; Return/Display 0 for modulo by zero

MOD_DONE:
RET

; --- 9. OUTPUT RESULTS TO UART ---
OUTPUT_RESULTS:
CALL SAVE_HISTORY
CALL CREATE_NEWLINE
CALL PRINT_NUMBERS
RET

;=====================================================

; STARTUP TEXT
STARTUP_TEXT:
CALL CREATE_NEWLINE
LOADI R6, 100     ; Pointer to H-HELP text in RAM
LOADI R5, 108     ; Pointer to the end of the Help string
STARTUP_LOOP:
CALL WAIT_TX      ; Wait for TX ready
LOADR R7, R6      ; pointer to first char in RAM
STORE R7, 246     ; Send char through UART

INC R6, R6            ; Move to next char in RAM
SUB R3, R6, R5        ; Check if we reached the end of the string
JNZ STARTUP_LOOP      ; If not, keep printing


; ==================== MAIN LOOP =====================
CHECK_INPUTS:
CALL WAIT_RX      ; Wait for RX ready
LOAD R1, 248      ; Read received char from UART RX FIFO

; CHECK H - HELP
LOADI R2, 72
SUB R3, R1, R2
JZ CALL_HELP

; CHECK % - MODULO
LOADI R2, 37
SUB R3, R1, R2
JZ CALL_MOD

; CHECK G - GCD
LOADI R2, 71
SUB R3, R1, R2
JZ CALL_GCD

; CHECK M - STATUS
LOADI R2, 77
SUB R3, R1, R2
JZ CALL_STATUS

; CHECK A - ADD
LOADI R2, 65
SUB R3, R1, R2
JZ CALL_ADD

; CHECK B - SUB
LOADI R2, 66
SUB R3, R1, R2
JZ CALL_SUB

; CHECK * - MUL
LOADI R2, 42
SUB R3, R1, R2
JZ CALL_MUL

; CHECK / - DIV
LOADI R2, 47
SUB R3, R1, R2
JZ CALL_DIV

; CHECK & - AND
LOADI R2, 38
SUB R3, R1, R2
JZ CALL_AND

; CHECK | - OR
LOADI R2, 124
SUB R3, R1, R2
JZ CALL_OR

; CHECK Y - HISTORY
LOADI R2, 89
SUB R3, R1, R2
JZ CALL_HISTORY

JMP CHECK_INPUTS  ; If not recognized, keep waiting for input

; =================== COMMANDS =====================

; =================== HELP =========================
CALL_HELP:
; H-HELP, print help text with all possible commands
LOADI R6, 108   ; Pointer to H-HELP text in RAM
LOADI R5, 184   ; Pointer to the end of the Help string

HELP_LOOP:
CALL WAIT_TX      ; Wait for TX ready
; LOOP THROUGH MEMORY
LOADR R7, R6      ; pointer to first char in RAM
STORE R7, 246     ; Send char through UART

INC R6, R6         ; Move to next char in RAM
SUB R3, R6, R5     ; Check if we reached the end of the strings
JNZ HELP_LOOP      ; If not, keep printing
JMP CHECK_INPUTS   ; After printing help, go back to waiting for input

; =================== ADD ==========================
CALL_ADD:
CALL UPDATE_SOURCES
ADD R2, R3, R4
CALL SAVE_HISTORY
CALL CREATE_NEWLINE
CALL PRINT_NUMBERS
JMP CHECK_INPUTS

; =================== SUB ==========================
CALL_SUB:
CALL UPDATE_SOURCES
SUB R2, R3, R4
CALL SAVE_HISTORY
CALL CREATE_NEWLINE
CALL PRINT_NUMBERS
JMP CHECK_INPUTS

; =================== MUL ==========================
CALL_MUL:
CALL UPDATE_SOURCES
LOADI R5, 0     ; Start result at 0
OR R7, R4, R4   ; Copy B into counter

; Check if B is zero
LOADI R6, 0
SUB R2, R7, R6
JZ MUL_DONE

MUL_LOOP:
ADD R5, R5, R3  ; Result = result + A
DEC R7, R7      ; Loop until B reaches 0 

LOADI R6, 0
SUB R2, R7, R6
JNZ MUL_LOOP

MUL_DONE:
OR R2, R5, R5 ; copy result into PRINT_NUMBERS input
CALL OUTPUT_RESULTS
JMP CHECK_INPUTS

; =================== DIV ==========================
CALL_DIV:
CALL UPDATE_SOURCES

; Check if B is 0 
LOADI R6, 0 
SUB R6, R4, R6
JZ DIV_ZERO

; Initalize Division
LOADI R7, 0    ; Quotient = 0
OR R2, R3, R3  ; Remainder = A

DIV_LOOP:
SUB R2, R2, R4      ; Remainder -= B
JC DIV_PASS         ; Succesful subtraction / no borrow

ADD R2, R2, R4      ; Went below zero, restore one B subtraction
JMP DIV_DONE

DIV_PASS:
INC R7, R7          ; Increment quotient
JMP DIV_LOOP

DIV_ZERO:
LOADI R2, 0         ; Return/display 0 for divide by zero
CALL CREATE_NEWLINE
CALL PRINT_NUMBERS
JMP CHECK_INPUTS

DIV_DONE:
OR R2, R7, R7       ; Copy Quotient to R2 for PRINT_NUMBERS
CALL OUTPUT_RESULTS
JMP CHECK_INPUTS

; =================== MOD ==========================
CALL_MOD:           ; Logic very similar to DIV but returns the remainder instead of the quotient
CALL UPDATE_SOURCES ; (The value after a carry is detected and one B value is restored to the remainder)

CALL CALC_MOD       ; Use the reusable MOD function to calculate A mod B

; R2 holds the remainder
CALL OUTPUT_RESULTS
JMP CHECK_INPUTS

; =================== AND ==========================
CALL_AND:
CALL UPDATE_SOURCES
AND R2, R3, R4
CALL OUTPUT_RESULTS
JMP CHECK_INPUTS

; =================== OR ===========================
CALL_OR:
CALL UPDATE_SOURCES
OR R2, R3, R4
CALL OUTPUT_RESULTS
JMP CHECK_INPUTS

; =================== STATUS =======================
CALL_STATUS:
CALL UPDATE_SOURCES

; Save A and B temporarilly
STORE R3, 93
STORE R4, 94

CALL CREATE_NEWLINE

; PRINT "A=" 

LOADI R6, 65      ; ASCII 'A'
CALL SEND_CHAR_R6

LOADI R6, 61      ; ASCII '='
CALL SEND_CHAR_R6

; Print A as decimal
LOAD R2, 93
CALL PRINT_NUMBERS

;  PRINT SPACE 

LOADI R6, 32      ; ASCII space
CALL SEND_CHAR_R6

; PRINT "B=" 

LOADI R6, 66      ; ASCII 'B'
CALL SEND_CHAR_R6

LOADI R6, 61      ; ASCII '='
CALL SEND_CHAR_R6

; Print B as a decimal
LOAD R2, 94
CALL PRINT_NUMBERS

JMP CHECK_INPUTS

; =================== HISTORY ======================
CALL_HISTORY:
CALL CREATE_NEWLINE
; NEWEST RESULT
LOAD R2, 90
CALL PRINT_NUMBERS
CALL CREATE_NEWLINE

; PREVIOUS RESULT
LOAD R2, 91
CALL PRINT_NUMBERS
CALL CREATE_NEWLINE

; OLDEST RESULT
LOAD R2, 92
CALL PRINT_NUMBERS
JMP CHECK_INPUTS

; =================== GCD ==========================
CALL_GCD:    ; Greatest Common Denominator 
; Using Euclidean Algorithm: GCD(A, B) = GCD(B, A mod B)
; R3 = A, R4 = B
; Do not need to check which is larger, the algorithm will work regardless of order
CALL UPDATE_SOURCES

GCD_LOOP:

CALL CALC_MOD       ; R2 = A mod B

; Check if remainder is 0, if so, GCD = B
LOADI R6, 0
SUB R6, R2, R6      
JZ GCD_DONE

; Prepare for next iteration
OR R3, R4, R4       ; A = B
OR R4, R2, R2       ; B = A mod B = Remainder

JMP GCD_LOOP

GCD_DONE:

OR R2, R4, R4       ; Copy GCD into R2 for OUTPUT_RESULTS
CALL OUTPUT_RESULTS
JMP CHECK_INPUTS

