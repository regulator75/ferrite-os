# This is a very crude Makefile, allowing me to experiment with 
# indivudial build options for various files. 
# Needs a cleanup, and CC etc.

os.bin: obj/boot_sector.bin obj/kernel_combined.bin
	cat obj/boot_sector.bin obj/kernel_combined.bin > obj/os.bin

obj/boot_sector.bin: boot_src/boot_sector.asm
	nasm -f bin boot_src/boot_sector.asm -o obj/boot_sector.bin

obj/interrupts_lowlevel.o: boot_src/interrupts_lowlevel.asm
	nasm -f elf64 boot_src/interrupts_lowlevel.asm -o obj/interrupts_lowlevel.o 

obj/kernel.o: boot_src/kernel.asm
	nasm -f elf64 boot_src/kernel.asm -o obj/kernel.o

obj/kernel_cpp.o: boot_src/kernel.cpp
	/usr/local/x86_64elfgcc/bin/x86_64-elf-gcc  -ffreestanding -c boot_src/kernel.cpp -o obj/kernel_cpp.o

obj/console.o: boot_src/console.cpp
	/usr/local/x86_64elfgcc/bin/x86_64-elf-gcc  -ffreestanding -c boot_src/console.cpp -o obj/console.o

obj/interrupts.o: boot_src/interrupts.cpp
	/usr/local/x86_64elfgcc/bin/x86_64-elf-gcc  -ffreestanding -c boot_src/interrupts.cpp -o obj/interrupts.o

obj/memory.o: boot_src/memory.cpp
	/usr/local/x86_64elfgcc/bin/x86_64-elf-gcc  -ffreestanding -c boot_src/memory.cpp -o obj/memory.o

obj/ports.o: boot_src/ports.cpp
	/usr/local/x86_64elfgcc/bin/x86_64-elf-gcc  -ffreestanding -c boot_src/ports.cpp -o obj/ports.o	

obj/kernel_combined.bin: obj/kernel.o obj/kernel_cpp.o obj/console.o obj/interrupts.o obj/interrupts_lowlevel.o obj/memory.o obj/ports.o
	/usr/local/x86_64elfgcc/bin/x86_64-elf-ld -o obj/kernel_combined.bin -Ttext 0x1000 -Tdata 0x20000 --oformat binary obj/kernel.o obj/kernel_cpp.o obj/console.o obj/interrupts.o obj/interrupts_lowlevel.o obj/memory.o obj/ports.o

clean:
	rm obj/*.bin 
	rm obj/*.o