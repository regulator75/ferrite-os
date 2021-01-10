#ifndef _UNIMPLEMENTED_H_
#define _UNIMPLEMENTED_H_

// Use this macro to print the simplest of error messages and block.
#define NOT_IMPLEMENTED() assert_fail_not_implemented(__FUNCTION__, __FILE__, __LINE__)

void assert_fail_not_implemented(const char * funcname, const char * file, int line);


#endif //_UNIMPLEMENTED_H_