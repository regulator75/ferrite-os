# ferrite-os
This operating system intends to run the V8 scripting engine on bare metal

Inspiration for OS bringup taken from https://github.com/cfenollosa/os-tutorial

## Plan
- Create boot-sector and kernel that takes computer to 64 bit mode [DONE]
- Get basic console output working [DONE]
- Get basic input working [Not done. Keyboard interrupts are caught and show but not properly implemented. Also no shell to send to so pointless]
- Get Memory layout for PC [Done]
- Implement Malloc
- Implement C++ test program to make sure "LIBC"-equivalents are there
- Get V8 building with custom toolchain with no libc to identify missing symbols for memory allocation etc
- Real work begins. 

## Running
1. Run qemu-system-x86_64 -fda obj/os.bin   (The -fda trick is apparantly a workaround as hightlighted in https://github.com/cfenollosa/os-tutorial/tree/master/07-bootsector-disk)
2. Play with -m MEMORY to increase/decrease size of memory

## Method for building V8 [Not tried yet]
- This is TBD. Plan is to NOT fork V8 but rather pull a known copy, and then auto generate build scripts from that. 

## Usefull links
https://gitlab.com/noencoding/OS-X-Chromium-with-proprietary-codecs/wikis/List-of-all-gn-arguments-for-Chromium-build

https://blog.scaleprocess.net/building-v8-on-arch-linux/

https://libcxx.llvm.org/docs/UsingLibcxx.html

Interrupts in 64 bit mode
https://0xax.gitbooks.io/linux-insides/content/Interrupts/linux-interrupts-1.html

http://www.uruk.org/orig-grub/mem64mb.html
https://en.wikibooks.org/wiki/X86_Assembly/Programmable_Interrupt_Controller
https://github.com/pdoane/osdev/blob/master/boot/loader.asm
https://docs.microsoft.com/en-us/cpp/build/x64-calling-convention?view=vs-2019

## Building the tools on macOS

- Go to a tmp folder
- curl -O https://ftp.gnu.org/gnu/gcc/gcc-9.2.0/gcc-9.2.0.tar.gz
- tar xf gcc-9.2.0.tar.gz
- mkdir gcc-build
- cd gcc-build
- ../gcc-9.2.0/configure --target=x86_64-elf --prefix="/usr/local/x86_64elfgcc" --disable-nls --disable-libssp --enable-languages=c,c++ --without-headers
- make all-gcc 
- make all-target-libgcc 
- make install-gcc 
- make install-target-libgcc


- curl -O https://ftp.gnu.org/gnu/binutils/binutils-2.33.1.tar.gz
- tar xf binutils-2.33.1.tar.gz 
- mkdir binutils-build
- cd binutils-build
- ../binutils-2.33.1/configure --target=x86_64-elf  --enable-interwork --enable-multilib --disable-nls --disable-werror --prefix=/usr/local/x86_64elfgcc 2>&1 | tee configure.log
- make all install 2>&1 | tee make.log

