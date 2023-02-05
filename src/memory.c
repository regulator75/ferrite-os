#include "console.h"
#include "types.h"
#include "memory.h"

#define PAGE_SIZE 4096
extern void *_kernel_begin, *_kernel_end; // Created in the linkmap script
/**
 * Memory management. like New, malloc, free etc
 */


/**
 *  
 * PHYSICAL MEMORY ANALYSIS
 * 
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


void memory_phys_map_init(void * src) {
	memory_copy((const char*)src, ( char*)&memory_region_map[0],sizeof(memory_region_map));
}


/** 
 * Diagnoses what memory we have and print a 
 * map to console
 */

void memory_phys_print_map() {
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


/** 
 *
 * UTILITY FUNCTIONS
 * 
*/


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


/**
 * 
 * PHYSICAL MEMORY ALLOCATION ACCOUNTING
 * 
 */

// types
typedef struct _tagMemrange{
	uint64_t physRangeStart;
	uint32_t rangeLength; // how many pages in this range.
	uint32_t in_use; /// Wow, great use of those bits. 
					 // I know we can squeeze this into physRangeStart 
					 // lower bits or something but I want to make this simple for now
	void * next_memrange;
} memrange;

// data
memrange first_memrange_map_buffer[PAGE_SIZE/sizeof(memrange)] __attribute__ ((aligned (4096)));
memrange * first_memrange_map;
int first_memrange_map_count;

// prototypes
memrange * take_memrange_for_address(uint64_t p, int length);


// code

static char is_address_within_region(memory_region_t * pregion, void * address) {
	return address > pregion->base && address < pregion->base+pregion->length_or_region;
}

void memory_phys_alloc_init(/*uses memory_region_map*/){
	int i = 0;
	int memrange_idx_it = 0;

	first_memrange_map = &first_memrange_map_buffer[0];
	first_memrange_map_count = PAGE_SIZE / sizeof(memrange);
	// TODO: See if we can get static initalizeres working so it can be
	// zeroed out for sure.
	memory_clear(first_memrange_map_buffer,sizeof(first_memrange_map_buffer));

	// First, map the entire memory, pretend its all free.
	while(memory_region_map[i].length_or_region != 0) {
		if(memory_region_map[i].type == 1) { // TYPE 1 is Usable RAM
			first_memrange_map[memrange_idx_it].physRangeStart = memory_region_map[i].base;
			first_memrange_map[memrange_idx_it].rangeLength = memory_region_map[i].length_or_region / PAGE_SIZE;
			first_memrange_map[memrange_idx_it].in_use = 0; // Free
			first_memrange_map[memrange_idx_it].next_memrange = 0; // Will be altered if we find more

			// If this is not the first range...
			if(memrange_idx_it != 0) {
				// link the previous range to this
				first_memrange_map[memrange_idx_it-1].next_memrange = &first_memrange_map[memrange_idx_it]; // Will be altered if we find more
			}
			memrange_idx_it++;
		}
		i++;
	}

	// Second, carve out the pieces that are known to be in use

	// Kernel code
	memory_phys_print_memranges();
	int length = &_kernel_end - &_kernel_begin;
	take_memrange_for_address(&_kernel_begin, length);
}

void memory_phys_collapse_memrange(memrange * prev, memrange * collapsed_and_goes_away) {
	// It turned into nothing, remove it.
	// Skip over us in the linked list.
	prev->next_memrange = collapsed_and_goes_away->next_memrange;

	// Zero out members to mark it free.
	collapsed_and_goes_away->physRangeStart = 0;
	collapsed_and_goes_away->next_memrange = 0;
	collapsed_and_goes_away->in_use = 0;
}

memrange * find_free_memrange_descriptor_mark_inuse(){
	for(int i = 0 ; i < first_memrange_map_count ; i++){
		// Dont just check the pointer, In the case of the very first range
		// for the first piece of RAM, the pointer will be 0.
		if( 0 == first_memrange_map[i].physRangeStart && 
			0 == first_memrange_map[i].rangeLength &&
			0 == first_memrange_map[i].next_memrange) {
				// mark in-use so multiple calls to this function does
				// not return the same segment
				first_memrange_map[i].physRangeStart=0xFFFFFFFFFFFFFFFF; 
			return &first_memrange_map[i];
		}
	}
	return 0;
}

// Find the memrange that maps the address given, making sure
// it also includes all of the length. 
// If no range is found, or if the length is not fully included,
// return 0;
// This function should only be used to locate memranges that need
// sections to be carved out during init, such as the space occupied
// by the kernel, GDT tables, Video memory etc.
memrange * take_memrange_for_address(uint64_t p, int length){

	memrange * it = first_memrange_map;
	memrange * it_prev = 0;
	int pages_needed = length+(PAGE_SIZE-1) / PAGE_SIZE;

	while(it) {
		uint64_t start_adress_page_aligned = (p/PAGE_SIZE) * PAGE_SIZE;
		uint64_t end_address_page_aligned = ((p+length+PAGE_SIZE-1)/PAGE_SIZE) * PAGE_SIZE;

		int starts_after = start_adress_page_aligned >= it->physRangeStart;
		int ends_before  = end_address_page_aligned  <= it->physRangeStart+it->rangeLength*PAGE_SIZE;

		console_kprint(" physStart, pageLength, start_aligned, end_aligned, starts_after, ends_before\n");
		console_kprint_hex(it->physRangeStart);
		console_kprint(", ");
		console_kprint_uint64(it->rangeLength);
		console_kprint(", ");
		console_kprint_hex(start_adress_page_aligned);
		console_kprint(", ");
		console_kprint_hex(end_address_page_aligned);
		console_kprint(", ");
		console_kprint_uint64(starts_after);
		console_kprint(", ");
		console_kprint_uint64(ends_before);
		console_kprint("\n");

		if(starts_after && ends_before) {

			// This is it.

			// There are three cases that needs to be dealt with,
			// 1) the case where p is at the very beginnig 
			// of the memrange, in which case one new descriptor is needed.
			// 2) The case where its in the middle, in which case two new 
			//    descriptors are needed (one for p and length, on for the 
			//    free space at the end)
			// 3) Rare case where p is in the middle of the range
			//    but ends at the very end.
			//

			if( p == it->physRangeStart) {
				// Insert a new memrange before. (Case 1)
				memrange * newly_minted = find_free_memrange_descriptor_mark_inuse();
				newly_minted->next_memrange = it;
				newly_minted->in_use=1;
				newly_minted->physRangeStart = it->physRangeStart;
				newly_minted->rangeLength = pages_needed;

				// Adjust the range that had the free
				it->physRangeStart += PAGE_SIZE * pages_needed;
				it->rangeLength -= pages_needed; // Give one up to newly_minted

				// insert newly_minted 
				if(it_prev) {
					it_prev->next_memrange = newly_minted;
				}

				// Check if this segment is now empty
				if(it->rangeLength == 0) {
					memory_phys_collapse_memrange(it_prev, it);
				}
			} else {
				// Insert a new memrange in the middle, (or at the tail)
				// Case 2 and 3

				memrange * newly_minted_middle = find_free_memrange_descriptor_mark_inuse();
				memrange * newly_minted_end = find_free_memrange_descriptor_mark_inuse();

				// First, set up the links, from the back
				newly_minted_end->next_memrange = it->next_memrange;
				newly_minted_middle->next_memrange = newly_minted_end;
				it->next_memrange = newly_minted_middle;


				// Now compute the new length of the segment we are chopping up
				int oldRangeLength = it->rangeLength; // Save to simplify some math below.
				it->rangeLength = (p - it->physRangeStart) / PAGE_SIZE;

				// Now we are done with "it", its legal and has the correct length and flags.
				// Move on to the middle piece.

				newly_minted_middle->in_use = 1;
				// The boundary prior to p. 
				newly_minted_middle->physRangeStart = (p/PAGE_SIZE)*PAGE_SIZE;
				newly_minted_middle->rangeLength = ((p + length - newly_minted_middle->physRangeStart)+(PAGE_SIZE-1))/PAGE_SIZE;
				newly_minted_middle->in_use = 1;

				// Finally, set up the piece _after_ the block we marked off
				// as used.
				newly_minted_end->in_use = 0;
				newly_minted_end->physRangeStart = newly_minted_middle->physRangeStart + newly_minted_middle->rangeLength*PAGE_SIZE;
				newly_minted_end->rangeLength = (oldRangeLength - newly_minted_middle->rangeLength) - it->rangeLength;
			}
			it = 0; // Breaks the loop
		} else {
			memory_phys_print_memranges();

			console_kprint("\n Moving from:");
			console_kprint_hex(it);

			it_prev = it;
			it=it->next_memrange;

			console_kprint(" to:");
			console_kprint_hex(it);
			console_kprint("\n");
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
		memrange * newly_minted = find_free_memrange_descriptor_mark_inuse();
		newly_minted->next_memrange = it;
		newly_minted->in_use=1;
		newly_minted->physRangeStart = it->physRangeStart;
		newly_minted->rangeLength = count;

		// Adjust the range that had the free
		it->physRangeStart += PAGE_SIZE * count;
		it->rangeLength -= count; // Give one up to newly_minted
		
		// insert newly_minted 
		if(it_prev)
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


void memory_phys_print_memranges(){
	int idx = 0;
	console_kprint("memory_phys_print_memranges\n");
	for( memrange * it = first_memrange_map ; it != 0 ; it = it->next_memrange ) {
		int location = (it - first_memrange_map) / sizeof(*it);
		console_kprint_uint64(idx);
		console_kprint(",");
		console_kprint_uint64(location);
		console_kprint(" a:");
		console_kprint_hex(it->physRangeStart);
		console_kprint(" length:");
		console_kprint_hex(it->rangeLength);
		console_kprint("\n");
	}
	console_kprint("\n");
}




