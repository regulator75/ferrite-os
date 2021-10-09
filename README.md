# ferrite-os
This operating system intends to run the V8 scripting engine on bare metal.

This is totally a research project at this stage, still focusing on getting a C++17 
toolchain working that can compile the V8 engine against bare metal targets.

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
- Implement Malloc [Done-ish. Hooks to allow Newlib to operate in place. Tested and works]
- Implement C test program to make sure "LIBC"-equivalents are there [Done]
- Implement C++ test program to make sure "libstdc++"-equivalents are there
- Get V8 building with custom toolchain with no libc to identify missing symbols for memory allocation etc
- Real work begins. 

### Building

## Downloading and patching the tools
Tools are built and created in the subfolder toolbuild. The Makefile in there downloads
the correct versions and patches them to support "ferrite" as a target. If you want to build
the tools one by one for easier debugging, there are shorthands for the following neccesary
tools: ```binutils gcc1 gcc2 gdb newlib libunwind libstdcpp gnu-efi```, meaning you can do 
```make binutils``` and it will download, unpack, patch and compile binutils to the right version

To download and install all tools:

```
$ cd toolbuild
$ make all
```

The Makefile will ask for your password as it installs the tools using sudo.

If building gcc fails try  
```
cd gcc-10.2.0 ; ./contrib/download_prerequisites
```
and re-try. The console output is not great, it may look like it failed to download
even if it succedded, check manually or just try to build again.

If you have problems with building GCC, make sure you have python installed. Check what
3.x version of python you have in your ```/usr/bin/python3``` and use the matching version in this command
```
sudo apt-get install python3-dev 
sudo apt install python3.8-distutils 
```
Needed clean build and install: ```sudo apt-get install texinfo```


## Compiling ferrite OS 
```
$ make os.bin
```

## Bugfixing the toolchain
If there is a bug in the toolchain, the Makefile in toolbuild/ supports a "gcc-dev-make-patches" target
that can be used to re-generate the patches. 

### Building the tools on macOS
Just dont. Several self-checks in the tool chains seems to assume you are building for host OS. If you have luck let me know.

### Running
The makefile supports launching and/or debugging through the use of `make run` or `make debug`, 
but if you want to control parameters yourself, this is how you launch it from the command line:

```
$ qemu-system-x86_64 -hda os.bin 
```

You can play with -m MEMORY to increase/decrease size of RAM emulated.


### Implementation notes

## CRT0.o
Currently does not initialize .bss etc properly. (no call to init)

```
x86_64-elf-as crt0.s -o crt0.o
sudo cp crt0.o /usr/local/x86_64-elf/x86_64-elf/lib/.
```

## C++
I had hell making the standard C++ library cross compile. I am sure its supported for those who know, but I had to jump through
various hoops to get it working. The Makefile has the sequence down, including installing newlib. 

## libstdc++
If threads are enabled, it access GNU thread-library internals. This is bad since I will not be using GNU threads

## UNWIND
Unwind is needed to handle exceptions properly. The Unwind to use is from LLVM since it supports cross compilation easily, and works. 

## UEFI
https://wiki.osdev.org/UEFI
Latest effort is to build UEFI image instead. This has just started
```
apt install ovfm
qemu-system-x86_64 -cpu qemu64 -bios /usr/share/ovmf/OVMF.fd -drive file=os.img,if=ide -net none
```

### GNU-EFI
There is quirk with the configuration that makes it bail if the compiler throws a warning. Unfortunately newer compilers
will not agree with some of the code, so the Make process includes applying a patch that removes -Werror



### Next things todo
- Install timer hook somehow.
- Learn how to switch between modes
- Learn about how manage memory tables for different processes. 


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

https://wiki.osdev.org/OS_Specific_Toolchain
https://www.hpl.hp.com/hosted/linux/mail-archives/libunwind/2004-September/000440.html


Porting newlib
https://wiki.osdev.org/Porting_Newlib



### Random notes
make GCC_SRC_LOCATION=~/projects/gcc-ferrite/ NEWLIB_SRC_LOCATION=~/projects/gcc-ferrite/ BINUTILS_SRC_LOCATION=~/projects/gcc-ferrite/ 

Variables that are intresting for adding pre-defined marcos:
tm_defines and tm_file in configure.gcc
