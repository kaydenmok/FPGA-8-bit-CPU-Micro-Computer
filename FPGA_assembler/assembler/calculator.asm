LOADI R0, 0
STORE R0, 249   ; Hex mode for 7 segment display

MAIN_LOOP:
LOAD R0, 243 ; Load Switch Value A
LOAD R1, 242 ; Load Switch Value B


    ; Used for AND operations to check which button is pressed
LOADI R5, 1 
LOADI R6, 2
LOADI R7, 4

LOAD R4, 244 ; Load Button Value 
    ; btn[0] = btnU , btn[1] = btnD, btn[2] = btnL, btn[3] = btnR

AND R3, R5, R4 ; See if btnU is pressed for ADD
JNZ ADD_CALL
AND R3, R6, R4 ; See if btnD is pressed for SUBTRACT
JNZ SUB_CALL
AND R3, R7, R4 ; See if btnL is pressed for AND
JNZ AND_CALL

LOADI R7, 8 
AND R3, R7, R4 ; See if btnR is pressed for OR
JNZ OR_CALL

JMP MAIN_LOOP
    
ADD_CALL: 
ADD R2, R0, R1
STORE R2, 240
STORE R2, 245
JMP MAIN_LOOP

SUB_CALL:
SUB R2, R0, R1
STORE R2, 240
STORE R2, 245
JMP MAIN_LOOP

AND_CALL:
AND R2, R0, R1
STORE R2, 240
STORE R2, 245
JMP MAIN_LOOP

OR_CALL:
OR R2, R0, R1
STORE R2, 240
STORE R2, 245
JMP MAIN_LOOP