; 64bit-switch.asm
; Based on https://wiki.osdev.org/Setting_Up_Long_Mode

POINTER_TABLE_BASE equ 0x2000

%define PAGE_PRESENT    (1 << 0)
%define PAGE_WRITE      (1 << 1)
 
%define CODE_SEG     0x0008
%define DATA_SEG     0x0010

[bits 32]

switch_to_longmode:

;
;
;   CHECK CPUID
;
; 

	; Check if CPUID is supported by attempting to flip the ID bit (bit 21) in
	; the FLAGS register. If we can flip it, CPUID is available.
	; Copy FLAGS in to EAX via stack
	pushfd
	pop eax

	; Copy to ECX as well for comparing later on
	mov ecx, eax

	; Flip the ID bit
	xor eax, 1 << 21

	; Copy EAX to FLAGS via the stack
	push eax
	popfd

	; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
	pushfd
	pop eax

	; Restore FLAGS from the old version stored in ECX (i.e. flipping the ID bit
	; back if it was ever flipped).
	push ecx
	popfd

	; Compare EAX and ECX. If they are equal then that means the bit wasn't
	; flipped, and CPUID isn't supported.
	xor eax, ecx
	jz .NoCPUID
	;;;ret  ;;;; Fall through and continue on.

;
;
; Is extended function avaliable?
;
;

    mov eax, 0x80000000    ; Set the A-register to 0x80000000.
    cpuid                  ; CPU identification.
    cmp eax, 0x80000001    ; Compare the A-register with 0x80000001.
    jb .NoLongMode         ; It is less, there is no long mode.


;
;
; Is Longmode avaliable?
;
;

    mov eax, 0x80000001    ; Set the A-register to 0x80000001.
    cpuid                  ; CPU identification.
    test edx, 1 << 29      ; Test if the LM-bit, which is bit 29, is set in the D-register.
    jz .NoLongMode         ; They aren't, there is no long mode.

;
;
;  Disable old paging
;
;

    mov eax, cr0                                   ; Set the A-register to control register 0.
    and eax, 01111111111111111111111111111111b     ; Clear the PG-bit, which is bit 31.
    mov cr0, eax                                   ; Set control register 0 to the A-register.


;
; Prepare the Funky tables for page-shit and shit
;

    ; Tried to move this to C code compiled to 32 bit
    ; but GDB was wonky for me and would not let debug it
    ;[extern pagetable_init]
    ; Align the stack pointer to 16-bytes 
    ;push esp ; messing with it... so keep it??
    ;and  esp, 0xfffffff0
    ;push edi
    ;call pagetable_init
    ;pop edi
    ;pop esp


; Zero out the 16KiB buffer.
; Since we are doing a rep stosd, count should be bytes/4.   
    push di                           ; REP STOSD alters DI.
    mov ecx, 0x1000 ; 16kb/4
    xor eax, eax
    cld
    rep stosd
    pop di                            ; Get DI back.

; Build the Page Map Level 4.
; es:di points to the Page Map Level 4 table.
    lea eax, [es:di + 0x1000]         ; Put the address of the Page Directory Pointer Table in to EAX.
    or eax, PAGE_PRESENT | PAGE_WRITE ; Or EAX with the flags - present flag, writable flag.
    mov [es:di], eax                  ; Store the value of EAX as the first PML4E.
 
 
; Build the Page Directory Pointer Table.
    lea eax, [es:di + 0x2000]         ; Put the address of the Page Directory in to EAX.
    or eax, PAGE_PRESENT | PAGE_WRITE ; Or EAX with the flags - present flag, writable flag.
    mov [es:di + 0x1000], eax         ; Store the value of EAX as the first PDPTE.
 
 
; Build the Page Directory.
    lea eax, [es:di + 0x3000]         ; Put the address of the Page Table in to EAX.
    or eax, PAGE_PRESENT | PAGE_WRITE ; Or EAX with the flags - present flag, writeable flag.
    mov [es:di + 0x2000], eax         ; Store to value of EAX as the first PDE.
 
 
    push di                           ; Save DI for the time being.
    lea di, [di + 0x3000]             ; Point DI to the page table.
    mov eax, PAGE_PRESENT | PAGE_WRITE    ; Move the flags into EAX - and point it to 0x0000.


    ; Build the Page Table.
.LoopPageTable:
    mov [es:di], eax
    add eax, 0x1000
    add di, 8
    cmp eax, 0x200000;          ; Check if we are done
    jb .LoopPageTable

    ; Bad idea, cant do this in the leaf page table
    ;mov eax, 0xfee00000 | PAGE_PRESENT | PAGE_WRITE
    ;mov [es:di], eax
    ;add di, 8 ; Not needed, we are done iterating, but make it easier for future maintainers.

    pop di                            ; Restore DI.

;
; Enter long mode.
    mov eax, 10100000b                ; Set the PAE and PGE bit.
    mov cr4, eax
 
    mov edx, edi                      ; Point CR3 at the PML4.
    ;[extern P4table]
    ;mov edx, P4table 
    mov cr3, edx
 
    mov ecx, 0xC0000080               ; Read from the EFER MSR. 
    rdmsr    
 
    or eax, 0x00000100                ; Set the LME bit.
    wrmsr
 
    mov ebx, cr0                      ; Activate long mode -
    or ebx,0x80000001                 ; - by enabling paging and protection simultaneously.
    mov cr0, ebx                    
 
	lgdt [GDT64.Pointer]         ; Load the 64-bit global descriptor table.
	jmp GDT64.Code:BEGIN_64       ; Set the code segment and enter 64-bit long mode.

    mov ebx, MSG_SWITCHING_TO_LONGMODE_FAIL
    ;;;call print_string_pm ; 
	jmp $ ; Not reached







[bits 32]

.NoCPUID:
	mov ebx, MSG_NOCPUID
    ;;;call print_string_pm 
	ret

.NoLongMode:
    mov ebx, MSG_NOLONGMODE
    ;;;call print_string_pm 
	ret


MSG_NOLONGMODE: db 'NoLngMd',0
MSG_NOCPUID: db '->NoCP',0 ; NoCPUID
MSG_NOTDONE: db 'More..',0 ; More Needed
MSG_SWITCHING_TO_LONGMODE: db "-> LM",0 ; To Longmode
MSG_SWITCHING_TO_LONGMODE_FAIL: db "FAIL",0

