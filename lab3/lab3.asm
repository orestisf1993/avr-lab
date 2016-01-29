; lab3.asm
; Φλώρος-Μαλιβίτσης Ορέστης, 7796
; Αντωνιάδου Αλεξάνδρα, 7853

; --------------------------------------------------------------------
; ΕΡΓΑΣΤΗΡΙΑΚΗ ΑΣΚΗΣΗ 3
; Σε μία δεξαμενή αναμειγνύονται οι ροές θερμού και κρύου υγρού για την παραγωγή
; στην έξοδο υγρού προκαθορισμένης θερμοκρασίας (SETPOINT) και προκαθορισμένου
; όγκου.
; Η λειτουργία καθορίζεται από την παρακάτω διαδικασία :
; - Ανοίγει η βάνα του κρύου υγρού (πλήκτρο START COLD) και ανάβει η αντίστοιχη ενδεικτική λυχνία.
; - Ανοίγει η βάνα του θερμού υγρού (πλήκτρο START HOT) και ανάβει η αντίστοιχη ενδεικτική λυχνία.
; - Η λειτουργία Temperature>SETPOINT προσομοιώνεται με την απελεθεύρωση του πλήκτρου SW2. Ταυτόχρονα κλείνει η βάνα του θερμού υγρού και σβήνει η αντίστοιχη ενδεικτική λυχνία.
; - Η λειτουργία Temperature<SETPOINT προσομοιώνεται με την απελεθεύρωση του πλήκτρου SW3. Ταυτόχρονα ανοίγει η βάνα του θερμού υγρού και ανάβει η αντίστοιχη ενδεικτική λυχνία.
; - Για κάθε μία από τις βάνες θερμού και κρύου υγρού υπάρχει ένας μετρητής ροής , ο οποίος προσομοιώνεται με εναν απαριθμητή. Ο απαριθμητής (για την διάρκεια λειτουργίας της αντίστοιχης βάνας), αυξάνεται κατά ένα κάθε 1 sec. Ο χρόνος αυτός αντιστοιχεί σε όγκο υγρού 50lt.
; - Η λειτουργία τερματίζει με το πέρασμα 2800 lt συνολικού υγρού. Κλείνουν και οι δύο βάνες εισαγωγής και ελέγχονται κατάλληλα οι αντίστοιχες ενδεικτικές λυχνίες λειτουργίας των βανών. Κατόπιν στις ενδεικτικές λυχνίες LED2, LED3, LED4 εμφανίζεται ο αριθμός ενεργοποιήσεων της βάνας του θερμού υγρού.
; - Η διαδικασία μπορεί να σταματήσει και με απευθείας έλεγχο από τον χειριστή με το πλήκτρα SW4 (STOP COLD), SW5 (STOP HOT) οπότε και αλλάζουν κατάσταση οι αντίστοιχες ενδεικτικές λυχνίες (LED5, LED6) και τα LED0, LED1 όπου είναι απαραίτητο.
; - Σε οποιαδήποτε χρονική στιγμή, μέσω του πλήκτρου Emergency STOP, ο χειριστής σταματά την διαδικασία και αλλάζουν κατάσταση οι αντίστοιχες ενδεικτικές λυχνίες λειτουργίας των βανών, καθώς και η LED7.

; Στην συνέχεια δίνονται οι παρακάτω συνδέσεις του AVR για την προσομοίωση των διαδικασιών και για τις οπτικές ενδείξεις:
; - SW1: Πλήκτρο START HOT.
; - SW2: Προσομοίωση κατάστασης Temperature>SETPOINT.
; - SW3: Προσομοίωση κατάστασης Temperature<SETPOINT.
; - SW4: Πλήκτρο STΟΡ COLD.
; - SW5: Πλήκτρο STΟΡ HOT.
; - SW7: Πλήκτρο Emergency STOP.

; - LED0: Ενδεικτική λυχνία ανοικτής βάνας COLD.
; - LED1: Ενδεικτική λυχνία ανοικτής βάνας HOT.
; - LED2 – LED4: Αριθμός ενεργοποιήσεων της βάνας του θερμού υγρού.
; - LED5: Ενδεικτική λυχνία STOP βάνας COLD (από τον χειριστή).
; - LED6: Ενδεικτική λυχνία STOP βάνας HOT (από τον χειριστή).
; - LED7: Ενδεικτική λυχνία Emergency STOP της διαδικασίας.
; --------------------------------------------------------------------

