[bits 16]

memory_map equ 0x5000

; Builds the e820 Memory map
build_memory_map:
        mov di ,0
        mov es, di
        mov di, memory_map          ; Destination for memory map storage
        xor ebx, ebx                ; State for BIOS call, set to 0 initially

.loop:
        mov eax, 0xe820             ; Call int 0x15, 0xe820 memory map
        mov edx, 0x534D4150
        mov ecx, 24
        int 0x15

        jc .done                    ; Carry means unsupported or end of list

        cmp eax, 0x534D4150         ; EAX should match EDX
        jne .done

        jcxz .next_entry            ; Skip zero-length entries

        cmp cl, 20                  ; Test for ACPI 3.X entry
        jbe .good_entry

        test byte [es:di + 20], 1   ; Test ACPI 3.X ignore bit
        je .next_entry

.good_entry:
        add di, 24                  ; Found a valid entry

.next_entry:
        test ebx, ebx               ; Go to next entry
        jne .loop

.done:
        xor ax, ax                  ; Write terminating entry
        mov cx, 12
        rep stosw
        ret





[bits 32] ;; THIS CODE will run before kernel have switched to 64 bit "long" mode.



;;; use the INT 0x15, eax= 0xE820 BIOS function to get a memory map
;;; note: initially di is 0, be sure to set it to a value so that the BIOS code will not be overwritten. 
;;;       The consequence of overwriting the BIOS code will lead to problems like getting stuck in `int 0x15`
;;; inputs: es:di -> destination buffer for 24 byte entries
;;; outputs: bp = entry count, trashes all registers except esi
;;;[extern loaded_entries] ; the number of entries will be stored at loaded_entries
;;;[extern memory_region_map]
;;;mmap_ent equ 0x8000     
;;
;;loaded_entries equ 0x8000
;;memory_region_map equ 0x8004
;;
;;do_e820:
;;	push edi
;;	push ds
;;	push cs
;;	push es
;;	push ebx;
;;	mov ebx,0x01
;;
;;	;mov cs, ebx
;;	mov ds, ebx
;;	mov es, ebx
;;    mov edi, memory_region_map          ; Set di to 0x8004. Otherwise this code will get stuck in `int 0x15` after some entries are fetched 
;;	xor ebx, ebx		; ebx must be 0 to start
;;	xor ebp, ebp		; keep an entry count in bp
;;	mov edx, 0x0534D4150	; Place "SMAP" into edx
;;	mov eax, 0xe820
;;	mov [es:edi + 20], dword 1	; force a valid ACPI 3.X entry
;;	mov ecx, 24		; ask for 24 bytes
;;	int 0x15
;;	jc short .failed	; carry set on first call means "unsupported function"
;;	mov edx, 0x0534D4150	; Some BIOSes apparently trash this register?
;;	cmp eax, edx		; on success, eax must have been reset to "SMAP"
;;	jne short .failed
;;	;test ebx, ebx		; ebx = 0 implies list is only 1 entry long (worthless)
;;	;je short .failed
;;	jmp short .jmpin
;;.e820lp:
;;	mov eax, 0xe820		; eax, ecx get trashed on every int 0x15 call
;;	mov [es:di + 20], dword 1	; force a valid ACPI 3.X entry
;;	mov ecx, 24		; ask for 24 bytes again
;;	int 0x15
;;	jc short .e820f		; carry set means "end of list already reached"
;;	mov edx, 0x0534D4150	; repair potentially trashed register
;;.jmpin:
;;	jcxz .skipent		; skip any 0 length entries
;;	cmp cl, 20		; got a 24 byte ACPI 3.X response?
;;	jbe short .notext
;;	test byte [es:di + 20], 1	; if so: is the "ignore this data" bit clear?
;;	je short .skipent
;;.notext:
;;	mov ecx, [es:di + 8]	; get lower uint32_t of memory region length
;;	or ecx, [es:di + 12]	; "or" it with upper uint32_t to test for zero
;;	jz .skipent		; if length uint64_t is 0, skip entry
;;	inc bp			; got a good entry: ++count, move to next storage spot
;;	add di, 24
;;.skipent:
;;	test ebx, ebx		; if ebx resets to 0, list is complete
;;	jne short .e820lp
;;.e820f:
;;	mov [loaded_entries], bp	; store the entry count
;;	clc			; there is "jc" on end of list to this point, so the carry must be cleared
;;	pop di
;;	ret
;;.failed:
;;	stc			; "function unsupported" error exit
;;	pop di
;;	ret;;