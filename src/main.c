#include <efi.h>
#include <efilib.h>
#include "memory_stuff.h"


EFI_STATUS efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
    InitializeLib(ImageHandle, SystemTable);
    EFI_STATUS Status;
    EFI_INPUT_KEY Key;
 
    /* Store the system table for future use in other functions */
    ST = SystemTable;
 
    /* Say hi */
    Print(L"Hello World 2!\r\n"); // EFI Applications use Unicode and CRLF, a la Windows
    print_memory_map();
 
    /* Now wait for a keystroke before continuing, otherwise your
       message will flash off the screen before you see it.
 
       First, we need to empty the console input buffer to flush
       out any keystrokes entered before this point */
    Status = uefi_call_wrapper(ST->ConIn->Reset,2,ST->ConIn, FALSE);
    if (EFI_ERROR(Status))
        return Status;
 
    /* Now wait until a key becomes available.  This is a simple
       polling implementation.  You could try and use the WaitForKey
       event instead if you like */
    while ((Status = uefi_call_wrapper(ST->ConIn->ReadKeyStroke,2,ST->ConIn, &Key)) == EFI_NOT_READY) ;
 
    return Status;
}