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
