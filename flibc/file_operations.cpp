#include <sys/stat.h>
#include <sys/types.h>
#include <sys/fcntl.h>
#include <sys/times.h>
#include <sys/errno.h>
#include <sys/time.h>
#include <stdio.h>
#include <unistd.h> 
#include "console.h" // ferrite kernel
#include "unimplemented.h"

// File operations
extern "C" int close(int file) {return -1;};
extern "C" int fstat(int file, struct stat *st){return 0;};;
extern "C" int isatty(int file){
	if ((file == STDOUT_FILENO) || (file == STDERR_FILENO))
	{ 
		return  1;
	} else {
		//errno = EBADF;
		return  -1;
	}    
}
extern "C" int link(const char *__path1, const char *__path2) {return 0;};;
extern "C" off_t lseek(int __fildes, off_t __offset, int __whence) {return 0;};;
extern "C" int open(const char *name, int flags, ...) {return 0;};;
extern "C" int read(int __fd, void *__buf, size_t __nbyte) {return 0;};;



int fprintf ( FILE * stream, const char * format, ... ) {
	printf("Something reported to fprintf: %s", format);
}
