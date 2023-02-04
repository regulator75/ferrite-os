//
// Switching to CPP to figure out how to invoke these bad boys
//

#include "console.h"
#include "interrupts.h"
#include "memory.h"
#include "keyboard.h"
#include <stdio.h>
#include <stdlib.h>

void * __attribute__((nothrow)) malloc(size_t);

void timer_install();

void kernel_c_entry(void) {
	memory_phys_map_init(0x5000);
	console_init();
	pagetable_init(0x9000); // This is where the asm code places it. Ugly code I know. 
	interrupts_install();	
//	timer_install();

	volatile int b = 0;

	console_kprint_at("Ferrite OS 0.0.0.0",0,1);
	console_kprint("\nNow try the keyboard");

	console_kprint("\nm -> print memory layout");
	console_kprint("\np -> Page table info");
	while(1==1) {
		char c = (char)keyboard_getc();
		console_kprint_char(c);
		console_kprint_char('\n');
		switch(c) {
			case 'm': memory_phys_print_map(); break;
			case 'p': pagetable_debug_print(); break;

		}

	}
		;
}