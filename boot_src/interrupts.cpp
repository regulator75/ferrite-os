#include "console.h"
#include "types.h"
#include "ports.h"

#include "interrupts.h"

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

/** Ferrite OS will hold the C level handlers in this array */
static irq_handler_func_t s_handlers[256];

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

void print_isr_irq_handler_parameters(isr_irq_handler_parameters * p) {
	console_kprint("ds       ");console_kprint_uint64(p->ds      );console_kprint("\n");
	console_kprint("rdi      ");console_kprint_uint64(p->rdi     );console_kprint("\n");
	console_kprint("rsi      ");console_kprint_uint64(p->rsi     );console_kprint("\n");
	console_kprint("rbp      ");console_kprint_uint64(p->rbp     );console_kprint("\n");
	console_kprint("rbx      ");console_kprint_uint64(p->rbx     );console_kprint("\n");
	console_kprint("rcx      ");console_kprint_uint64(p->rcx     );console_kprint("\n");
	console_kprint("rax      ");console_kprint_uint64(p->rax     );console_kprint("\n");
	console_kprint("int_no   ");console_kprint_uint64(p->int_no  );console_kprint("\n");
	console_kprint("code     ");console_kprint_uint64(p->code    );console_kprint("\n");
	console_kprint("eip      ");console_kprint_uint64(p->eip     );console_kprint("\n");
	console_kprint("cs       ");console_kprint_uint64(p->cs      );console_kprint("\n");
	console_kprint("eflags   ");console_kprint_uint64(p->eflags  );console_kprint("\n");
	console_kprint("useresp  ");console_kprint_uint64(p->useresp );console_kprint("\n");
	console_kprint("ss       ");console_kprint_uint64(p->ss      );console_kprint("\n");
}


