#include "console.h"
#include "types.h"
#include "memory.h"
/**
 * Memory management. like New, malloc, free etc
 */


typedef struct memory_region{
	uint64_t base;
	uint64_t length_or_region;
	
	// Type 1: Usable (normal) RAM
	// Type 2: Reserved - unusable
	// Type 3: ACPI reclaimable memory
	// Type 4: ACPI NVS memory
	// Type 5: Area containing bad memory
	uint32_t type; 
	uint32_t acpi_extended_attributes; // commonly unused
} __attribute((packed)) memory_region_t;


// This data-structure is filled out by the kernel before it leaves 32 bit mode, because
// at that point INT 15 becomes unavaliable.

/* In reality, this function returns an unsorted list that may contain unused 
entries and (in rare/dodgy cases) may return overlapping areas. Each list entry 
is stored in memory at ES:DI, and DI is not incremented for you. The format 
of an entry is 2 uint64_t's and a uint32_t in the 20 byte version, plus one 
additional uint32_t in the 24 byte ACPI 3.0 version (but nobody has ever seen 
a 24 byte one). It is probably best to always store the list entries as 24 byte 
quantities -- to preserve uint64_t alignments, if nothing else. (Make sure to 
set that last uint64_t to 1 before each call, to make your map compatible with ACPI).
*/
uint32_t loaded_entries;
memory_region_t memory_region_map[256];



/** 
 * Diagnoses what memory we have and print a 
 * map to console
 */
 
void memory_analyze_and_print() {

	memory_copy((const char*)0x5000, ( char*)&memory_region_map[0],sizeof(memory_region_map));
	console_kprint("\nMemory map: ");
	console_kprint_uint64(loaded_entries);
	console_kprint("\n");


// index by type-1
	const char* types[] = {
			"Usable (normal) RAM",
			"Reserved - unusable",
			"ACPI reclaimable memory",
			"ACPI NVS memory",
			"Area containing bad memory"};

	int i = 0 ;
	console_kprint("index\tbase\tlength_or_region\ttype\n");
	while(memory_region_map[i].length_or_region != 0) {
	//for(int i = 0 ; i < 5 ; i++) {
		console_kprint_uint64(i);
		console_kprint("\t");
		console_kprint_hex((int64_t)memory_region_map[i].base);
		console_kprint("     \t");
		console_kprint_hex((int64_t)memory_region_map[i].length_or_region);
		console_kprint("   \t");
		console_kprint(types[memory_region_map[i].type-1]);
		console_kprint("\n");
		i++;
	}
}

void memory_copy(const char *source, char *dest, int nbytes) {
    // TODO: Add 1-byte premove, 8 byt mid-section, 1-byte postmove
    for (int i = 0; i < nbytes; i++) {
        *(dest + i) = *(source + i);
    }
}

void memory_clear( char * target, uint64_t size) {
	if((uint64_t)target%8 || size%8) {
		// slow
		for(uint64_t i = 0 ; i < size ; i++) {
			target[i]=0;
		}
	} else {
		//fast
		uint64_t size8 = size/8;
		uint64_t * target8 = (uint64_t*)target;
		for(uint64_t i = 0 ; i < size8 ; i++) {
			target8[i]=0;
		}
	}
}





