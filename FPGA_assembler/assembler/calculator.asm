; MAIN_LOOP - Address 0
LOAD R0, 243 ; Load Switch Value A
LOAD R1, 242 ; Load Switch Value B


    ; Used for AND operations to check which button is pressed
LOADI R5, 1 
LOADI R6, 2
LOADI R7, 4

LOAD R4, 244 ; Load Button Value 
    ; btn[0] = btnU , btn[1] = btnD, btn[2] = btnL, btn[3] = btnR

AND R3, R5, R4 ; See if btnU is pressed for ADD
JNZ 16
AND R3, R6, R4 ; See if btnD is pressed for SUBTRACT
JNZ 20
AND R3, R7, R4 ; See if btnL is pressed for AND
JNZ 24

LOADI R7, 8 
AND R3, R7, R4 ; See if btnR is pressed for OR
JNZ 28

JMP 0
    
; ADD VALUES - Address 16
ADD R2, R0, R1
STORE R2, 240
STORE R2, 245
JMP 0  

; SUBTRACT VALUES - Address 20
SUB R2, R0, R1
STORE R2, 240
STORE R2, 245
JMP 0

; AND VALUES - Address 24
AND R2, R0, R1
STORE R2, 240
STORE R2, 245
JMP 0

; OR VALUES - Address 28
OR R2, R0, R1
STORE R2, 240
STORE R2, 245
JMP 0