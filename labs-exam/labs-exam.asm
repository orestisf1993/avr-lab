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
rcall test_ex6
rcall test_ex10
rcall test_ex25

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

; Exercise 6
.def sum_L=r24
.def sum_H=r25
.def counter=r16
.def temp_byte=r17
.def zero_reg=r0
ex6:
clr sum_L
clr sum_H
clr zero_reg
clc
ldi counter, 8

loop6:
; Only sum for counter values 7,5,3,1 => bit0 is set
bst counter, 0
; ld should be above brtc so that we always point to the next byte after each loop.
ld temp_byte, X+
brtc skip_sum_calc
add sum_L, temp_byte
adc sum_H, zero_reg
skip_sum_calc:
dec counter
brne loop6
clt
ret

.def temp=r20
test_ex6:
ldi XL, low(0x60)
ldi XH, high(0x60)
; Store stuff in memory
ldi temp, 25
; 1st = 25
st X+, temp
; 2nd = 25
st X+, temp
; 3rd = 33
ldi temp, 33
st X+, temp
; 4th = 55
ldi temp, 55
st X+, temp
; 5th = 55
st X+, temp
; 6th = 55
st X+, temp
; 7th = 255
ldi temp, 255
st X+, temp
; 8th = 255
st X+, temp
; Junk data:
ldi temp, 100
st X+, temp
st X+, temp
clr temp
st X+, temp
; Reset X
ldi XL, low(0x60)
ldi XH, high(0x60)
rcall ex6
ldi temp, 0x86
cpse sum_L, temp
jmp test_failed
ldi temp, 0x01
cpse sum_H, temp
jmp test_failed
ret
.undef temp
.undef sum_L
.undef sum_H
.undef counter
.undef temp_byte
.undef zero_reg

; Exercise 10
; We need 2 bytes since 16 * 256 fits.
.def sum_L=r24
.def sum_H=r25
.def counter=r16
.def temp_register=r17
.def zero_reg=r18
ex10:
clr sum_L
clr sum_H
ldi counter, 16
; X points to r0
clr XL
clr XH
clr zero_reg
clc
; Sum registers r0 to r15
loop10:
ld temp_register, X+
add sum_L, temp_register
adc sum_H, zero_reg
dec counter
brne loop10
ret

test_ex10:
.def temp=r20
ldi temp, 10
mov r0, temp
mov r5, temp
mov r7, temp
ldi temp, 255
mov r1, temp
mov r2, temp
mov r15, temp
ldi temp, 0
mov r3, temp
ldi temp, 100
mov r4, temp
mov r6, temp
mov r8, temp
mov r9, temp
mov r10, temp
ldi temp, 200
mov r11, temp
mov r12, temp
mov r13, temp
ldi temp, 3
mov r14, temp
; Garbage data:
ldi r16, 1
ldi r17, 2
ldi r18, 3
ldi r19, 4
; Expected result = 10 + 255 + 255 + 0 + 100 + 10 + 100 + 10 + 100 + 100 + 100 + 200 + 200 + 200 + 3 + 255
; res = 1897 == 0x76a
rcall ex10
ldi temp, 0x6a
cpse temp, sum_L
jmp test_failed
ldi temp, 0x07
cpse temp, sum_H
jmp test_failed
ret
.undef temp
.undef sum_L
.undef sum_H
.undef counter
.undef temp_register
.undef zero_reg

; Exercise 25
; Calculate 4 * x + y / 2 for signed x, y with full accuracy.
.def xvalue=r16
.def yvalue=r17
.def yvalue_fract=r19
.def ans_L=r24
.def ans_H=r25
ex25:
; Do y / 2 w/ fract
rcall full_div2
; Do x * 4
ldi ans_H, 4
muls xvalue, ans_H
movw ans_L, r0
; Add the results
add ans_L, yvalue
clr r1
adc ans_H, r1
sbrc yvalue, 7
dec ans_H
ret

full_div2:
mov yvalue_fract, yvalue
sbrc yvalue, 7
subi yvalue, -1
asr yvalue
andi yvalue_fract, 1
ret

.def expected_L=r20
.def expected_H=r21
.def expected_fract=r22
.MACRO CHECK25
ldi xvalue, @0
ldi yvalue, @1
ldi expected_L, low(4 * @0 + @1 / 2)
ldi expected_H, high(4 * @0 + @1 / 2)
rcall ex25
cpse ans_L, expected_L
jmp test_failed
cpse ans_H, expected_H
jmp test_failed
.ENDMACRO

.MACRO CHECKDIV2
ldi yvalue, @0
ldi expected_L, ((@0) / 2)
ldi expected_fract, (ABS(@0) % 2)
rcall full_div2
cpse yvalue, expected_L
jmp test_failed
cpse yvalue_fract, expected_fract
jmp test_failed
.ENDMACRO

test_ex25:
; test full_div2
CHECKDIV2 11
CHECKDIV2 0
CHECKDIV2 5
CHECKDIV2 5
CHECKDIV2 -5
CHECKDIV2 -101
CHECKDIV2 -6

; test ex25
CHECK25 100, 10
CHECK25 100, 10
CHECK25 4, 5
CHECK25 -4, 101
CHECK25 -100, 0
CHECK25 -127, 127
CHECK25 0, 0
CHECK25 0, 1
CHECK25 0, -1
CHECK25 -10, -10
CHECK25 -100, -100
ret

.undef expected_L
.undef expected_H
.undef expected_fract
.undef xvalue
.undef yvalue
.undef ans_L
.undef ans_H
.undef yvalue_fract
