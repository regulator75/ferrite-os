os.bin: obj/boot_sector.bin obj/kernel_combined.bin
	cat obj/boot_sector.bin obj/kernel_combined.bin > obj/os.bin

obj/boot_sector.bin: boot_src/boot_sector.asm
	nasm -f bin boot_src/boot_sector.asm -o obj/boot_sector.bin

obj/kernel.o: boot_src/kernel.asm
	nasm -f elf64 boot_src/kernel.asm -o obj/kernel.o

obj/kernel_cpp.o: boot_src/kernel.cpp
	/usr/local/x86_64elfgcc/bin/x86_64-elf-gcc  -ffreestanding -c boot_src/kernel.cpp -o obj/kernel_cpp.o

obj/console.o: boot_src/console.cpp
	/usr/local/x86_64elfgcc/bin/x86_64-elf-gcc  -ffreestanding -c boot_src/console.cpp -o obj/console.o


obj/kernel_combined.bin: obj/kernel.o obj/kernel_cpp.o obj/console.o
	/usr/local/x86_64elfgcc/bin/x86_64-elf-ld -o obj/kernel_combined.bin -Ttext 0x1000 --oformat binary obj/kernel.o obj/kernel_cpp.o obj/console.o

clean:
	rm obj/*.bin 
	rm obj/*.o