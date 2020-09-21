;kernel.asm

;[org 0x1000]
[bits 32]
kernel_main:
    mov ebx, MSG_KERNEL_RUNNING
    call print_string_pm ; Note that this will be written at the top left corner

	mov edi, 0x9000

	call switch_to_longmode

	jmp $


MSG_KERNEL_RUNNING: db 'Kernel running...',0

%include "boot_src/32bit-print.asm"
%include "boot_src/64bit-print.asm"
%include "boot_src/64bit-switch.asm"
%include "boot_src/64bit-gdt.asm"

MSG_64_IS_DA_SHIT: db 'Kernel running in 64 bit mode YEAH!',0
MSG_64_FROM_C_IS_DA_SHIT: db 'This printout came from C',0



[BITS 64]
BEGIN_64:


    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Blank out the screen to a blue color.
    mov edi, 0xB8000
    mov rcx, 500                      ; Since we are clearing uint64_t over here, we put the count as Count/4.
    mov rax, 0x1F201F201F201F20       ; Set the value to set the screen to: Blue background, white foreground, blank spaces.
    rep stosq                         ; Clear the entire screen. 

    ; Display "Hello World!"
    mov edi, 0x00b8000              
 
    mov rax, 0x1F6C1F6C1F651F48    
    mov [edi],rax
 

    mov rax, 0x1F6F1F571F201F6F
    mov [edi + 8], rax

    mov rax, 0x1F211F641F6C1F72
    mov [edi + 16], rax


	mov rbx, MSG_64_IS_DA_SHIT	
	call print64_string_pm

    [extern kernel_c_entry]
    call kernel_c_entry

;    cli                           ; Clear the interrupt flag.
;    mov ax, GDT64.Data            ; Set the A-register to the data descriptor.
;    mov ds, ax                    ; Set the data segment to the A-register.
;    mov es, ax                    ; Set the extra segment to the A-register.
;    mov fs, ax                    ; Set the F-segment to the A-register.
;    mov gs, ax                    ; Set the G-segment to the A-register.
;    mov ss, ax                    ; Set the stack segment to the A-register.
;    mov edi, 0xB8000              ; Set the destination index to 0xB8000.
;    mov rax, 0x1F201F201F201F20   ; Set the A-register to 0x1F201F201F201F20.
;    mov ecx, 500                  ; Set the C-register to 500.
;    rep stosq                     ; Clear the screen.
    
    jmp $
    hlt                           ; Halt the processor.


times 1024-($-$$) db 0