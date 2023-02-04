#include "types.h"
#include "console.h"

typedef struct {
    uint64_t P4table[512]; // PML4
    uint64_t P3table[512]; // Directory Pointer
    uint64_t P2table[512]; // Directory
    uint64_t P1table[512]; // Page Table
} PTables_initial_set_from_asm_loader;

//PTables * the_tables = (PTables*)0x1000;

// Page table layout
//
// 63   62-48 47-12              11-3  2  1  0
// NX         Physical address         U  W  P


/*static*/ uint64_t PML4_location;
void print_ptable_entry(uint64_t entry) {
    char nx = 0 != entry & 0x8000000000000000;
    uint32_t n6248 = (entry & 0x7FFF000000000000) >> 48;
    uint64_t phys = (entry & 0xFFFFFFFFF000) >> 12;
    char u = (entry & 0x4) >> 2;
    char w = (entry & 0x2) >> 1;
    char p = (entry & 0x1);

    console_kprint("\n ptable_entry: ");
    console_kprint(" nx:");     console_kprint_uint64(nx);
    console_kprint(" n6248:");  console_kprint_hex(n6248);
    console_kprint(" phys:");   console_kprint_hex(phys);
    console_kprint(" u:");      console_kprint_hex(u);
    console_kprint(" w:");      console_kprint_hex(w);
    console_kprint(" p:");      console_kprint_hex(p);

}

// Creates a 1-1 mapping
void pagetable_init(PTables_initial_set_from_asm_loader * the_tables){
    console_kprint("Init Pagetable");
    PML4_location = the_tables;
}

void pagetable_debug_print() {
    PTables_initial_set_from_asm_loader * the_tables = (PTables_initial_set_from_asm_loader*)PML4_location;
    print_ptable_entry(the_tables->P1table[0]);
    print_ptable_entry(the_tables->P1table[1]);
    print_ptable_entry(the_tables->P1table[2]);
    print_ptable_entry(the_tables->P1table[3]);
    print_ptable_entry(the_tables->P1table[4]);

}

void pagetable_init_OLD(PTables_initial_set_from_asm_loader * the_tables){

    for(int i = 0 ; i < 512 ; i++) {
        // Lock the pages down by making them unavaliable 
        the_tables->P4table[i]=0x0;
    }

    for(int i = 0 ; i < 512 ; i++) {
        // Lock the pages down by making them unavaliable 
        the_tables->P3table[i]=0x0; 
    }

    for(int i = 0 ; i < 512 ; i++) {
        // Lock the pages down by making them unavaliable 
        the_tables->P2table[i]=0x0; 
    }


    // Sets up the first two Meg of memory linearely
    uint64_t v1= (uint64_t)0x3 | (uint64_t)(&the_tables->P3table[0]);
    uint64_t v2= (uint64_t)0x3 | (uint64_t)(&the_tables->P2table[0]);
    uint64_t v3= (uint64_t)0x3 | (uint64_t)(&the_tables->P1table[0]);
    
    //the_tables->P4table[0] = (uint64_t)0x3 | (uint64_t)(&the_tables->P3table[0]);
    //the_tables->P3table[0] = (uint64_t)0x3 | (uint64_t)(&the_tables->P2table[0]);
    //the_tables->P2table[0] = (uint64_t)0x3 | (uint64_t)(&the_tables->P1table[0]);

    the_tables->P4table[0] = v1;
    the_tables->P3table[0] = v2;
    the_tables->P2table[0] = v3;

    uint64_t physicalAdress = 0;
    for(int i = 0 ; i < 512 ; i++ && physicalAdress < 0x200000) {
        // Lock the pages down by making them unavaliable

        // Trickery. The lower 12 bits in the adress must be
        // 0 since they are funny flags and whatnot.
        the_tables->P1table[i]= physicalAdress | 0x3; // User/Supervisor = 0, Present = 1, Writable = 1
        physicalAdress += 0x1000;
    }
}

