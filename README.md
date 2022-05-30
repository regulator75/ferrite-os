# ferrite-os
This operating system intends to run the V8 scripting engine on bare metal.
Previous work, that successfully booted to 64 bit from BIOS, have been mvoed to archived_efforts, to leave room for UEFI based approach that should avoid most of the custom tooling work that was used in the first attempts.

# Usage
Clone. 
make gnu-efi (This will clone gnu-efi to the local folder structure and build it.)
make run (will compile the OS and launch qemu)

# Inspirational links
(The README under archived_efforts conatins lots of links to resources for general OS knowledge. Below is for the new effort)
https://blog.llandsmeer.com/tech/2019/07/21/uefi-x64-userland.html
https://wiki.osdev.org/UEFI_App_Bare_Bones