; Ορισμός MACROS που βοηθάνε στους υπολογισμούς των κύκλων.
; --------------------------------------------------------------------
; Ο αριθμός των κύκλων ανά δευτερόλεπτο.
#define F_CPU 4000000
; Ο αριθμός των δευτερολέπτων που χρειάζονται για να φτάσουμε το όριο των λίτρων με μία βάνα ανοιχτή.
#define MAX_LITERS 56
; MACRO συναρτήσεις για να πάρουμε συγκεκριμένα bytes μιας σταθερής λέξης 3 byte.
#define GET_HIGH_BYTE(X) ((X)>>16)
#define GET_MID_BYTE(X) ((X)>>8 & 0xff)
#define GET_LOW_BYTE(X) ((X) & 0xff)

.cseg
.include "m16def.inc"
.org 0x0000
RJMP main

; --------------------------------------------------------------------
; Main ρουτίνα.
main:
    ; ----------------------------------------------------------------
    ; Αρχικοποίηση του stack pointer.
    SPI_INIT:
    LDI r25,low(RAMEND)
    OUT Spl,r25
    LDI r25,high(RAMEND)
    OUT sph,r25

    CLR r25
    RCALL main_loop
    RET

; --------------------------------------------------------------------
; Ρουτίνα για την ενημέρωση των LEDs σύμφωνα με την αντίστροφη λογική.
light_leds:
    COM r16
    OUT PORTB, R16
    RET

; --------------------------------------------------------------------
; Ρουτίνα για την αρχικοποίηση των I/O ports και LEDs.
init:
    ; DDRB είναι η έξοδος μας.
    LDI R16, 255
    OUT DDRB, R16
    ; Σιγουρεύουμε ότι όλα τα LEDs είναι σβηστά.
    OUT PORTB, R16
    ; DDRD είναι η είσοδος μας.
    LDI R16, 0
    OUT DDRD, R16
    RET
; --------------------------------------------------------------------
; Ρουτίνα για τον έλεγχο της εισόδου από τα PINs.
check_input:
    ; Έλεγχος για το emergency stop.
    BST R16, 7
    BRTS check_input_start_cold
    ; Απενεργοποίηση του hot και cold.
    ANDI R17, 0b11111100
    ; Ανοίγουμε τα hot/cold stop LEDs
    ORI R17, 0b11100000
    RJMP check_input_return
check_input_start_cold:
    ; Πλήκτρο start cold.
    BST R16, 0
    BRTS check_input_start_hot
    ; Απενεργοποίηση emergency stop και cold stop.
    ANDI R17, 0b01011111
    ; Ενεργοποίηση ένδειξης ανοιχτής βάνας cold.
    ORI R17, 0b00000001
    RJMP check_input_return
check_input_start_hot:
    ; Temperature<SETPOINT και start hot switch.
    ; Έλεγχος για SW3 ή SW1.
    MOV R18, R16
    ANDI R18, 0b00001010
    CPI R18, 0b00001010
    BREQ check_input_temp_g_setpoint
    ; Ενεργοποίηση ένδειξης ανοιχτής βάνας hot.
    ORI R17, 0b00000010
    MOV R16, R17
    ; Απενεργοποίηση emergency stop και hot stop.
    ANDI R17, 0b00100011
    ; Προσαύξηση κατά 1 την ένδειξη αριθμών ενεργοποιήσεων της βάνας hot.
    ; Ουσιαστικά πρόσθεση με το 0b00000100 και κρατάμε τα bits2-4.
    SUBI R16, 252
    ANDI R16, 0b00011100
    ; Συνδυασμός αποτελεσμάτων.
    OR R17, R16
    RJMP check_input_return
check_input_temp_g_setpoint:
    ; Temperature>SETPOINT
    BST R16, 2
    BRTS check_input_stop_cold
    ; Απενεργοποίηση ένδειξης ανοιχτής βάνας hot.
    ANDI R17, 0b11111101
    RJMP check_input_return
check_input_stop_cold:
    ; Πλήκτρο stop cold.
    BST R16, 4
    BRTS check_input_stop_hot
    ; Απενεργοποίηση ένδειξης ανοιχτής βάνας cold.
    ANDI R17, 0b11111110
    ; Ενεργοποίηση cold stop.
    ORI R17, 0b00100000
    RJMP check_input_return
