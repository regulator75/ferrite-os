//
// Switching to CPP to figure out how to invoke these bad boys
//

#include "console.h"
#include "interrupts.h"

class CppLibTesterClazz{
public:
	CppLibTesterClazz(int x): m_x(x) {}
private:
	int m_x;

};
volatile CppLibTesterClazz * p_instance;


/*void kernel_cpp_entry() {
	p_instance = new CppLibTesterClazz(42);

}*/

extern "C" void kernel_c_entry(void) {
	console_init();
	interrupts_install();
	volatile int b = 0;

	console_kprint_at("Ferrite OS 0.0.0.0",0,1);



	console_kprint_at("Hello at 10,3\n",10,3);

	console_kprint("\nTesting multi line\nSecond line");

	// trigger division by zero
	//int a = 4/b;

	for(int i = 0 ; i < 10 ; i++) {
		console_kprint("\nIteration: "); console_kprint_int(i);
	}
	console_kprint("\nNow try the keyboard");
	while(true)
		;
}