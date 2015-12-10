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

//TODO: use ports etc instead of 0x18
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
		; emergency stop check
        BST     R16, 7
        BRTS    check_input_0
		; turn off hot/cold running leds
        ANDI    R17, 0b11111100
		; turn on emergency, hot/cold stop leds
        ORI     R17, 0b11100000
        RJMP    check_input_1
check_input_0:
		; start cold switch
        BST     R16, 0
        BRTS    check_input_2
		; turn off emergency stop and cold stop
        ANDI    R17, 0b01011111
		; turn on cold running
        ORI     R17, 0b00000010
        RJMP    check_input_1
check_input_2:
		; Temperature<SETPOINT and start hot switch
		; check if switch pressed is either SW3 or SW1
        MOV     R18, R16
        ANDI    R18, 0b00001010
        CPI     R18, 0b00001010
        BREQ    check_input_3
		; turn on hot running led
        ORI     R17, 0b00000001
        MOV     R16, R17
		; turn off emergency, stop hot leds
        ANDI    R17, 0b00100011
		; add 1 to the leds that count hot activations
		; equal to adding 0b00000100
        SUBI    R16, 252
		; only keep the count leds
        ANDI    R16, 0b00011100
		; combine results
        OR      R17, R16
        RJMP    check_input_1
check_input_3:
		; Temperature>SETPOINT
        BST     R16, 2
        BRTS    check_input_4
		; turn off hot running led
		; TODO: fix order of hot_running, cold_running
        ANDI    R17, 0b11111110
        RJMP    check_input_1
check_input_4:
		; stop cold switch
        BST     R16, 4
        BRTS    check_input_5
		; turn off cold running led
        ANDI    R17, 0b11111101
		; turn on stop cold led
        ORI     R17, 0b00100000
        RJMP    check_input_1
check_input_5:
		; stop hot switch
        BST     R16, 5
        BRTS    check_input_1
		; turn off hot running led
        ANDI    R17, 0b11111110
		; turn on stop hot led
        ORI     R17, 0b01000000
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
