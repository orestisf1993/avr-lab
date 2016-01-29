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