check_input_stop_hot:
    ; Πλήκτρο stop hot.
    BST R16, 5
    BRTS check_input_return
    ; Απενεργοποίηση ένδειξης ανοιχτής βάνας hot.
    ANDI R17, 0b11111101
    ; Ενεργοποίηση hot stop.
    ORI R17, 0b01000000
check_input_return:
    MOV R16, R17
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
    RCALL init
    ; Μηδενισμός του register που μετράει τις διάφορες ενδείξεις.
    ; Ο my_leds λειτουργεί με ορθή λογική και αντριστρέφεται πριν την εξαγωγή του στα LEDs.
    clr my_leds
    ; Η old_input αρχικοποιείται σαν να μην έχει πατηθεί τίποτα ακόμα.
    LDI old_input, 0xFF
    LDI liters, 0
    ; Η outter_loop τρέχει μέχρι να φτάσουμε τον στόχο στα λίτρα.
outter_loop:
    ; Μηδενίζουμε τον 3-byte μετρητή των κύκλων.
    LDI counter_low_byte, 0
    LDI counter_mid_byte, 0
    LDI counter_high_byte, 0
    ; Η inner_loop τρέχει μέχρι να φτάσουμε F_CPU αριθμούς κύκλων (1 δευτερόλεπτο).
inner_loop:
    IN new_input, PIND
    CP new_input, old_input
    ; Αν δεν αλλάξει το input συνεχίζουμε την λούπα.
    BREQ counter_increase_and_compare
    ; in + cp + breq = 4 cycles συνήθως.
    CPI old_input, 0xFF
    BREQ store_whats_pressed
    ; Αν κάτι ήταν πατημένο πρίν, τώρα πρέπει να το επεξεργαστούμε και να ανανεώσουμε τα LEDs.
    MOV R17, my_leds
    MOV R16, whats_pressed
    RCALL check_input
    MOV my_leds, R16
    RCALL light_leds
    RJMP store_old_input
store_whats_pressed:
    ; Αν πριν δεν είχαμε κανένα πατημένο κουμπί, τότε αυτό που είναι πατημένο τώρα είναι το input μας.
    ; Η επεξεργασία του input θα γίνει αφού τα πλήκτρα αφαιθούν.
    MOV whats_pressed, new_input
store_old_input:
    MOV old_input, new_input
counter_increase_and_compare:
    ; Αυξάνουμε τον μετρήτη κατά 14.
    SUBI counter_low_byte, -14
    SBCI counter_mid_byte, -1
    SBCI counter_high_byte, -1
    MOV R17, counter_mid_byte
    MOV R18, counter_high_byte
    ; Σύγκριση counter με F_CPU.
    CPI counter_low_byte, GET_LOW_BYTE(F_CPU)
    SBCI R17, GET_MID_BYTE(F_CPU)
    SBCI R18, GET_HIGH_BYTE(F_CPU)
    BRCS inner_loop
    ; subi + 2*sbci + 2*mov + cpi + 2*sbci + brcs = 10 cycles συνήθως
    ; Συνολικά 14 κύκλοι.

    ; Όταν φτάσουμε εδώ έχει περάσει 1 δευτερόλεπτο, αρα αυξάνουμε τον μετρητή μας.
    ; Ο r16 έχει τιμή 1 αν το cold ήταν ανοιχτό.
    MOV R16, my_leds
    ANDI R16, 0x01
    ; Φορτώνουμε το bit1 απο my_leds στον r17. Ο r17 έχει τιμή 1 αν το hot ήταν ανοιχτό.
    BST my_leds, 1
    LDI R17, 0
    BLD R17, 0
    ; Πιθανές τιμές r16: 0, 1, 2
    ADD R16, R17
    ; Αυξάνουμε τον μετρητή λίτρων ανάλογα.
    ADD liters, R16
    CPI liters, MAX_LITERS
    BRCS outter_loop
    ; Αν φτάσουμε εδώ έχουμε φτάσει το μέγιστο αριθμό λιτρών.
    ; Προβάλουμε για μια τελευταία φορά τα LEDs και επιστρέφουμε.
    MOV R16, my_leds
    RCALL light_leds
    RET
