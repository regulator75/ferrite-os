/**
 * Memory management. like New, malloc, free etc
 */

 
void memory_copy(const char *source, char *dest, int nbytes) {
    // TODO: Add 1-byte premove, 8 byt mid-section, 1-byte postmove
    for (int i = 0; i < nbytes; i++) {
        *(dest + i) = *(source + i);
    }
}