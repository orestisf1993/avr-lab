; lab1.asm
; Orestis Floros-Malivitsis 7796
; Alexandra Antoniadou 7853
; Omada 10

.cseg
.include "m16def.inc"
.org 0x0000
rjmp main

;define student's info
aem1dw: .dw $7796
aem2dw: .dw $7853

main:
.def aem1H=R6
.def aem1L=R7
.def aem2H=R8
.def aem2L=R9
.def temp_carry=r24

;PART1
;init stack pointer

SPI_INIT:
ldi r25,low(RAMEND)
out Spl,r25
ldi r25,high(RAMEND)
out sph,r25

;load aem1 in memory
ldi ZH,high(2 * aem1dw)
ldi ZL,low(2 * aem1dw)
lpm aem1L, Z+
lpm aem1H, Z

;load aem2 in memory
ldi ZH,high(2 * aem2dw)
ldi ZL,low(2 * aem2dw)
lpm aem2L, Z+
lpm aem2H, Z

;aem2 in digits
ldi r16,0x03
ldi r17,0x05
ldi r18,0x08
ldi r19,0x07
;aem1 in digits
ldi r20,0x06
ldi r21,0x09
ldi r22,0x07
ldi r23,0x07

; add digits one by one
add r16,r20
add r17,r21
add r18,r22
add r19,r23

cpi r16,0x0A
; if r16 is smaller than 10 jump to next comparison
brlo cmp17
subi r16,0x0A
subi r17,-1

cmp17:
cpi r17,0x0A
brlo cmp18
subi r17,0x0A
subi r18,-1

cmp18:
cpi r18,0x0A
brlo cmp19
subi r18,0x0A
subi r19,-1

cmp19:
cpi r19, 0x0A
brlo cmpend
subi r19,0x0A

cmpend:

; move digits to SRAM
sts 0x0060, r19
sts 0x0061, r18
sts 0x0062, r17
sts 0x0063, r16

;define PORTB as exit
.def temp=r25
ser temp
out DDRB,temp

rcall show_aem1_digits
rcall show_aem2_digits

; show digits from addition

lds r19,0x0062
lds r18,0x0063
swap r19
or r19,r18
com r19
out PORTB,r19
rcall delay10

lds r19,0x0060
lds r18,0x0061
swap r19
or r19,r18
com r19
out PORTB,r19
rcall delay10

;PART2
;define PORTD as input
ser temp
out PORTB,temp
clr temp
out DDRD,temp

;wait in this loop until the user press a switch
wait_loop:
in r22,PIND
sbrs r22,1
rcall sw1_pressed
sbrs r22,2
rcall sw2_pressed
sbrs r22,3
rcall sw3_pressed
jmp wait_loop

ret

;wait until user releases switch 1
sw1_pressed:
sw1_loop:
    in r22,PIND
    sbrs r22,1
    jmp sw1_loop
    rcall show_aem1_digits
    ret

;wait until user releases switch 2
sw2_pressed:
sw2_loop:
    in r22,PIND
    sbrs r22,2
    jmp sw2_loop
    rcall show_aem2_digits
    ret

;wait until user releases switch 3
sw3_pressed:
digits0:
    in r22,PIND
    sbrs r22,3
    jmp digits0
    rcall show_addition_digit1
pressed1:
    in r22,PIND
    sbrc r22,3
    jmp pressed1
digits1:
    in r22,PIND
    sbrs r22,3
    jmp digits1
    rcall show_addition_digit2
pressed2:
    in r22,PIND
    sbrc r22,3
    jmp pressed2
digits2:
    in r22,PIND
    sbrs r22,3
    jmp digits2
    rcall show_addition_digit3
pressed3:
    in r22,PIND
    sbrc r22,3
    jmp pressed3
digits3:
    in r22,PIND
    sbrs r22,3
    jmp digits3
    rcall show_addition_digit4
    ret

show_addition_digit1:
    lds r19,0x0060
    com r19
    out PORTB,r19
    ret
show_addition_digit2:
    lds r19,0x0061
    com r19
    out PORTB,r19
    ret
show_addition_digit3:
    lds r19,0x0062
    com r19
    out PORTB,r19
    ret
show_addition_digit4:
    lds r19,0x0063
    com r19
    out PORTB,r19
    ret


show_aem1_digits:
    ; load on portb a 8-bit register with 2 last digits
    ldi r18, 0x06
    ldi r19, 0x09
    swap r19
    or r19,r18
    ; r19 was 1 for active led but st500 has inverted logic
    ; because of that we use 1-complement
    com r19
    out PORTB,r19
    rcall delay10
    ldi r18, 0x07
    ldi r19, 0x07
    swap r19
    or r19,r18
    com r19
    out PORTB,r19
    rcall delay10
    ret

show_aem2_digits:
    ldi r18, 0x03
    ldi r19, 0x05
    swap r19
    or r19,r18
    com r19
    out PORTB,r19
    rcall delay10
    ldi r18, 0x08
    ldi r19, 0x07
    swap r19
    or r19,r18
    com r19
    out PORTB,r19
    rcall delay10
    ret

; Delay 40 000 000 cycles
; 10s at 4 MHz
delay10:
    ldi  r18, 203
    ldi  r19, 236
    ldi  r20, 133
delay10L1: dec  r20
    brne delay10L1
    dec  r19
    brne delay10L1
    dec  r18
    brne delay10L1
    ret
