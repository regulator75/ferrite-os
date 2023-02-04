#ifndef MEMORY_MGNT_H
#define MEMORY_MGNT_H

void memory_phys_map_init();
void memory_print_memory_map();
void memory_copy(const char *source, char *dest, int nbytes);
void memory_clear( char * target, uint64_t size);

//unsigned char * memory_first_usable_memory();

#endif