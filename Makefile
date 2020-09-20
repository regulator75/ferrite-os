os.bin: kernel.bin boot_sector.bin obj/kernel_cpp.bin
	cat obj/boot_sector.bin obj/kernel.bin > obj/os.bin

boot_sector.bin:
	nasm -f bin boot_src/boot_sector.asm -o obj/boot_sector.bin

kernel.bin: 
	nasm -f bin boot_src/kernel.asm -o obj/kernel.bin

obj/kernel_cpp.bin: boot_src/kernel.cpp
	x86_64-apple-darwin17-gcc-9  -ffreestanding -c boot_src/kernel.cpp -o obj/kernel_cpp.o
	x86_64-apple-darwin17-ld -o kernel_cpp.bin -Ttext 0x0 --oformat binary obj/kernel_cpp.o