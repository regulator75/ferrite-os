[org 0x7c00] ; This is the adress where the first instruction will be in RAM after BIOS have loaded it

KERNEL_OFFSET equ 0x1000 ; The same one we used when linking the kernel


; Set up the offset for all memory
;mov bx, 0x7c0 ; remember, the segment is automatically <<4 for you
;mov ds, bx

; Set up printing
mov ah, 0x0e ; tty mode

; Set up stack
mov bp, 0x8000 ; this is an address far away from 0x7c00 so that we don't get overwritten
mov sp, bp ; if the stack is empty then sp points to bp


;
; Print out boot banner
;
	mov bx, MSG_BOOTING
	call print	
	call print_nl
;
; Load the kernel that we will jump to after switching to 32 bit mode
;
	call load_kernel


;
; Switch to real mode, re-appear at BEGIN_PM below
;

	call switch_to_pm
	jmp $ ; this will actually never be executed



[bits 16]
load_kernel:
    mov bx, MSG_LOADINGKERNEL
    call print
    mov bx, KERNEL_OFFSET ; Read from disk and store in 0x1000
    mov dh, 4
    mov dl, [BOOT_DRIVE]
    call disk_load
    
    mov bx, MSG_DONE
    call print    
    ret



; Include the function print, print_nl and hex16_print
%include "boot_src/boot_sect_print.asm"
%include "boot_src/boot_sect_disk.asm"


; Data
MSG_BOOTING: db 'Booting Ferrite OS...',0
MSG_32BIT_FAIL: db 'Failed to enter 32 bit mode',0
MSG_32BIT: db 'Entered 32 bit mode',0
MSG_LOADINGKERNEL: db 'Loading Kernel...',0
MSG_DONE: db 'Done',0
MSG_DEBUG: db 'Debug',0
BOOT_DRIVE db 0 ; It is a good idea to store it in memory because 'dl' may get overwritten


%include "boot_src/32bit-gdt.asm"
%include "boot_src/32bit-print.asm"
%include "boot_src/32bit-switch.asm"

[bits 32]
BEGIN_PM: ; after the switch we will get here
    mov ebx, MSG_32BIT
    call print_string_pm ; Note that this will be written at the top left corner

    call KERNEL_OFFSET

    mov ebx, MSG_DEBUG
    call print_string_pm ; Note that this will be written at the top left corner

    jmp $ ; Never reached





times 510-($-$$) db 0
dw 0xaa55