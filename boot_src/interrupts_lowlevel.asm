[bits 64] ; using 64-bit 



; Defined in isr.c
[extern interupt_service_request_handler]
[extern interupt_request_line_handler]

%macro pushaq 0
    push rax
    push rcx
    push rdx
    push rbx
    push rbp
    push rsi
    push rdi
%endmacro

%macro popaq 0
    pop rdi    
    pop rsi    
    pop rbp    
    pop rbx    
    pop rdx    
    pop rcx
    pop rax
%endmacro

; Common ISR code
isr_common_stub:
    ; 1. Save CPU state
	pushaq 
	mov rax, ds ; Lower 16-bits of eax = ds.
	push rax ; save the data segment descriptor
	mov ax, 0x10  ; kernel data segment descriptor
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	
    ; 2. Call C handler
	call interupt_service_request_handler
	
    ; 3. Restore state
    ; (Note on 64 bit, im not sure if we actually need to do this
    ; but most reference code suggest this is wholesome. Revisit
    ; when we introduce processes and privelage levels)
	pop rax 
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	popaq
	add rsp, 16 ; Cleans up the pushed error code and pushed ISR number
	sti
	iretq ; 64 bit return 

irq_common_stub:
    ; 1. Save CPU state
    pushaq
    mov rax, ds ; Lower 16-bits of eax = ds.
    push rax ; save the data segment descriptor
    mov ax, 0x10  ; kernel data segment descriptor
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    ; 2. Call C handler
    call interupt_request_line_handler
    
    ; 3. Restore state
    ; (Note on 64 bit, im not sure if we actually need to do this
    ; but most reference code suggest this is wholesome. Revisit
    ; when we introduce processes and privelage levels)

    pop rbx  ;; NOTE NOT COMMON WITH ISR. Also not pop ebx like in tutorials
    mov ds, bx ; diff
    mov es, bx ; diff
    mov fs, bx ; diff
    mov gs, bx ; diff
    popaq
    add rsp, 16 ; Cleans up the pushed error code and pushed ISR number
    sti
    iretq ; 64 bit return 

	
; We don't get information about which interrupt was caller
; when the handler is run, so we will need to have a different handler
; for every interrupt.
; Furthermore, some interrupts push an error code onto the stack but others
; don't, so we will push a dummy error code for those which don't, so that
; we have a consistent stack for all of them.

; First make the ISRs global
global asm_isr0
global asm_isr1
global asm_isr2
global asm_isr3
global asm_isr4
global asm_isr5
global asm_isr6
global asm_isr7
global asm_isr8
global asm_isr9
global asm_isr10
global asm_isr11
global asm_isr12
global asm_isr13
global asm_isr14
global asm_isr15
global asm_isr16
global asm_isr17
global asm_isr18
global asm_isr19
global asm_isr20
global asm_isr21
global asm_isr22
global asm_isr23
global asm_isr24
global asm_isr25
global asm_isr26
global asm_isr27
global asm_isr28
global asm_isr29
global asm_isr30
global asm_isr31

global asm_irq0
global asm_irq1
global asm_irq2
global asm_irq3
global asm_irq4
global asm_irq5
global asm_irq6
global asm_irq7
global asm_irq8
global asm_irq9
global asm_irq10
global asm_irq11
global asm_irq12
global asm_irq13
global asm_irq14
global asm_irq15


;
; ISRs
;

; 0: Divide By Zero Exception
asm_isr0:
    cli
    push byte 0
    push byte 0
    jmp isr_common_stub

; 1: Debug Exception
asm_isr1:
    cli
    push byte 0
    push byte 1
    jmp isr_common_stub

; 2: Non Maskable Interrupt Exception
asm_isr2:
    cli
    push byte 0
    push byte 2
    jmp isr_common_stub

; 3: Int 3 Exception
asm_isr3:
    cli
    push byte 0
    push byte 3
    jmp isr_common_stub

; 4: INTO Exception
asm_isr4:
    cli
    push byte 0
    push byte 4
    jmp isr_common_stub

; 5: Out of Bounds Exception
asm_isr5:
    cli
    push byte 0
    push byte 5
    jmp isr_common_stub

; 6: Invalid Opcode Exception
asm_isr6:
    cli
    push byte 0
    push byte 6
    jmp isr_common_stub

; 7: Coprocessor Not Available Exception
asm_isr7:
    cli
    push byte 0
    push byte 7
    jmp isr_common_stub

; 8: Double Fault Exception
asm_isr8:
    cli
    ; Error code already pushed here
    push byte 8
    jmp isr_common_stub

