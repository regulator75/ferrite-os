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
https://stackoverflow.com/questions/3381755/porting-newlib-crt0

https://www.embecosm.com/appnotes/ean9/ean9-howto-newlib-1.0.html [porting newlib]


## Building the tools on macOS

1. Download and build GCC
2. Download and build binutils
3. Download and build newlib
4. Re-build GCC
5. compile crt0.s, place O file in 
6. Test-compile a plain C program
7. Download and configure stdlibc++v3




- Build a native to native GCC so you are not stuck with the xcode toolchain.
- Download GCC
- enter GCC folder
- Run sh ./contrib/download_prerequisites. Ignore the warnings if you get them about host. you can make sure the files are there by ls *.bz2, and you will see 3 files.
- cd..
- Create and enter build folder
- ../gcc-10.2.0/configure --prefix=/usr/local/gcc-10.2.0/bin --enable-languages=c,c++ --disable-multilib --with-sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
- make -j 8



- Set the path so that these tools are picked up instead.

- export PATH=/usr/local/macos-gcc/bin:$PATH

- Go to a tmp folder
- curl -O https://ftp.gnu.org/gnu/binutils/binutils-2.33.1.tar.gz
- tar xf binutils-2.33.1.tar.gz 
- mkdir binutils-build
- cd binutils-build
- ../binutils-2.33.1/configure --target=x86_64-elf  --enable-interwork --disable-multilib --disable-nls --disable-werror --prefix=/usr/local/x86_64-elf
- make all
- sudo make install


- curl -O https://ftp.gnu.org/gnu/gcc/gcc-9.2.0/gcc-9.2.0.tar.gz
- tar xf gcc-9.2.0.tar.gz
- mkdir gcc-build
- cd gcc-build
- ../gcc-9.2.0/configure --target=x86_64-elf --prefix="/usr/local/x86_64-elf" --disable-nls --disable-libssp --enable-languages=c,c++ --disable-multilib --enable-newlib
- make all-gcc 
- make all-target-libgcc 
- make install-gcc  (May need sudo)
- make install-target-libgcc (May need sudo)


#ADDING THIS TO .profile
# For building Ferrite
# Add path to build tools and binaries
PATH="/usr/local/x86_64-elf/bin:$PATH"



curl -O ftp://sourceware.org/pub/newlib/newlib-3.3.0.tar.gz
../newlib-3.3.0/configure --target=x86_64-elf --prefix=/usr/local/x86_64-elf \
CC_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-gcc \
CXX_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-g++ \
LD_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-ld \
AS_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-as \
NM_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-nm \
AR_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-ar \
RANLIB_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-ranlib \
OBJDUMP_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-objdump

make all
sudo make install



Note on CRT0.o

x86_64-elf-as crt0.s -o crt0.o
sudo cp crt0.o /usr/local/x86_64-elf/x86_64-elf/lib/.

x86_64-myos-ar rcs libc.a strfoo.o x86_64/crt0.o

../gcc-10.2.0/libstdc++-v3/configure --target=x86_64-elf --prefix="/usr/local/x86_64-elf" --disable-nls --disable-libssp --enable-languages=c,c++ --with-newlib=/usr/local/x86_64-elf/x86_64-elf/ --disable-libstdcxx-threads --disable-multilib --disable-hosted-libstdcxx \
CC_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-gcc \
CXX_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-g++ \
LD_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-ld \
AS_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-as \
NM_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-nm \
AR_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-ar \
RANLIB_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-ranlib \
OBJDUMP_FOR_TARGET=/usr/local/x86_64-elf/bin/x86_64-elf-objdump

make all-target-libstdc++-v3


Add /usr/local/x86_64-elf/x86_64-elf/lib/libc.a to the LD line to get newlibs functions included.


CC=/usr/local/x86_64-elf/bin/x86_64-elf-gcc \
CXX=/usr/local/x86_64-elf/bin/x86_64-elf-g++ \
LD=/usr/local/x86_64-elf/bin/x86_64-elf-ld \
AS=/usr/local/x86_64-elf/bin/x86_64-elf-as \
NM=/usr/local/x86_64-elf/bin/x86_64-elf-nm \
AR=/usr/local/x86_64-elf/bin/x86_64-elf-ar \
RANLIB=/usr/local/x86_64-elf/bin/x86_64-elf-ranlib \
OBJDUMP=/usr/local/x86_64-elf/bin/x86_64-elf-objdump

