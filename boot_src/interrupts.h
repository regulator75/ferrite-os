#include "types.h"
typedef struct {
   uint64_t ds; /* Data segment selector */
   uint64_t rdi, rsi, rbp, rbx, rdx, rcx, rax; // pushaq
   uint64_t int_no; // Interrupt gate. 0-31 are the common projected interrupts. 32-48 are IRQ 0-15
   uint64_t code; /* In case of an interrupt, possibly an error code. In case of IRQ, the IRQ number*/
   uint64_t eip, cs, eflags, useresp, ss; /* Pushed by the processor automatically */
} isr_irq_handler_parameters;

typedef void (*irq_handler_func_t)(isr_irq_handler_parameters);

void interrupts_install();
void register_irq_handler(irq_handler_func_t h);
