;kernel.asm

[org 0x1000]
[bits 32]

kernel_main:
    mov ebx, MSG_KERNEL_RUNNING
    call print_string_pm ; Note that this will be written at the top left corner
	
	call switch_to_longmode

	jmp $

%include "boot_src/32bit-print.asm"
%include "boot_src/64bit-print.asm"
%include "boot_src/64bit-switch.asm"
%include "boot_src/64bit-gdt.asm"


MSG_KERNEL_RUNNING: db 'Kernel running...',0
MSG_64_IS_DA_SHIT: db 'Kernel running in 64 bit mode YEAH!',0


[BITS 64]
BEGIN_64:

	
	mov rbx, MSG_64_IS_DA_SHIT	
	call print64_string_pm
	jmp $

    cli                           ; Clear the interrupt flag.
    mov ax, GDT64.Data            ; Set the A-register to the data descriptor.
    mov ds, ax                    ; Set the data segment to the A-register.
    mov es, ax                    ; Set the extra segment to the A-register.
    mov fs, ax                    ; Set the F-segment to the A-register.
    mov gs, ax                    ; Set the G-segment to the A-register.
    mov ss, ax                    ; Set the stack segment to the A-register.
    mov edi, 0xB8000              ; Set the destination index to 0xB8000.
    mov rax, 0x1F201F201F201F20   ; Set the A-register to 0x1F201F201F201F20.
    mov ecx, 500                  ; Set the C-register to 500.
    rep stosq                     ; Clear the screen.
    hlt                           ; Halt the processor.

times 512-($-$$) db 0
