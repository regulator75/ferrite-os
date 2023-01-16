#include <efi.h>
#include <efilib.h>
#include "gdt_stuff.h"

#pragma pack (1)

struct gdt_entry {
  uint16_t limit15_0;            uint16_t base15_0;
  uint8_t  base23_16;            uint8_t  type;
  uint8_t  limit19_16_and_flags; uint8_t  base31_24;
};

struct tss {
    uint32_t reserved0; 
    uint64_t rsp0, rsp1, rsp2;
    uint64_t reserved1; 
    uint64_t ist1,ist2,ist3,ist4,ist5,ist6,ist7;
    uint64_t reserved2; 
    uint16_t reserved3; 
    uint16_t iopb_offset;
} tss;

__attribute__((aligned(4096)))
struct {
  struct gdt_entry null;
  struct gdt_entry kernel_code;
  struct gdt_entry kernel_data;
  struct gdt_entry null2;
  struct gdt_entry user_data;
  struct gdt_entry user_code;
  struct gdt_entry ovmf_data;
  struct gdt_entry ovmf_code;
  struct gdt_entry tss_low;
  struct gdt_entry tss_high;
  //"In 64-bit mode, the Base and Limit values are ignored, 
  // each descriptor covers the entire linear address space 
  // regardless of what they are set to." - https://wiki.osdev.org/Global_Descriptor_Table
} gdt_table = {
    //        type  //lim&flag
    {0, 0, 0, 0x00, 0x00     , 0},  /* 0x00 null  */
    {0, 0, 0, 0x9a, 0xa0     , 0},  /* 0x08 kernel code (kernel base selector) */
    {0, 0, 0, 0x92, 0xC0     , 0},  /* 0x10 kernel data */
    {0, 0, 0, 0x00, 0x00     , 0},  /* 0x18 null (user base selector) */
    {0, 0, 0, 0xF2, 0xC0     , 0},  /* 0x20 user data */
    {0, 0, 0, 0xFa, 0xa0     , 0},  /* 0x28 user code */
    {0, 0, 0, 0xF2, 0xa0     , 0},  /* 0x30 ovmf data */
    {0, 0, 0, 0xFa, 0xC0     , 0},  /* 0x38 ovmf code */
    {0, 0, 0, 0x89, 0xa0     , 0},  /* 0x40 tss low */
    {0, 0, 0, 0x00, 0x00     , 0},  /* 0x48 tss high */
};

struct table_ptr {
    uint16_t limit;
    uint64_t base;
};

#pragma pack ()

extern /* defined in assembly */
void gdt_load(struct table_ptr * gdt_ptr);

static void * memzero(void * s, uint64_t n) {
    for (int i = 0; i < n; i++) ((uint8_t*)s)[i] = 0;
}

void gdt_setup() {
    memzero((void*)&tss, sizeof(tss));
    uint64_t tss_base = ((uint64_t)&tss);
    gdt_table.tss_low.base15_0 = tss_base & 0xffff;
    gdt_table.tss_low.base23_16 = (tss_base >> 16) & 0xff;
    gdt_table.tss_low.base31_24 = (tss_base >> 24) & 0xff;
    gdt_table.tss_low.limit15_0 = sizeof(tss);
    gdt_table.tss_high.limit15_0 = (tss_base >> 32) & 0xffff;
    gdt_table.tss_high.base15_0 = (tss_base >> 48) & 0xffff;

    struct table_ptr gdt_ptr = { sizeof(gdt_table)-1, (UINT64)&gdt_table };
    load_gdt(&gdt_ptr);
}