// https://wiki.osdev.org/Porting_Newlib THANKS!

/* note these headers are all provided by newlib - you don't need to provide them */
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
#include "memory.h"


const static int DEFAULT_PID=123;

extern "C" void _exit(int status) { NOT_IMPLEMENTED(); while(1);} ;


extern "C" int execve(const char *__path, char * const __argv[], char * const __envp[]) 
{
	//errno = ENOMEM;
	return -1;
};

extern "C" int fork() 
{
	//errno = ENOSYS;
	return -1;
}

extern "C" int getpid()
{
	return DEFAULT_PID;
};

extern "C" int kill(int pid, int sig) {
	//errno = EPERM;
	return -1;
}



static unsigned char * next_heap_to_send = 0;
extern "C" void* sbrk (ptrdiff_t __incr) {
	if (next_heap_to_send == NULL) {
		next_heap_to_send = memory_first_usable_memory();
		// if above call returns 0 we are screwed.
	}

	unsigned char * toreturn = next_heap_to_send;
	next_heap_to_send += __incr;

	// Dont use printf since that may trigger us being here..
	console_kprint("Allocating bytes: ");
	console_kprint_uint64((uint64_t) __incr);
	console_kprint("\n");

	return next_heap_to_send;
}




extern "C" int stat(const char *file, struct stat *st) {return 0;};;
extern "C" clock_t times(struct tms *buf) {return 0;};;
extern "C" int unlink(const char *name) {return 0;};;
extern "C" int wait(int *status) {return 0;};;
extern "C" int write(int __fd, const void *__buf, size_t __nbyte) {return 0;};;
extern "C" int gettimeofday(struct timeval *__restrict __p, void *__restrict __tz) {return 0;};;


// Implement the bridge from the printf implementation to actual character output
extern "C" void _putchar(char character) {
	char buff[2];
	buff[0] = character;
	buff[1] = 0;
	console_kprint(buff);
}