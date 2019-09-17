os.bin: kernel.bin boot_sector.bin
	cat obj/boot_sector.bin obj/kernel.bin > obj/os.bin

boot_sector.bin:
	nasm -f bin boot_src/boot_sector.asm -o obj/boot_sector.bin


kernel.bin:
	nasm -f bin boot_src/kernel.asm -o obj/kernel.bin