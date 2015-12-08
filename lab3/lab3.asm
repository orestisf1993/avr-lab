; lab3.asm
; Floros-Malivitsis Orestis
; Antoniadou Alexandra

.cseg
.include "m16def.inc"
.org 0x0000
rjmp main

main:
; init stack pointer
SPI_INIT:
ldi r25,low(RAMEND)
out Spl,r25
ldi r25,high(RAMEND)
out sph,r25

clr r25
rcall main_loop
ret

light_leds:
        com r16
        OUT     0x18, R16
        RET
init:
; DDRB as output
        LDI     R16, 255
        OUT     0x17, R16
; turn off any leds
        OUT     0x18, R16
; DDRD as input
        LDI     R16, 0
        OUT     0x11, R16
        RET

check_input:
        BST     R16, 7
        BRTS    check_input_0
        ANDI    R17, 0xFC
        ORI     R17, 0xE0
        RJMP    check_input_1
check_input_0:
        BST     R16, 0
        BRTS    check_input_2
        ANDI    R17, 0x5F
        ORI     R17, 0x02
        RJMP    check_input_1
check_input_2:
        MOV     R18, R16
        ANDI    R18, 0x0A
        CPI     R18, 10
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
        BRTS    check_input_4
        ANDI    R17, 0xFE
        RJMP    check_input_1
check_input_4:
        BST     R16, 4
        BRTS    check_input_5
        ANDI    R17, 0xFD
        ORI     R17, 0x20
        RJMP    check_input_1
check_input_5:
        BST     R16, 5
        BRTS    check_input_1
        ANDI    R17, 0xFE
        ORI     R17, 0x40
check_input_1:
        MOV     R16, R17
        RET

main_loop:
//   45     leds myleds = init();
        RCALL   init
        MOV     R0, R16
//   46     uint8_t oldinput = 0xFF;
        LDI     R30, 255
//   47     uint8_t whatspressed;
//   48     uint8_t liters = 0;
        LDI     R31, 0
//   49 
//   50     do {
//   51         bitfield24 counter;
//   52         counter.value = 0x000000;
main_0:
        LDI     R20, 0
        LDI     R21, 0
        LDI     R22, 0
//   53         do {
//   54             uint8_t newinput = PIND;
main_1:
        IN      R19, 0x10
//   55             if (newinput != oldinput) {
        CP      R19, R30
        BREQ    main_2
        ; 4 cycles
//   56                 // we can additionaly increase the counter inside this if
//   57                 if (oldinput != 0xFF) {
        CPI     R30, 255
        BREQ    main_3
//   58                     myleds = check_input(whatspressed, myleds);
        MOV     R17, R0
        MOV     R16, R1
        RCALL   check_input
        MOV     R0, R16
//   59                     light_leds(myleds);
        RCALL   light_leds
        RJMP    main_4
//   60                 } else {
//   61                     whatspressed = newinput;
main_3:
        MOV     R1, R19
//   62                 }
//   63                 oldinput = newinput;
main_4:
        MOV     R30, R19
//   64             }
//   65         } while ((counter.value += 14) < F_CPU);
main_2:
        SUBI    R20, -14    ;+1
        SBCI    R21, -1     ;+1
        SBCI    R22, -1     ;+1
        MOV     R17, R21    ;+1
        MOV     R18, R22    ;+1
        CPI     R20, 0      ;+1
        SBCI    R17, 9      ;+1
        SBCI    R18, 61     ;+1
        BRCS    main_1      ;+2
        ; 10 cycles
//   66         liters += myleds.hot_running + myleds.cold_running;
        MOV     R16, R0
        ANDI    R16, 0x01
        BST     R0, 1
        LDI     R17, 0
        BLD     R17, 0
        ADD     R16, R17
        ADD     R31, R16
//   67     } while (liters < MAX_LITERS);
        CPI     R31, 56
        BRCS    main_0
//   68     light_leds(myleds);
        MOV     R16, R0
        RCALL   light_leds
//   69 }
        LDI     R16, 0
        LDI     R17, 0
        RET
