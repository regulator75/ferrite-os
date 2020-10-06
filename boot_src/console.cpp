
#include "stdint.h"
#include "memory.h"
#include "ports.h"

#define VIDEO_ADDRESS ((char*)0xb8000)
#define MAX_ROWS 25
#define MAX_COLS 80
#define WHITE_ON_BLACK 0x0f
#define RED_ON_WHITE 0xf4

/* Screen i/o ports */
#define REG_SCREEN_CTRL 0x3d4
#define REG_SCREEN_DATA 0x3d5


/* Declaration of private functions */
int get_cursor_offset();
void set_cursor_offset(int offset);
int print_char(char c, int col, int row, char attr);
int get_offset(int col, int row);
int get_offset_row(int offset);
int get_offset_col(int offset);
void int_to_ascii_unsafe(uint64_t i, char * buff);
void int_to_hex_unsafe(uint64_t i, char * buff);
// /**********************************************************
//  * Public Kernel API functions                            *
//  **********************************************************/

/**
 * Print a message on the specified location
 * If col, row, are negative, we will use the current offset
 */
void console_kprint_at(const char *message, int col, int row) {
    /* Set cursor if col/row are negative */
    int offset;
    if (col >= 0 && row >= 0) {
        offset = get_offset(col, row);
    } else {
        offset = get_cursor_offset();
        row = get_offset_row(offset);
        col = get_offset_col(offset);
    }

    /* Loop through message and print it */
    int i = 0;
    while (message[i] != 0) {
        offset = print_char(message[i++], col, row, WHITE_ON_BLACK);
        /* Compute row/col for next iteration */
        row = get_offset_row(offset);
        col = get_offset_col(offset);
    }
}


void console_kprint(const char *message) {
    console_kprint_at(message, -1, -1);
}

void console_kprint_uint64(uint64_t i) {
    char numberbuff[21];// "-9223372036854775806"
    int_to_ascii_unsafe(i,numberbuff);
    console_kprint(numberbuff);
}

void console_kprint_hex(uint64_t i) {
    char numberbuff[19];// "0x0000000000000000"
    int_to_hex_unsafe(i,numberbuff);
    console_kprint(numberbuff);
}


// /**********************************************************
//  * Private kernel functions                               *
//  **********************************************************/


// /**
//  * Innermost print function for our kernel, directly accesses the video memory 
//  *
//  * If 'col' and 'row' are negative, we will print at current cursor location
//  * If 'attr' is zero it will use 'white on black' as default
//  * Returns the offset of the next character
//  * Sets the video cursor to the returned offset
//  */
int print_char(char c, int col, int row, char attr) {
    unsigned char *vidmem = (unsigned char*) VIDEO_ADDRESS;
    if (!attr) attr = WHITE_ON_BLACK;

    //Error control: print a red 'E' if the coords aren't right 
    if (col >= MAX_COLS || row >= MAX_ROWS) {
        vidmem[2*(MAX_COLS)*(MAX_ROWS)-2] = 'E';
        vidmem[2*(MAX_COLS)*(MAX_ROWS)-1] = RED_ON_WHITE;
        return get_offset(col, row);
    }

    int offset;
    if (col >= 0 && row >= 0) offset = get_offset(col, row);
    else offset = get_cursor_offset();

    if (c == '\n') {
        row = get_offset_row(offset);
        offset = get_offset(0, row+1);
    }else if(c == '\t') {
        offset = ((offset/16)+1)*16;
    }else {
        vidmem[offset] = c;
        vidmem[offset+1] = attr;
        offset += 2;
    }

    /* Check if the offset is over screen size and scroll */
    if (offset >= MAX_ROWS * MAX_COLS * 2) {
        int i;
        for (i = 1; i < MAX_ROWS; i++) 
            memory_copy(get_offset(0, i) + VIDEO_ADDRESS,
                        get_offset(0, i-1) + VIDEO_ADDRESS,
                        MAX_COLS * 2);

        /* Blank last line */
        char *last_line = get_offset(0, MAX_ROWS-1) + VIDEO_ADDRESS;
        for (i = 0; i < MAX_COLS * 2; i++) last_line[i] = 0;

        offset -= 2 * MAX_COLS;
    }

    set_cursor_offset(offset);
    return offset;
}

int get_cursor_offset() {
    /* Use the VGA ports to get the current cursor position
     * 1. Ask for high byte of the cursor offset (data 14)
     * 2. Ask for low byte (data 15)
     */

     //return 0;
    port_byte_out(REG_SCREEN_CTRL, 14);
    int offset = port_byte_in(REG_SCREEN_DATA) << 8; /* High byte: << 8 */
    port_byte_out(REG_SCREEN_CTRL, 15);
    offset += port_byte_in(REG_SCREEN_DATA);
    return offset * 2; /* Position * size of character cell */
}

void set_cursor_offset(int offset) {
    /* Similar to get_cursor_offset, but instead of reading we write data */
    offset /= 2;
    port_byte_out(REG_SCREEN_CTRL, 14);
    port_byte_out(REG_SCREEN_DATA, (unsigned char)(offset >> 8));
    port_byte_out(REG_SCREEN_CTRL, 15);
    port_byte_out(REG_SCREEN_DATA, (unsigned char)(offset & 0xff));
}

void console_clear_screen() {
    int screen_size = MAX_COLS * MAX_ROWS;
    int i;
    char *screen = VIDEO_ADDRESS;

    for (i = 0; i < screen_size; i++) {
        screen[i*2] = ' ';
        screen[i*2+1] = WHITE_ON_BLACK;
    }
    set_cursor_offset(get_offset(0, 0));
}


int get_offset(int col, int row) { return 2 * (row * MAX_COLS + col); }
int get_offset_row(int offset) { return offset / (2 * MAX_COLS); }
int get_offset_col(int offset) { return (offset - (get_offset_row(offset)*2*MAX_COLS))/2; }


 void console_init() {

 }
 void console_printchar(char character) {
 	char * next_free_character = VIDEO_ADDRESS;
 	*next_free_character = character;
 	next_free_character++;

	// Ugly wrap for now, assume there is only 100 character
 	// positions on the screen.
 	if(next_free_character > VIDEO_ADDRESS+100)
 		next_free_character = VIDEO_ADDRESS;
 }


static void reverse(char * start, char * end) {
    while(start<end) {
        char tmp = *end;
        *end = *start;
        *start = tmp;
        start++; 
        end--;
    }
}
void int_to_ascii_unsafe(uint64_t n, char str[]) {
    int i, sign;
    if ((sign = n) < 0) n = -n;
    i = 0;
    do {
        str[i++] = n % 10 + '0';
    } while ((n /= 10) > 0); 

    if (sign < 0) str[i++] = '-';
    str[i] = '\0';

    // reverse
    reverse(&str[0],&str[i-1]);
}

void int_to_hex_unsafe(uint64_t n, char str[]) {
    int i;
    i = 0;
    str[i++]='0';
    str[i++]='x';
    do {
        str[i++] = n % 16 + '0';
        if(str[i-1] > '9' ) {
            (str[i-1]-=('9'+1))+='A';
        }
    } while ((n /= 16) > 0); 
    str[i] = '\0';
    // reverse
    reverse(&str[2],&str[i-1]); // 2 because of 0x
}






