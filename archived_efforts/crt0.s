.section .text

.global _start
.global _exit
_start:
	# Set up end of the stack frame linked list.
	movq $0, %rbp
	pushq %rbp # rip=0
	pushq %rbp # rbp=0
	movq %rsp, %rbp

	# We need those in a moment when we call main.
	pushq %rsi
	pushq %rdi

	# Prepare signals, memory allocation, stdio and such.
	####call initialize_standard_library

	# Run the global constructors.
	####call _init
	### TODO fix this..

	# Restore argc and argv.
	popq %rdi
	popq %rsi

	# Run main
	call main

	# Terminate the process with the exit code.
	movl %eax, %edi
	call exit

exit:
_exit:
	hlt

.size _start, . - _start

