#include "unimplemented.h"
#include "console.h"

void assert_fail_not_implemented(const char * funcname, const char * file, int line) {
	console_kprint("Function ");
	console_kprint(funcname);
	console_kprint(" not implemented. called from ");
	console_kprint(file);
	console_kprint(":");
	console_kprint_uint64(line);
	while(1==1)
		; // Hang.
}


