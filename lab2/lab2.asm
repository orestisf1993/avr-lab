; lab2.asm
; Floros-Malivitsis Orestis, 7796
; Antoniadou Alexandra, 7853

.cseg
.include "m16def.inc"
.org 0x0000
rjmp main

; define grades
gradesa: .dw 0x510F,0x5211,0x5311,0x5410,0x550F,0x5620
gradesb: .dw 0x410A,0x4212,0x430D,0x4412,0x4520,0x4610

main:
.def temp=r25

;init stack pointer
SPI_INIT:
ldi r25,low(RAMEND)
out Spl,r25
ldi r25,high(RAMEND)
out sph,r25

; define PORTB as exit
ser temp
out DDRB,temp
; turn off all leds
out PORTB, temp

ldi ZL, low(2*gradesa)
ldi ZH, high(2*gradesa)

.def i=r24
clr i ; our counter
;loop all memory
read_loop:

lpm r16, Z
adiw ZL, 1
lpm r17, Z
adiw ZL, 1
rcall combine_leds
rcall flash_leds

; for (i=0; i<12; i++)
adiw i,0x01
cpi i,12
brlo read_loop

ret

read_pdata:
    ldi ZL, low(2*gradesa)
    ldi ZH, high(2*gradesa)
    add ZL, r16
    add ZL, r16
    lpm r16, Z
    adiw ZL, 1
    lpm r17, Z
    ret

combine_leds:
    ; keep 4 lsb of r17
    andi r17,0b00001111
    ; swap right and keep 4 lsb or r16
    lsr r16
    andi r16,0b00001111

    ; old r17 is the 4 msb and old r16 the 4 lsb
    swap r17
    or r16,r17
    com r16

    ; show r16 in LEDs
    out PORTB,r16
    ret

flash_leds:
    rcall delay5
    ser temp

    out PORTB,temp
    rcall delay05
    out PORTB,r16
    rcall delay05

    out PORTB,temp
    rcall delay05
    out PORTB,r16
    rcall delay05

    out PORTB,temp
    rcall delay05
    out PORTB,r16
    rcall delay05

    out PORTB,temp
    rcall delay05
    out PORTB,r16
    rcall delay05

    ret

;TODO
delay5:
    ret

delay05:
    ret
