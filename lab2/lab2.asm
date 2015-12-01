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

.def i=r24 ; our counter
.def grade=r19
.def sum=r6 ; our sum
.def decades=r4 ; number of decades
.def studentid=r20 ; current student
clr sum
clr decades
clr i
clr studentid
;loop all memory
read_loop:

lpm r16, Z
adiw ZL, 1
lpm r17, Z
adiw ZL, 1

mov grade,r16 ; Backup grade

rcall combine_leds
rcall flash_leds

; add to sum
; if the 0-th bit is set then grade is XY.5
; so, if the 0-th bit is cleared don't add to halfs counter
;sbrc grade, 0
;inc halfs
; add 10 if the decade bit is set
sbrc grade, 5
inc decades

;lsr grade
; mask it so we only sum the 5 lsb
andi grade,0b00011111
add sum,grade

inc i
cpi i,6
brlo read_loop ; loop until all student's grades are iterated

inc studentid
; calculate accurate sum

clr r5
sbrc sum, 0
inc r5
lsr sum

ldi temp, 10
mul decades,temp ; Multiply unsigned decades with 10
movw decades,r0 ; Copy result back in decades
clr r1
add sum, decades

mov r24, sum
mov r22, r5
rcall find_average
; open corresponding LEDs

; reset i and if there is another student loop again
clr i
clr sum
clr decades
cpi studentid,2
brne read_loop

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

find_average:
    ; sum is at r24
    ; halfs is at r22
    ; divide sum by 6
    ldi r18,-85
    mul r24,r18
    mov r18,r1
    clr r1
    lsr r18
    lsr r18
    mov r19,r18
    lsl r19
    add r19,r18
    lsl r19
    sub r24,r19
    ; r24 is now sum % 6
    cpi r24,2
    brlo L2
    cpi r24,5
    brlo L3
    cpi r24,5
    brne L2
    subi r18,-1
L2:
    mov r24,r18
    mov r25,r22
    ret
L3:
    add r18,r22
    ldi r24,1
    eor r22,r24
    mov r24,r18
    mov r25,r22
    ret
