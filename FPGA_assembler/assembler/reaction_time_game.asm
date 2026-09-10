START:
    LOADI R0, 1
    STORE R0, 240      ; LED0 = test started

    LOADI R6, 3

DEC_TEST:
    DEC R6, R6
    JZ DEC_FINISHED
    JMP DEC_TEST

DEC_FINISHED:
    LOADI R0, 255
    STORE R0, 240      ; All LEDs = DEC/JZ worked

HOLD:
    JMP HOLD
    
JMP RANDOM_LED_START

; ============================ FUNCTIONS ===============================
DELAY: ; Delays for a certain number of clock cycles to count time in ms
; 1 ms = 1 000 000 ns       1 000 000 ns / 10 ns = 100 000 clock cycles
; 1 ms = 100 000 clock cycles
; USES R6 AND R5 AS A COUNTERS, R3, R4 USED FOR LOGIC

    LOADI R6, 249 
    LOADI R5, 100 
    LOADI R4, 0   

    DELAY_LOOP: ; Inner counter
    DEC R6, R6     ; Decrement the counter  
    SUB R3, R6, R4
    JZ DELAY_PASS  ; If the counter reaches zero, exit the loop
    JMP DELAY_LOOP ; Otherwise, continue looping

    DELAY_PASS: ; Inner counter reached 0, update the outer counter
    DEC R5, R5
    ; Check whether outer counter reached 0
    SUB R3, R5, R4
    JZ DELAY_DONE

    LOADI R6, 249
    JMP DELAY_LOOP

    DELAY_DONE:
    RET

; Timing breakdown:
; Inner loop:
;   248 normal loops × 4 cycles = 992 cycles
;   Final loop to DELAY_PASS     =   3 cycles
;   Total inner loop             = 995 cycles
;
; Outer loop:
;   99 normal passes × 5 cycles  = 495 cycles
;   Final pass to DELAY_DONE     =   3 cycles
;
; Startup = 3 cycles
; RET     = 1 cycle
;
; Total cycles ≈ 3 + 100(995) + 99(5) + 3 + 1
;              = 100,002 cycles
;              = 1,000,020 ns at 100 MHz
;              ≈ 1.00002 ms

TIME_START:
    LOADI R7, 0   ; Number of tenths of a second

    TIME_LOOP:
    LOADI R6, 100 ; Call ~1 ms delay 100 times

    TIME_100MS_LOOP:
    PUSH R6       ; DELAY destroys R6, so we need to save it
    CALL DELAY    ; ~1ms
    POP R6        ; Restore R6

    DEC R6, R6
    JNZ TIME_100MS_LOOP ; Loop until 100 ms have passed

    ; Approximately 100 ms have passed
    INC R7, R7

    ; Update display
    STORE R7, 245 

    ; Check Button U
    LOAD R1, 244   ; Read buttons
    LOADI R2, 1    ; Button U mask = 0000_0001
    AND R0, R1, R2 
    JNZ REACTION_DONE 

    JMP TIME_LOOP ; Otherwise, keep counting time

    REACTION_DONE:
        LOADI R0, 0
        STORE R0, 240 ; Turn off the leds

        JMP REACTION_DONE  ; Freeze results

; ======================================================================

RANDOM_LED_START: ; Push buttonU to start and then wait N time for leds to turn on 
    ; Need a random number generator to determine how long to wait before turning on the leds

    LOADI R7, 0 ; R7 will constant change while waiting

    BUTTON_IDLE_WAIT:
    INC R7, R7  ; Keep changing the random value
    
    LOAD R1, 244   ; Read buttons
    LOADI R2, 1    ; Button U mask = 0000_0001
    AND R0, R1, R2 ; Check if button U is pressed

    JZ BUTTON_IDLE_WAIT ; If button U is not pressed, keep waiting

    ; Button has been pressed — wait until it is released
    BUTTON_RELEASE_WAIT:
    LOAD R1, 244
    LOADI R2, 1
    AND R0, R1, R2
    JNZ BUTTON_RELEASE_WAIT

    JMP RANDOM_DELAY_WAIT

    RANDOM_DELAY_WAIT: 
    CALL DELAY 
    CALL DELAY
    CALL DELAY
    CALL DELAY
    CALL DELAY
    CALL DELAY
    CALL DELAY
    CALL DELAY
    CALL DELAY
    CALL DELAY
    CALL DELAY
    CALL DELAY ; 12 ms total

    DEC R7, R7 ; Decrement the random value
    JZ RANDOM_LED_DONE

    JMP RANDOM_DELAY_WAIT ; Keep waiting until the random value is 0

    RANDOM_LED_DONE:
    LOADI R0, 255
    STORE R0, 240 ; Turn on the leds
    JMP TIME_START