; 9: Coprocessor Segment Overrun Exception
asm_isr9:
    cli
    push byte 0
    push byte 9
    jmp isr_common_stub

; 10: Bad TSS Exception
asm_isr10:
    cli
    ; Error code already pushed here
    push byte 10
    jmp isr_common_stub

; 11: Segment Not Present Exception
asm_isr11:
    cli
    ; Error code already pushed here
    push byte 11
    jmp isr_common_stub

; 12: Stack Fault Exception
asm_isr12:
    cli
    ; Error code already pushed here
    push byte 12
    jmp isr_common_stub

; 13: General Protection Fault Exception
asm_isr13:
    cli
    ; Error code already pushed here
    push byte 13
    jmp isr_common_stub

; 14: Page Fault Exception
asm_isr14:
    cli
    ; Error code already pushed here
    push byte 14
    jmp isr_common_stub

; 15: Reserved Exception
asm_isr15:
    cli
    push byte 0
    push byte 15
    jmp isr_common_stub

; 16: Floating Point Exception
asm_isr16:
    cli
    push byte 0
    push byte 16
    jmp isr_common_stub

; 17: Alignment Check Exception
asm_isr17:
    cli
    push byte 0
    push byte 17
    jmp isr_common_stub

; 18: Machine Check Exception
asm_isr18:
    cli
    push byte 0
    push byte 18
    jmp isr_common_stub

; 19: Reserved
asm_isr19:
    cli
    push byte 0
    push byte 19
    jmp isr_common_stub

; 20: Reserved
asm_isr20:
    cli
    push byte 0
    push byte 20
    jmp isr_common_stub

; 21: Reserved
asm_isr21:
    cli
    push byte 0
    push byte 21
    jmp isr_common_stub

; 22: Reserved
asm_isr22:
    cli
    push byte 0
    push byte 22
    jmp isr_common_stub

; 23: Reserved
asm_isr23:
    cli
    push byte 0
    push byte 23
    jmp isr_common_stub

; 24: Reserved
asm_isr24:
    cli
    push byte 0
    push byte 24
    jmp isr_common_stub

; 25: Reserved
asm_isr25:
    cli
    push byte 0
    push byte 25
    jmp isr_common_stub

; 26: Reserved
asm_isr26:
    cli
    push byte 0
    push byte 26
    jmp isr_common_stub

; 27: Reserved
asm_isr27:
    cli
    push byte 0
    push byte 27
    jmp isr_common_stub

; 28: Reserved
asm_isr28:
    cli
    push byte 0
    push byte 28
    jmp isr_common_stub

; 29: Reserved
asm_isr29:
    cli
    push byte 0
    push byte 29
    jmp isr_common_stub

; 30: Reserved
asm_isr30:
    cli
    push byte 0
    push byte 30
    jmp isr_common_stub

; 31: Reserved
asm_isr31:
    cli
    push byte 0
    push byte 31
    jmp isr_common_stub




;
; IRQs
;
asm_irq0:
    cli
    push byte 0
    push byte 32
    jmp irq_common_stub

asm_irq1:
    cli
    push byte 1
    push byte 33
    jmp irq_common_stub

asm_irq2:
    cli
    push byte 2
    push byte 34
    jmp irq_common_stub

asm_irq3:
    cli
    push byte 3
    push byte 35
    jmp irq_common_stub

asm_irq4:
    cli
    push byte 4
    push byte 36
    jmp irq_common_stub

asm_irq5:
    cli
    push byte 5
    push byte 37
    jmp irq_common_stub

asm_irq6:
    cli
    push byte 6
    push byte 38
    jmp irq_common_stub

asm_irq7:
    cli
    push byte 7
    push byte 39
    jmp irq_common_stub

asm_irq8:
    cli
    push byte 8
    push byte 40
    jmp irq_common_stub

asm_irq9:
    cli
    push byte 9
    push byte 41
    jmp irq_common_stub

asm_irq10:
    cli
    push byte 10
    push byte 42
    jmp irq_common_stub

asm_irq11:
    cli
    push byte 11
    push byte 43
    jmp irq_common_stub

asm_irq12:
    cli
    push byte 12
    push byte 44
    jmp irq_common_stub

asm_irq13:
    cli
    push byte 13
    push byte 45
    jmp irq_common_stub

asm_irq14:
    cli
    push byte 14
    push byte 46
    jmp irq_common_stub

asm_irq15:
    cli
    push byte 15
    push byte 47
    jmp irq_common_stub    