#ifndef __CONSOLE_H__
#define __CONSOLE_H__
#include "types.h"
/**
 * Basic console output function. Accessible internally from kernel only
 */

void console_init();
void console_printchar(char character); // top left corner

void console_kprint_at(const char *message, int col, int row);
void console_kprint(const char *message);
void console_kprint_uint64(uint64_t i);
void console_kprint_hex(uint64_t i);
void console_clear_screen();

#endif //__CONSOLE_H__
