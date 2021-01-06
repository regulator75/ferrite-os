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
 
extern "C" void _exit(int status) {while(0==0);};
extern "C" int close(int file) {return -1;};
extern "C" char **environ; /* pointer to array of char * strings that define the current environment variables */
extern "C" int execve(const char *__path, char * const __argv[], char * const __envp[]) {return 0;};
extern "C" int fork() {return 0;};;
extern "C" int fstat(int file, struct stat *st){return 0;};;
extern "C" int getpid(){return 0;};;
extern "C" int isatty(int file){
	if ((file == STDOUT_FILENO) || (file == STDERR_FILENO))
	{ 
		return  1;
	} else {
		//errno = EBADF;
		return  -1;
	}    
}

extern "C" int kill(int pid, int sig) {return 0;};;
extern "C" int link(const char *__path1, const char *__path2) {return 0;};;
extern "C" off_t lseek(int __fildes, off_t __offset, int __whence) {return 0;};;
extern "C" int open(const char *name, int flags, ...) {return 0;};;
extern "C" int read(int __fd, void *__buf, size_t __nbyte) {return 0;};;
extern "C" void* sbrk (ptrdiff_t __incr) {return 0;};;
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