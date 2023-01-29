;; Based on https://wiki.osdev.org/APIC_timer

global timer_install

%define apic            00000000fee00000h 
;%define apic            00000000fec00000h 
 
%define APIC_APICID     20h
%define APIC_APICVER	30h
%define APIC_TASKPRIOR	80h
%define APIC_EOI	    0B0h
%define APIC_LDR	    0D0h
%define APIC_DFR	    0E0h
%define APIC_SPURIOUS	0F0h
%define APIC_ESR	    280h
%define APIC_ICRL	    300h
%define APIC_ICRH	    310h
%define APIC_LVT_TMR	320h
%define APIC_LVT_PERF	340h
%define APIC_LVT_LINT0	350h
%define APIC_LVT_LINT1	360h
%define APIC_LVT_ERR	370h
%define APIC_TMRINITCNT	380h
%define APIC_TMRCURRCNT	390h
%define APIC_TMRDIV	    3E0h
%define APIC_LAST	    38Fh
%define APIC_DISABLE	10000h
%define APIC_SW_ENABLE	100h
%define APIC_CPUFOCUS	200h
%define APIC_NMI	    (4<<8)
%define TMR_PERIODIC	20000h
%define TMR_BASEDIV	    (1<<20)

[bits 64] 


	;Interrupt Service Routines
isr_dummytmr:	
    mov         rax, apic+APIC_EOI
    mov			dword [rax], 0
	iret
isr_spurious:	iret
    ;function to set a specific interrupt gate in IDT
    ;al=interrupt
    ;ebx=isr entry point
writegate:	
	ret



timer_install:
    push rdx
    push rax

    ;you should read MSR, get APIC base and map to "apic"
    ;you should have used lidt properly

    ;set up isrs
    ;mov			al, 32
    ;mov			ebx, isr_dummytmr
    ;call			writegate
    ;mov			al, 39
    ;mov			ebx, isr_spurious
    ;call			writegate

    ;initialize LAPIC to a well known state
    mov         rax, 0x00000000fee00000
    mov 		dword [rax+APIC_DFR], 0FFFFFFFFh ;
    mov			edx, dword [rax+APIC_LDR]
    and			edx, 00FFFFFFh
    or			al, 1
    mov			dword [rax+APIC_LDR], edx
    mov			dword [rax+APIC_LVT_TMR], APIC_DISABLE
    mov			dword [rax+APIC_LVT_PERF], APIC_NMI
    mov			dword [rax+APIC_LVT_LINT0], APIC_DISABLE
    mov			dword [rax+APIC_LVT_LINT1], APIC_DISABLE
    mov			dword [rax+APIC_TASKPRIOR], 0
    ;okay, now we can enable APIC
    ;global enable
    mov			ecx, 1bh
    rdmsr
    bts			eax, 11
    wrmsr
    ;software enable, map spurious interrupt to dummy isr
    mov         rax, 0x00000000fee00000
    mov			dword [rax+APIC_SPURIOUS], 39+APIC_SW_ENABLE
    ;map APIC timer to an interrupt, and by that enable it in one-shot mode
    mov			dword [rax+APIC_LVT_TMR], 32
    ;set up divide value to 16
    mov			dword [rax+APIC_TMRDIV], 03h

    ;ebx=0xFFFFFFFF;
    xor			ebx, ebx
    dec			ebx

    ;initialize PIT Ch 2 in one-shot mode
    ;waiting 1 sec could slow down boot time considerably,
    ;so we'll wait 1/100 sec, and multiply the counted ticks
    mov			dx, 61h
    in			al, dx
    and			al, 0fdh
    or			al, 1
    out			dx, al
    mov			al, 10110010b
    out			43h, al
    ;1193180/100 Hz = 11931 = 2e9bh
    mov			al, 9bh		;LSB
    out			42h, al
    in			al, 60h		;short delay
    mov			al, 2eh		;MSB
    out			42h, al
    ;reset PIT one-shot counter (start counting)
    in			al, dx
    and			al, 0feh
    out			dx, al		;gate low
    or			al, 1
    out			dx, al		;gate high
    ;reset APIC timer (set counter to -1)
    mov			dword [apic+APIC_TMRINITCNT], ebx
    ;now wait until PIT counter reaches zero
timer_setup_local_1:
	in			al, dx
    and			al, 20h
    jz			timer_setup_local_1
    ;stop APIC timer
    mov			dword [apic+APIC_LVT_TMR], APIC_DISABLE
    ;now do the math...
    xor			eax, eax
    xor			ebx, ebx
    dec			eax
    ;get current counter value
    mov			ebx, dword [apic+APIC_TMRCURRCNT]
    ;it is counted down from -1, make it positive
    sub			eax, ebx
    inc			eax
    ;we used divide value different than 1, so now we have to multiply the result by 16
    shl			eax, 4		;*16
    xor			edx, edx
    ;moreover, PIT did not wait a whole sec, only a fraction, so multiply by that too
    mov			ebx, 100	;*PITHz
    mul			ebx
;-----edx:eax now holds the CPU bus frequency-----
    ;now calculate timer counter value of your choice
    ;this means that tasks will be preempted 1000 times in a second. 100 is popular too.
    mov			ebx, 1000
    xor			edx, edx
    div			ebx
    ;again, we did not use divide value of 1
    shr			eax, 4		;/16
    ;sanity check, min 16
    cmp			eax, 010h
    jae			timer_setup_local_2
    mov			eax, 010h
    ;now eax holds appropriate number of ticks, use it as APIC timer counter initializer
timer_setup_local_2:
	mov			dword [apic+APIC_TMRINITCNT], eax
    ;finally re-enable timer in periodic mode
    mov			dword [apic+APIC_LVT_TMR], 32 ; or??? TMR_PERIODIC
    ;setting divide value register again not needed by the manuals
    ;although I have found buggy hardware that required it
    mov			dword [apic+APIC_TMRDIV], 03h

    pop rax
    pop rdx
    ret