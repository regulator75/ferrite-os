#include <efi.h>
#include <efilib.h>

#include "memory_stuff.h"



static void print_chunk(int index, EFI_MEMORY_DESCRIPTOR * desc) {
    Print(L"[%3ld] Type: %8lx, NumberOfPages:   %8ld, physical location: %8lx\r\n"
        , index, desc->Type, desc->NumberOfPages, desc->PhysicalStart ); 
}



void print_memory_map() {
    uefi_mmap_type uefi_mmap; 

    Print(L"--- Memory Map ---\r\n" );

    uefi_mmap.nbytes = UEFI_MMAP_SIZE;
    uefi_call_wrapper(ST->BootServices->GetMemoryMap, 5,
            &uefi_mmap.nbytes,
            uefi_mmap.buffer,
            &uefi_mmap.mapkey,
            &uefi_mmap.desc_size,
            &uefi_mmap.desc_version);
    /* find largest continuous chunk of EfiConventionalMemory */
    Print(L"nbytes: %lx, mapkey: %lx, desc_size: %lx, desc_version: %lx\r\n\r\n",
        uefi_mmap.nbytes,uefi_mmap.mapkey,uefi_mmap.desc_size,uefi_mmap.desc_version);
    uint64_t best_alloc_start = 0;
    uint64_t best_number_of_pages = 0;
    int index = 0;
    for (int i = 0; i < uefi_mmap.nbytes; i += uefi_mmap.desc_size) {
        EFI_MEMORY_DESCRIPTOR * desc = (EFI_MEMORY_DESCRIPTOR*)&uefi_mmap.buffer[i];
        if (desc->Type != EfiConventionalMemory) {
            //print unusable memory

            //Print(L"Useless ->" );
            //print_chunk(desc);
        } else{
            // print usable memory
            print_chunk(index, desc);
            // Check if this is the largest space.
            if (desc->NumberOfPages > best_number_of_pages) {
                best_number_of_pages = desc->NumberOfPages;
                best_alloc_start = desc->PhysicalStart;
            }
        }
        index++; // for pretty printing only
        
    }
    Print(L"--- Done ---\r\n" );

    //next_alloc_page = best_alloc_start;
    /* call ExitBootServices(ImageHandle, mapkey) */
}
