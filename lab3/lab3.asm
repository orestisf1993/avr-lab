; lab3.asm
; Floros-Malivitsis Orestis
; Antoniadou Alexandra

.cseg
.include "m16def.inc"
.org 0x0000
rjmp main

; TODO: fix whitespace and capitalizations
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
    OUT     PORTB, R16
    RET
init:
; DDRB as output
    LDI     R16, 255
    OUT     DDRB, R16
; turn off any leds
    OUT     PORTB, R16
; DDRD as input
    LDI     R16, 0
    OUT     DDRD, R16
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

#define liters r31
#define counter_low_byte r20
#define counter_mid_byte r21
#define counter_high_byte r22
#define old_input r30
#define new_input r19
#define my_leds r0
#define whats_pressed r1
main_loop:
    ; initializations
    RCALL   init
    clr my_leds
    ; initialize old_input to nothing pressed
    LDI     old_input, 0xFF
    LDI     liters, 0
    ; start main loop until target liters are reached
outter_loop:
    ; zero out 3-byte cycles counter
    LDI     counter_low_byte, 0
    LDI     counter_mid_byte, 0
    LDI     counter_high_byte, 0
    ; start inner loop until target cycles are reached
inner_loop:
    IN      new_input, PIND
    CP      new_input, old_input
    BREQ    counter_increase_and_compare
    ; in + cp + breq = 4 cycles usually
    ; if nothing was pressed before we need to store what is being pressed right now
    ; don't process input yet
    CPI     old_input, 0xFF
    BREQ    store_whats_pressed
    ; if something was pressed before then the switch is now released, process our input
    MOV     R17, my_leds
    MOV     R16, whats_pressed
    RCALL   check_input
    MOV     my_leds, R16
    RCALL   light_leds
    RJMP    store_old_input
store_whats_pressed:
    MOV     whats_pressed, new_input
store_old_input:
    MOV     old_input, new_input
counter_increase_and_compare:
    ; increase 3-byte counter by 14
    SUBI    counter_low_byte, -14
    SBCI    counter_mid_byte, -1
    SBCI    counter_high_byte, -1
    MOV     R17, counter_mid_byte
    MOV     R18, counter_high_byte
    ; compare counter to F_CPU
    CPI     counter_low_byte, 0
    ; TODO: change to #define and shifts
    ; F_CPU>>8 & 0xff == 9
    SBCI    R17, 9
    ; F_CPU>>16 == 61
    SBCI    R18, 61
    BRCS    inner_loop
    ; subi + 2*sbci + 2*mov + cpi + 2*sbci + brcs = 10 cycles usually
    ; here 1s passed, increase the liters value
    ; keep 0th-bit from leds with and on r16
    MOV     R16, my_leds
    ANDI    R16, 0x01
    ; keep 1st-bit from leds with bst
    BST     my_leds, 1
    LDI     R17, 0
    ; load it on r17
    BLD     R17, 0
    ADD     R16, R17
    ; add them on liters
    ADD     liters, R16
    ; TODO: #define MAX_LITERS 56
    CPI     liters, 56
    BRCS    outter_loop
    ; here max liters are reached, display leds once more
    MOV     R16, my_leds
    RCALL   light_leds
    RET
