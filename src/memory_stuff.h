#define UEFI_MMAP_SIZE 0x4000
typedef struct _taguefi_mmap {
    uint64_t nbytes;
    uint8_t buffer[UEFI_MMAP_SIZE];
    uint64_t mapkey;
    uint64_t desc_size;
    uint32_t desc_version;
} uefi_mmap_type;


void print_memory_map();