//
// Switching to CPP to figure out how to invoke these bad boys
//

#include "console.h"
#include "interrupts.h"
#include "memory.h"
#include <stdio.h>
#include <stdlib.h>

void * __attribute__((nothrow)) malloc(size_t);

/*void kernel_cpp_entry() {
	p_instance = new CppLibTesterClazz(42);

}*/
void kernel_c_entry(void) {
	console_init();
	interrupts_install();	

	volatile int b = 0;

	console_kprint_at("Ferrite OS 0.0.0.0",0,1);

	console_kprint_at("Hello at 10,3\n",10,3);

	console_kprint("\nTesting multi line\nSecond line");

	memory_analyze_and_print();

	// This seems broken at the moment
	//printf("Hello Printf\n");

//	CppLibTesterClazz clz(0);
//	CppLibTesterClazz * pcls = new CppLibTesterClazz(1);
	//CppLibTesterClazz * pz = new CppLibTesterClazz(2);

	//void * p= malloc(34);

	console_kprint("\nNow try the keyboard");

	//free(p);

	while(1==1)
		;
}