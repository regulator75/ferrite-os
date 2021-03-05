# ferrite-os
This operating system intends to run the V8 scripting engine on bare metal.

This is totally a research project at this stage, still focusing on getting a C++17 toolchain working for bare metal targets.

This project contains a total of three different attempts
 - GCC using regular BIOS boot, including a C++ cross compiler (furthest along)
 - LLVM using regular BIOS boot, I could not get the C++ libraries cross compiiled
 - GCC using UEFI boot, the newest attempt and is just in its infancy.


## BIOS booting

Inspiration for OS bringup taken from https://github.com/cfenollosa/os-tutorial




### Plan
- Create boot-sector and kernel that takes computer to 64 bit mode [DONE]
- Get basic console output working [DONE]
- Get basic input working [Not done. Keyboard interrupts are caught and show but not properly implemented. Also no shell to send to so pointless]
- Get Memory layout for PC [Done]
- Implement Malloc [Done-ish]
- Implement C++ test program to make sure "LIBC"-equivalents are there
- Get V8 building with custom toolchain with no libc to identify missing symbols for memory allocation etc
- Real work begins. 

### Running
1. Run qemu-system-x86_64 -hda os.bin 
2. Play with -m MEMORY to increase/decrease size of memory


### Usefull links
https://gitlab.com/noencoding/OS-X-Chromium-with-proprietary-codecs/wikis/List-of-all-gn-arguments-for-Chromium-build

https://blog.scaleprocess.net/building-v8-on-arch-linux/
	
https://libcxx.llvm.org/docs/UsingLibcxx.html

Interrupts in 64 bit mode
https://0xax.gitbooks.io/linux-insides/content/Interrupts/linux-interrupts-1.html

http://www.uruk.org/orig-grub/mem64mb.html
https://en.wikibooks.org/wiki/X86_Assembly/Programmable_Interrupt_Controller
https://github.com/pdoane/osdev/blob/master/boot/loader.asm
https://docs.microsoft.com/en-us/cpp/build/x64-calling-convention?view=vs-2019
https://stackoverflow.com/questions/3381755/porting-newlib-crt0

https://www.embecosm.com/appnotes/ean9/ean9-howto-newlib-1.0.html [porting newlib]


## Tools (GCC)

### Building the tools on macOS

Just dont. Several self-checks in the tool chains seems to assume you are building for native. If you have luck let me know.

### Building the tools on Ubuntu

All tool downloads and building is in the make file.
One by one make each -done target
 
Binutils is currently at 2.33 and needs upgrde

If building gcc fails try  
cd gcc-10.2.0 ; ./contrib/download_prerequisites
The console output is not great, it may look like it failed to download, check manually.

If you have problems with building GCC, make sure you have python installed. 
sudo apt-get install python3-dev 
sudo apt install python3.8-distutils (match 3.8 to your /usr/bin/python3 version)

Needed clean build and install: sudo apt-get install texinfo



### CRT0.o
Currently does not initialize .bss etc properly. (no call to init)

x86_64-elf-as crt0.s -o crt0.o
sudo cp crt0.o /usr/local/x86_64-elf/x86_64-elf/lib/.


### C++
I had hell making the standard C++ library cross compile. I am sure its supported for those who know, but I had to jump through
various hoops to get it working. The Makefile has the sequence down, including installing newlib. 


### UNWIND
Unwind is needed to handle exceptions properly. The Unwind to use is from LLVM since it supports cross compilation easily, and works. 



## UEFI

https://wiki.osdev.org/UEFI
Latest effort is to build UEFI image instead. This has just started

apt install ovfm
qemu-system-x86_64 -cpu qemu64 -bios /usr/share/ovmf/OVMF.fd -drive file=os.img,if=ide -net none

### GNU-EFI
There is quirk with the configuration that makes it bail if the compiler throws a warning. Unfortunately newer compilers
will not agree with some of the code, so the process includes applying a patch that removes -Werror