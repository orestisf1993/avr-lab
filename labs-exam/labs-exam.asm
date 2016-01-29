.cseg
.include "m16def.inc"
.org 0x0000
rjmp main

test_failed:
set
jmp test_failed

test_succeeded:
clt
jmp test_succeeded

main:
; Init stack pointer.
SPI_INIT:
ldi r25,low(RAMEND)
out Spl,r25
ldi r25,high(RAMEND)
out sph,r25

rcall test_ex2
rcall test_ex4

rcall test_succeeded

; Exercise 1
ex1:
.def counter=r16
.def value=r17
#define INITIAL_POS 0x60
#define MY_VALUE 0x5f
#define REPEAT_COUNT 64
ldi XL, low(INITIAL_POS)
ldi XH, high(INITIAL_POS)
ldi counter, REPEAT_COUNT
ldi value, MY_VALUE
loop1:
st X+, value
dec counter
tst counter
brne loop1
ret
.undef counter
.undef value

; Exercise 2
.def xvalue=r16
.def yvalue=r17
.def result_L=r24
.def result_H=r25
ex2:
push xvalue
push yvalue

clr result_H
mov result_L, xvalue
; Shift left 2 times => x = x * 4
; Be carefull with overflow.
lsl result_L
rol result_H
lsl result_L
rol result_H
add result_L, yvalue
clr yvalue
adc result_H, yvalue

pop yvalue
pop xvalue
ret

test_ex2:
ldi xvalue, 240
ldi yvalue, 100
rcall ex2
cpi result_L, 0x24
brne test_failed
cpi result_H, 0x04
brne test_failed
ret
.undef xvalue
.undef yvalue
.undef result_L
.undef result_H

; Exercise 4
; https://en.wikipedia.org/wiki/Parity_bit
; Even parity bit.
.def my_byte=r16
.def counter=r17
.def ones_count=r18
.def initial_byte=r0
ex4:
; Backup byte input
mov initial_byte, my_byte
ldi counter, 7
clr ones_count
; Check each byte. This loop can be unrolled.
loop4:
; Sequentially bring each bit to the LSbit.
lsr my_byte
sbrc my_byte, 0
inc ones_count
dec counter
tst counter
brne loop4
; Find parity
; ones_count is even when bit0 is set.
bst ones_count, 0
bld initial_byte, 0
clt
ret

test_ex4:
; bit0 shouldn't matter.
; 0 ones => odd
ldi my_byte, 0b00000001
rcall ex4
sbrc my_byte, 0
rcall test_failed

; 0 ones => odd
ldi my_byte, 0b00000000
rcall ex4
sbrc my_byte, 0
rcall test_failed

; 3 ones => even
ldi my_byte, 0b10100010
rcall ex4
sbrs my_byte, 0
rcall test_failed

; 7 ones => even
ldi my_byte, 0b11111111
rcall ex4
sbrs my_byte, 0
rcall test_failed
ret
.undef my_byte
.undef counter
.undef ones_count
.undef initial_byte