void set_idt_gate(int n, const void * handler) {
    s_idt[n].low_offset = lowest_16(handler);
    s_idt[n].sel = 0x08; 
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
extern "C" void interupt_service_request_handler(isr_irq_handler_parameters r) {
    console_kprint("received interrupt: ");
    console_kprint_uint64(r.int_no);
    console_kprint("\n");
    console_kprint(interupt_service_request_handler_exception_messages[r.int_no]);
    console_kprint("\n");


    ////print_isr_irq_handler_parameters(&r);
}

extern "C" void interupt_request_line_handler(isr_irq_handler_parameters r) {

	// Clear the flag so IRQ subsystem know we are ready 
	// to recieve another
    if (r.int_no >= 40) {
    	port_byte_out(0xA0, 0x20);  // follower 
    }
    port_byte_out(0x20, 0x20); // leader

    /* Handle the interrupt in a more modular way */
    /*if (interrupt_handlers[r.int_no] != 0) {
        isr_t handler = interrupt_handlers[r.int_no];
        handler(r);
    }*/
    console_kprint("received IRQ: ");
    console_kprint_uint64(r.code);
    console_kprint("\n");
    if(r.code == 1) {
	    int keycode = port_byte_in(0x60);

	    console_kprint("(Keyboard) Scancode : ");
	    console_kprint_uint64(keycode);
	    console_kprint("\n");
    }
    ////print_isr_irq_handler_parameters(&r);

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

extern "C" void asm_irq0();
extern "C" void asm_irq1();
extern "C" void asm_irq2();
extern "C" void asm_irq3();
extern "C" void asm_irq4();
extern "C" void asm_irq5();
extern "C" void asm_irq6();
extern "C" void asm_irq7();
extern "C" void asm_irq8();
extern "C" void asm_irq9();
extern "C" void asm_irq10();
extern "C" void asm_irq11();
extern "C" void asm_irq12();
extern "C" void asm_irq13();
extern "C" void asm_irq14();
extern "C" void asm_irq15();

#define SET_IDT_GATE_ISR(n) set_idt_gate( n , (const void*)asm_isr##n)
#define SET_IDT_GATE_IRQ(n) set_idt_gate( (32+n) , (const void*)asm_irq##n)

void interrupts_isr_install() {
	SET_IDT_GATE_ISR(0);
	SET_IDT_GATE_ISR(1);
	SET_IDT_GATE_ISR(2);
	SET_IDT_GATE_ISR(3);
	SET_IDT_GATE_ISR(4);
	SET_IDT_GATE_ISR(5);
	SET_IDT_GATE_ISR(6);
	SET_IDT_GATE_ISR(7);
	SET_IDT_GATE_ISR(8);
	SET_IDT_GATE_ISR(9);
	SET_IDT_GATE_ISR(10);
	SET_IDT_GATE_ISR(11);
	SET_IDT_GATE_ISR(12);
	SET_IDT_GATE_ISR(13);
	SET_IDT_GATE_ISR(14);
	SET_IDT_GATE_ISR(15);
	SET_IDT_GATE_ISR(16);
	SET_IDT_GATE_ISR(17);
	SET_IDT_GATE_ISR(18);
	SET_IDT_GATE_ISR(19);
	SET_IDT_GATE_ISR(20);
	SET_IDT_GATE_ISR(21);
	SET_IDT_GATE_ISR(22);
	SET_IDT_GATE_ISR(23);
	SET_IDT_GATE_ISR(24);
	SET_IDT_GATE_ISR(25);
	SET_IDT_GATE_ISR(26);
	SET_IDT_GATE_ISR(27);
	SET_IDT_GATE_ISR(28);
	SET_IDT_GATE_ISR(29);
	SET_IDT_GATE_ISR(30);
	SET_IDT_GATE_ISR(31);

    // Remap the PIC
    port_byte_out(0x20, 0x11); // restart PIC1
    port_byte_out(0xA0, 0x11); // restart PIC2
    port_byte_out(0x21, 0x20); // PIC1 now starts at 32
    port_byte_out(0xA1, 0x28); // PIC2 now starts at 40
    port_byte_out(0x21, 0x04); // setup cascading
    port_byte_out(0xA1, 0x02); // setup cascading
    port_byte_out(0x21, 0x01); // environment
    port_byte_out(0xA1, 0x01); // environment
    port_byte_out(0x21, 0x01); // mask
    port_byte_out(0xA1, 0x01); // mask

    // Install the IRQs
	SET_IDT_GATE_IRQ(0);
	SET_IDT_GATE_IRQ(1);
	SET_IDT_GATE_IRQ(2);
	SET_IDT_GATE_IRQ(3);
	SET_IDT_GATE_IRQ(4);
	SET_IDT_GATE_IRQ(5);
	SET_IDT_GATE_IRQ(6);
	SET_IDT_GATE_IRQ(7);
	SET_IDT_GATE_IRQ(8);
	SET_IDT_GATE_IRQ(9);
	SET_IDT_GATE_IRQ(10);
	SET_IDT_GATE_IRQ(11);
	SET_IDT_GATE_IRQ(12);
	SET_IDT_GATE_IRQ(13);
	SET_IDT_GATE_IRQ(14);
	SET_IDT_GATE_IRQ(15);


    load_idt_registry(); 
}

void interrupts_install() {
	// Clean out array that will hold all handlers.
	for(int i = 0 ; i < sizeof(s_handlers)/sizeof(s_handlers[0]) ; i++)
		s_handlers[i] = 0;

	interrupts_isr_install();
	load_idt_registry();

    /* Get current master PIC interrupt mask */
    unsigned char curmask_master = port_byte_in (0x21);

    ///* 0xFD is 11111101 - enables only IRQ1 (keyboard) on master pic
    //   by clearing bit 1. bit is clear for enabled and bit is set for disabled */
    //port_byte_out(0x21, curmask_master & 0xFD);

	asm volatile("sti");
}

void register_irq_handler(int id, irq_handler_func_t h) {
	if(id < sizeof(s_handlers)/sizeof(s_handlers[0])){
		s_handlers[id] = h;
	} else {
		// Error
	}

}
