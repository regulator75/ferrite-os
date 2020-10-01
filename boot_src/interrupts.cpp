#include "console.h"
#include "types.h"

/** Interrupts.cpp
 *
 */


/** Types
*/

/**
 * In the table of all the descriptors, there will
 * be 256 of this instances. Each one located by the 
 * CPU based on the IRQ number. 
 */
struct gate_struct {
	uint16_t        low_offset;
	uint16_t        sel;

	// Section that in linux is called idt_bits

	uint8_t always0;
    /* First byte
     * Bit 7: "Interrupt is present"
     * Bits 6-5: Privilege level of caller (0=kernel..3=user)
     * Bit 4: Set to 0 for interrupt gates
     * Bits 3-0: bits 1110 = decimal 14 = "32 bit interrupt gate" */
    uint8_t flags; 

	uint16_t        middle_offset;

	// 64 bit stuff
	uint32_t        high_offset;
	uint32_t        reserved;
} __attribute__((packed));

/** This tiny structure is pointed to by the IDTR, the CPU register 
 * that is the root used by the CPU to figure out what to do in the 
 * event of an interrupt. */

typedef struct {
    uint16_t limit;
    uint64_t base; // Note 64 bit size in x86_64 bit mode
} __attribute__((packed)) idt_register_t;


typedef struct {
   uint32_t ds; /* Data segment selector */
   uint32_t edi, esi, ebp, esp, ebx, edx, ecx, eax; /* Pushed by pusha. */
   uint32_t int_no, err_code; /* Interrupt number and error code (if applicable) */
   uint32_t eip, cs, eflags, useresp, ss; /* Pushed by the processor automatically */
} isr_service_handler_parameters;

/** Data
*/

// Instansiate a table of interrupt handlers.
// This thing needs to be initalized properly.
static gate_struct s_idt[256]; // It must always be 256, its the CPU architecture that says this.

// Instansiate the "root node for interrupt information".
// This instance will be pointed to by
static idt_register_t s_idt_reg;
/* A pointer to the array of interrupt handlers.
 * Assembly instruction 'lidt' will read it */

/** Support for messages */
const char  *interupt_service_request_handler_exception_messages[] = {
    "Division By Zero",
    "Debug",
    "Non Maskable Interrupt",
    "Breakpoint",
    "Into Detected Overflow",
    "Out of Bounds",
    "Invalid Opcode",
    "No Coprocessor",
    "Double Fault",
    "Coprocessor Segment Overrun",
    "Bad TSS",
    "Segment Not Present",
    "Stack Fault",
    "General Protection Fault",
    "Page Fault",
    "Unknown Interrupt",
    "Coprocessor Fault",
    "Alignment Check",
    "Machine Check",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved"
};


static uint16_t lowest_16(const void * address) {
	return (uint16_t)(((uint64_t)address)& 0xFFFF);
};
static uint16_t secondlowest_16(const void * address) {
	return (uint16_t)((((uint64_t)address) >> 16) & 0xFFFF);
};
static uint32_t high_32(const void * address) {
	return (uint32_t)((((uint64_t)address) >> 32) & 0xFFFFFFFF);
}

void set_idt_gate(int n, const void * handler) {
    s_idt[n].low_offset = lowest_16(handler);
    s_idt[n].sel = 0x08; // WHAT IS THIS? Some docs says 8 //KERNEL_CS;
    s_idt[n].always0 = 0;
    s_idt[n].flags = 0x8E; 
    s_idt[n].middle_offset = secondlowest_16(handler);
	s_idt[n].high_offset = high_32(handler); // I think this is right?
	s_idt[n].reserved = 0; //0, because why not.    
}

void load_idt_registry() {
    s_idt_reg.base = (uint64_t) &s_idt;
    s_idt_reg.limit = 256 * sizeof(gate_struct) - 1;
   
    // Discussion on why not to use "m" rather than "r" can be found here
    // https://stackoverflow.com/questions/56424988/gcc-inline-assembly-error-invalid-instruction-suffix-for-lidt
    __asm__ __volatile__("lidt (%0)" : : "r" (&s_idt_reg) : "memory");
}

// Called from the ASM portion of this system, hence the extern "C"
extern "C" void interupt_service_request_handler(isr_service_handler_parameters r) {
    console_kprint("received interrupt: ");
    console_kprint_int(r.int_no);
    console_kprint("\n");
    console_kprint(interupt_service_request_handler_exception_messages[r.int_no]);
    console_kprint("\n");
}

extern "C" void asm_isr0();
extern "C" void asm_isr1();
extern "C" void asm_isr2();
extern "C" void asm_isr3();
extern "C" void asm_isr4();
extern "C" void asm_isr5();
extern "C" void asm_isr6();
extern "C" void asm_isr7();
extern "C" void asm_isr8();
extern "C" void asm_isr9();
extern "C" void asm_isr10();
extern "C" void asm_isr11();
extern "C" void asm_isr12();
extern "C" void asm_isr13();
extern "C" void asm_isr14();
extern "C" void asm_isr15();
extern "C" void asm_isr16();
extern "C" void asm_isr17();
extern "C" void asm_isr18();
extern "C" void asm_isr19();
extern "C" void asm_isr20();
extern "C" void asm_isr21();
extern "C" void asm_isr22();
extern "C" void asm_isr23();
extern "C" void asm_isr24();
extern "C" void asm_isr25();
extern "C" void asm_isr26();
extern "C" void asm_isr27();
extern "C" void asm_isr28();
extern "C" void asm_isr29();
extern "C" void asm_isr30();
extern "C" void asm_isr31();

#define SET_IDT_GATE(n) set_idt_gate( n , (const void*)asm_isr##n)
void interrupts_isr_install() {
	SET_IDT_GATE(0);
	SET_IDT_GATE(1);
	SET_IDT_GATE(2);
	SET_IDT_GATE(3);
	SET_IDT_GATE(4);
	SET_IDT_GATE(5);
	SET_IDT_GATE(6);
	SET_IDT_GATE(7);
	SET_IDT_GATE(8);
	SET_IDT_GATE(9);
	SET_IDT_GATE(10);
	SET_IDT_GATE(11);
	SET_IDT_GATE(12);
	SET_IDT_GATE(13);
	SET_IDT_GATE(14);
	SET_IDT_GATE(15);
	SET_IDT_GATE(16);
	SET_IDT_GATE(17);
	SET_IDT_GATE(18);
	SET_IDT_GATE(19);
	SET_IDT_GATE(20);
	SET_IDT_GATE(21);
	SET_IDT_GATE(22);
	SET_IDT_GATE(23);
	SET_IDT_GATE(24);
	SET_IDT_GATE(25);
	SET_IDT_GATE(26);
	SET_IDT_GATE(27);
	SET_IDT_GATE(28);
	SET_IDT_GATE(29);
	SET_IDT_GATE(30);
	SET_IDT_GATE(31);

    load_idt_registry(); 
}

void interrupts_install() {
	interrupts_isr_install();
	load_idt_registry();
	
}
