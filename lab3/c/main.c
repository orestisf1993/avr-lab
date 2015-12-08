#define F_CPU 4000000UL
#include <stdint.h>
#define ENABLE_BIT_DEFINITIONS
#include <iom16.h>

#define MAX_LITERS 56

#define bit(x) (1<<(x))
#define bit_is_clear(sfr,x) (!((sfr) & bit(x)))

typedef struct {
    uint32_t value : 24;
} bitfield24;

typedef struct {
    uint8_t hot_running : 1;
    uint8_t cold_running : 1;
    uint8_t hot_count : 3;
    uint8_t cold_stop : 1;
    uint8_t hot_stop : 1;
    uint8_t emergency_stop : 1;
} leds;

leds check_input(uint8_t t, leds myleds);

void light_leds(leds myleds) {
    PORTB = ~(*(uint8_t*)&myleds);
}

leds init(void) {
    DDRB = 0xFF; // DDRB as output
    PORTB = 0xFF; // turn off any leds
    DDRD = 0x00; // DDRD as input
    leds myleds;
    myleds.hot_count =
        myleds.hot_running =
            myleds.cold_running =
                myleds.cold_stop =
                    myleds.emergency_stop =
                        myleds.hot_stop = 0x00;
    return myleds;
}

int main(void) {

    leds myleds = init();
    uint8_t oldinput = 0xFF;
    uint8_t whatspressed;
    uint8_t liters = 0;

    do {
        bitfield24 counter;
        counter.value = 0x000000;
        do {
            uint8_t newinput = PIND;
            if (newinput != oldinput) {
                // we can additionaly increase the counter inside this if
                if (oldinput != 0xFF) {
                    myleds = check_input(whatspressed, myleds);
                    light_leds(myleds);
                } else {
                    whatspressed = newinput;
                }
                oldinput = newinput;
            }
        } while ((counter.value += 14) < F_CPU);
        liters += myleds.hot_running + myleds.cold_running;
    } while (liters < MAX_LITERS);
    light_leds(myleds);
}

#define EMERGENCY_STOP_SWITCH PD7
#define START_COLD_SWITCH PD0
#define START_HOT_SWITCH PD1

#define STOP_COLD_SWITCH PD4
#define STOP_HOT_SWITCH PD5

#define TEMP_UP_SWITCH PD2
#define TEMP_DOWN_SWITCH PD3

leds check_input(const uint8_t whatspressed, leds myleds) {
    if (bit_is_clear(whatspressed, EMERGENCY_STOP_SWITCH)) {
        myleds.hot_running = 0;
        myleds.cold_running = 0;
        myleds.emergency_stop = 1;
        myleds.cold_stop = 1;
        myleds.hot_stop = 1;
    } else if (bit_is_clear(whatspressed, START_COLD_SWITCH)) {
        myleds.cold_running = 1;
        myleds.cold_stop = 0;
        myleds.emergency_stop = 0;
    } else if (bit_is_clear(whatspressed, START_HOT_SWITCH) ||
               bit_is_clear(whatspressed, TEMP_DOWN_SWITCH)) {
        myleds.hot_running = 1;
        myleds.hot_count++;
        myleds.hot_stop = 0;
        myleds.emergency_stop = 0;
    } else if (bit_is_clear(whatspressed, TEMP_UP_SWITCH)) {
        myleds.hot_running = 0;
    } else if (bit_is_clear(whatspressed, STOP_COLD_SWITCH)) {
        myleds.cold_running = 0;
        myleds.cold_stop = 1;
    } else if (bit_is_clear(whatspressed, STOP_HOT_SWITCH)) {
        myleds.hot_running = 0;
        myleds.hot_stop = 1;
    }
    return myleds;
}
