#include "console.h"
#include "types.h"
#include "memory.h"

#define PAGE_SIZE 4096
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

typedef struct _tagMemrange{
	void * physRangeStart;
	uint32_t rangeLength; // how many pages in this range.
	uint32_t in_use; /// Wow, great use of those bits. 
					 // I know we can squeeze this into physRangeStart 
					 // lower bits or something but I want to make this simple for now
	void * next_memrange;
} memrange;

static memrange * first_memrange_map;
static int first_memrange_map_count;

static char is_address_within_region(memory_region_t * pregion, void * address) {
	return address > pregion->base && address < pregion->base+pregion->length_or_region;
}

void memory_phys_alloc_init(/*uses memory_region_map*/){
	int first_found= 0;
	int i = 0;
	int memrange_idx_it;
	while(memory_region_map[i].length_or_region != 0) {
		char dont_use_this = is_address_within_region(&memory_region_map[i],(void*)memory_phys_alloc_init);
		if(memory_region_map[i].type == 1) { // TYPE 1 is Usable RAM
			if(!first_found){
				first_found = 1;
				// Rudly grab the first know usable memory for our own needs.
				first_memrange_map = memory_region_map[i].base;
				first_memrange_map_count = PAGE_SIZE / sizeof(memrange);

				// Initialize the structure. Bootstrap it with 
				// the page we stole for ourself.
				first_memrange_map[0].physRangeStart = memory_region_map[i].base;
				first_memrange_map[0].rangeLength = 1;
				first_memrange_map[0].in_use = 1;
				first_memrange_map[0].next_memrange = &first_memrange_map[1];

				first_memrange_map[1].physRangeStart = memory_region_map[i].base + PAGE_SIZE;
				first_memrange_map[1].rangeLength = memory_region_map[i].length_or_region / PAGE_SIZE - PAGE_SIZE; //- PAGE_SIZE since we stole one for ourselves
				first_memrange_map[1].in_use = 0; // Free
				first_memrange_map[1].next_memrange = 0; // Will be altered if we find more

				memrange_idx_it = 2;
			} else {
				first_memrange_map[memrange_idx_it].physRangeStart = memory_region_map[i].base;
				first_memrange_map[memrange_idx_it].rangeLength = memory_region_map[i].length_or_region / PAGE_SIZE;
				first_memrange_map[memrange_idx_it].in_use = 0; // Free
				first_memrange_map[memrange_idx_it].next_memrange = 0; // Will be altered if we find more

				first_memrange_map[memrange_idx_it-1].next_memrange = &first_memrange_map[memrange_idx_it]; // Will be altered if we find more
				memrange_idx_it++;
			}
		}
		i++;
	}

	// Clean up the rest of the descriptors.
	while(memrange_idx_it < first_memrange_map_count){
		first_memrange_map[memrange_idx_it].physRangeStart = 0;
		first_memrange_map[memrange_idx_it].rangeLength    = 0;
		first_memrange_map[memrange_idx_it].in_use         = 0; 
		first_memrange_map[memrange_idx_it].next_memrange  = 0; 
	}
}

void memory_phys_collapse_memrange(memrange * prev, memrange * curr) {
	// It turned into nothing, remove it.
	prev->next_memrange = curr->next_memrange;
	curr->physRangeStart = 0;
	curr->next_memrange = 0;
	curr->in_use = 0;
}

memrange * find_free_memrange_descriptor(){
	for(int i = 0 ; i < first_memrange_map_count ; i++){
		if(0 == first_memrange_map[i].physRangeStart) {
			return &first_memrange_map[i];
		}
	}
	return 0;
}

// Allocates a physical page
void * memory_phys_alloc_page(int count) {

	void * toReturn = 0;
	// Look first free range
	memrange * it = first_memrange_map;
	memrange * it_prev = 0;
	while(it && it->in_use !=0 && it->rangeLength < count) {
		it_prev = it;
		it=it->next_memrange;
	}
	// TODO: Add end marker and indicator that the memrange map spans over to another page
	// TODO: bail if it is null, we are out of memory
	if(!it) {
		console_kprint("No free page found in memory_phys_alloc_page\n");
		return 0;
	}

	// Now we have found a free page. 
	// We will take the first page of this.
	toReturn = it->physRangeStart;


	// Adjust the bookkeeping

	//Lets see if the previous range
	// is aligned neatly with this, if so just adjust the boundary.
	if(it_prev->physRangeStart + it_prev->rangeLength*PAGE_SIZE*count == it->physRangeStart) {
		// Expand previous into this
		it_prev->rangeLength += count;
		it->physRangeStart += PAGE_SIZE*count;
		it->rangeLength -= count;

		// Check if this range collapsed totally
		if(it->rangeLength == 0) {
			memory_phys_collapse_memrange(it_prev, it);
		}
	} else {
		// There is some gap, lets create a new memrange.
		// This is only the case when allocations happens
		// on a completely new memory sector.
		
		// Prepare the new range descriptor
		memrange * newly_minted = find_free_memrange_descriptor();
		newly_minted->next_memrange = it;
		newly_minted->in_use=1;
		newly_minted->physRangeStart = it->physRangeStart;
		newly_minted->rangeLength = count;

		// Adjust the range that had the free
		it->physRangeStart += PAGE_SIZE * count;
		it->rangeLength -= count; // Give one up to newly_minted
		
		// insert newly_minted 
		it_prev->next_memrange = newly_minted;

		// Check if this segment is now empty
		if(it->rangeLength == 0) {
			memory_phys_collapse_memrange(it_prev, it);
		}
	}
}

void memory_phys_alloc_free(void * p) {
	// TODO

}





