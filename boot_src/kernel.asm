;kernel.asm

[org 0x1000]
[bits 32]

kernel_main:
    mov ebx, MSG_KERNEL_RUNNING
    call print_string_pm ; Note that this will be written at the top left corner
	jmp $

%include "boot_src/32bit-print.asm"


MSG_KERNEL_RUNNING: db 'Kernel running...',0

times 512-($-$$) db 0

