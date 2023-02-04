#include "keyboard.h"

#define SCANCODE_BUFFER_LENGTH 8
/*static*/ volatile int scancode_buffer_head = 0;
/*static*/ volatile int scancode_buffer_tail = 0;

/*static*/ unsigned int scancode_buffer[SCANCODE_BUFFER_LENGTH];


/** Local functions */
int _scancode_to_unicode( unsigned int scancode ) {
    const char kbd_US [128] =
        {
            0,  27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',   
            '\t', /* <-- Tab */
            'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',     
            0, /* <-- control key */
            'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`',  0, '\\', 'z',
            'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/',   0,
            '*',
            0,  /* Alt */
            ' ',  /* Space bar */
            0,  /* Caps lock */
            0,  /* 59 - F1 key ... > */
            0,   0,   0,   0,   0,   0,   0,   0,
            0,  /* < ... F10 */
            0,  /* 69 - Num lock*/
            0,  /* Scroll Lock */
            0,  /* Home key */
            0,  /* Up Arrow */
            0,  /* Page Up */
            '-',
            0,  /* Left Arrow */
            0,
            0,  /* Right Arrow */
            '+',
            0,  /* 79 - End key*/
            0,  /* Down Arrow */
            0,  /* Page Down */
            0,  /* Insert Key */
            0,  /* Delete Key */
            0,   0,   0,
            0,  /* F11 Key */
            0,  /* F12 Key */
            0,  /* All other keys are undefined */
        };  

    int toReturn;
    if(scancode < 128) {
        toReturn = kbd_US[scancode];
    } else {
        toReturn = 0;
    }

    return toReturn;
}


// TODO tweak the tail and head code so we can use all elements of the
// circular buffer.
void keyboard_register_keypress_scancode(unsigned int scancode) {
    if((scancode_buffer_tail+1)%SCANCODE_BUFFER_LENGTH != scancode_buffer_head) {
        // There is room in the circular buffer, add.
        scancode_buffer[scancode_buffer_tail] = scancode;
        scancode_buffer_tail+=1;
        scancode_buffer_tail%=SCANCODE_BUFFER_LENGTH;
    } else {
        // Drop.
    }
}


/** Read the next character from the 
 *  keyboard. Block and wait if there
 *  is nothing there.
*/
int keyboard_getc() {
    int toReturn = 0; // While this is 0, dont return.
    while(toReturn == 0) {

        // If there is something in the buffer...
        if(scancode_buffer_head != scancode_buffer_tail) {
            // ... process it.
            toReturn = _scancode_to_unicode( scancode_buffer[scancode_buffer_head] );
            scancode_buffer_head+=1;
            scancode_buffer_head%=SCANCODE_BUFFER_LENGTH;
            // At this point "toReturn" may contain 0, because the user
            // pressed an arrow key or something, in which case
            // we will not return.
        }
        // Wait for something to come in.
    }
    return toReturn;
}