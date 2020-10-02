#include "types.h"
typedef struct {
   uint64_t ds; /* Data segment selector */
   uint64_t rdi, rsi, rbp, rsp, rbx, rdx, rcx, rax; // pushaq
   uint64_t int_no, err_code; /* Interrupt number and error code (if applicable) */
   uint64_t eip, cs, eflags, useresp, ss; /* Pushed by the processor automatically */
} isr_irq_handler_parameters;

typedef void (*irq_handler_func_t)(isr_irq_handler_parameters);

void interrupts_install();
void register_irq_handler(irq_handler_func_t h);
