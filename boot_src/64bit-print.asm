; 64bit-print.asm
; BASED ON https://github.com/cfenollosa/os-tutorial/blob/master/08-32bit-print/32bit-print.asm
[bits 64] ; using 32-bit protected mode

; this is how constants are defined
VIDEO_MEMORY equ 0xb8000
WHITE_ON_BLACK equ 0x0f ; the color byte for each character

print64_string_pm:
    push rdx
    push rax
    mov rdx, VIDEO_MEMORY

print64_string_pm_loop:
    mov al, [rbx] ; [rbx] is the address of our character
    mov ah, WHITE_ON_BLACK

    cmp al, 0 ; check if end of string
    je print64_string_pm_done

    mov [rdx], ax ; store character + attribute in video memory
    add rbx, 1 ; next char
    add rdx, 2 ; next video memory position

    jmp print64_string_pm_loop

print64_string_pm_done:
    pop rax
    pop rdx
    ret