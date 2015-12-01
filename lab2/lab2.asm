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
ldi XL, low(0x0060)
ldi XH, high(0x0060)

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

; remove 0-th bit by shifting
lsr sum

ldi temp, 10
mul decades,temp ; Multiply unsigned decades with 10
movw decades,r0 ; Copy result back in decades
add sum, decades

mov r24, sum
rcall find_average

cpi r24, 10
breq remove10
lsl r24
or r24,r25
mov temp, studentid
swap temp
lsl temp
lsl temp
or r24, temp
com r24
st X+, r24

continue:


; reset i and if there is another student loop again
clr i
clr sum
clr decades
cpi studentid,2
brne read_loop

; open corresponding LEDs
lds r25, 0x0060
rcall display_average
rcall delay2

lds r25, 0x0061
rcall display_average

;

ret

display_average:
	out PORTB,r25
	rcall delay5
	ser r18
	out PORTB,r18

remove10:
	ldi r24, 32 ; set 5-th bit, all other are cleared
	jmp continue

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
delay2:
	ret

delay5:
    ret

delay05:
    ret

; returns r25 as sum, r24 as halfs
find_average:
    ; sum is at r24
    ; divide sum by 6
    ldi r18,-85
    mul r24,r18
    mov r18,r1
    lsr r18
    lsr r18
    mov r25,r18
    lsl r25
    add r25,r18
    lsl r25
    sub r24,r25
    ; r24 is now sum % 6
    cpi r24,2
    brlo L5
    cpi r24,5
    brlo L3
    cpi r24,5
    brne L5
    subi r18,-1
	; r25 is halfs flag
	; r24 is average
    ldi r25,0
    mov r24,r18
    ret
L5:
    ldi r25,0
    mov r24,r18
    ret
L3:
    ldi r25,1
    mov r24,r18
    ret
