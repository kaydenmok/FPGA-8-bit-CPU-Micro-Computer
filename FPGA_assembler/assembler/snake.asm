; Test program for now
;LOADI R1, 65     ; 'A'
;STORE R1, 246    ; 0xF6 = UART TX

;LOADI R3, 2      ; RX-ready mask 0000_0010

; WAIT LOOP
;LOAD R2, 247     ; Ready UART status: 0000_0010
;AND R2, R2, R3   ; Keep bit 1
;JZ 3             ; No byte yet -> keep waiting

;LOAD R2, 248     ; 0xF8 = UART RX FIFO
;STORE R2, 240    ; Show received value on LEDS

;HALT

LOADI R1, 65       ; ASCII 'A'

STORE R1, 240      ; DEBUG: show 65 on LEDs
STORE R1, 246      ; Send 'A' through UART

HALT