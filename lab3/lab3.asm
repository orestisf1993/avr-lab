; lab3.asm
; Floros-Malivitsis Orestis
; Antoniadou Alexandra

.cseg
.include "m16def.inc"
.org 0x0000
rjmp main

#define START_COLD_SWITCH 0
#define START_HOT_SWITCH 1

#define STOP_COLD_SWITCH 4
#define STOP_HOT_SWITCH 5
#define EMERGENCY_STOP_SWITCH 7

#define MAX_TOTAL_LIQUID 2800
#define LIQUID_PER_SECOND 50

main:
.def temp=r25

; init stack pointer
SPI_INIT:
ldi r25,low(RAMEND)
out Spl,r25
ldi r25,high(RAMEND)
out sph,r25

; ορίζουμε το DDRB σαν έξοδο.
ser temp
out DDRB,temp
; μηδενισμός των LEDs στην αρχική κατάσταση.
out PORTB, temp

; define PORTD as input
out PORTB,temp
clr temp
out DDRD,temp

clr r1
rcall main_loop
ret

light_leds:
        OUT     0x18, R16
        RET
init:
        LDI     R16, 255
        OUT     0x17, R16
        LDI     R16, 0
        OUT     0x11, R16
        RET
check_input:
        BST     R16, 7
        BRTC    check_input_0
        ANDI    R17, 0xFC
        ORI     R17, 0xE0
        RJMP    check_input_1
check_input_0:
        BST     R16, 0
        BRTC    check_input_2
        ANDI    R17, 0x5F
        ORI     R17, 0x02
        RJMP    check_input_1
check_input_2:
        MOV     R18, R16
        ANDI    R18, 0x0A
        BREQ    check_input_3
        ORI     R17, 0x01
        MOV     R16, R17
        ANDI    R17, 0x23
        SUBI    R16, 252
        ANDI    R16, 0x1C
        OR      R17, R16
        RJMP    check_input_1
check_input_3:
        BST     R16, 2
        BRTC    check_input_4
        ANDI    R17, 0xFE
        RJMP    check_input_1
check_input_4:
        BST     R16, 4
        BRTC    check_input_5
        ANDI    R17, 0xFD
        ORI     R17, 0x20
        RJMP    check_input_1
check_input_5:
        BST     R16, 5
        BRTC    check_input_1
        ANDI    R17, 0xFE
        ORI     R17, 0x40
check_input_1:
        MOV     R16, R17
        RET

main_loop:
        RCALL   init
        MOV     R0, R16
        LDI     R30, 255
        LDI     R31, 0
main_0:
        LDI     R20, 0
        LDI     R21, 0
        LDI     R22, 0
main_1:
        IN      R19, 0x10   ;+1
        CP      R19, R30    ;+1
        BREQ    main_2    ;+2
        ; 4 cycles
        ; usually equal, so branch
        CPI     R30, 255
        BREQ    main_3
        MOV     R17, R0
        MOV     R16, R1
        RCALL   check_input
        MOV     R0, R16
        RCALL   light_leds
        RJMP    main_4
main_3:
        MOV     R1, R19
main_4:
        MOV     R30, R19
main_2:
        SUBI    R20, 243    ;+1
        SBCI    R21, 255    ;+1
        SBCI    R22, 255    ;+1
        MOV     R17, R21    ;+1
        MOV     R18, R22    ;+1
        CPI     R20, 0      ;+1
        SBCI    R17, 9      ;+1
        SBCI    R18, 61     ;+1
        BRCS    main_1      ;+2
        ; 9 cycles
        MOV     R16, R0
        ANDI    R16, 0x01
        BST     R0, 1
        LDI     R17, 0
        BLD     R17, 0
        ADD     R16, R17
        ADD     R31, R16
        CPI     R31, 56
        BRCS    main_0
        ; light leds and exit
        MOV     R16, R0
        RCALL   light_leds
        LDI     R16, 0
        LDI     R17, 0
        RET
