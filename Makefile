
GNU_EFI_DIR=./gnu-efi

OBJ= obj/main.o \
     obj/memory_stuff.o


gnu-efi:
	git clone https://git.code.sf.net/p/gnu-efi/code gnu-efi
	make -C $(GNU_EFI_DIR)

mkgpt:
	git clone https://github.com/jncronin/mkgpt.git
	cd mkgpt \
		; automake --add-missing \
		; autoreconf \
		; ./configure
	make -C mkgpt
	sudo make -C mkgpt install

obj/%.o: src/%.c
	gcc -I$(GNU_EFI_DIR)/inc \
		-fpic \
		-ffreestanding \
		-fno-stack-protector \
		-fno-stack-check \
		-fshort-wchar \
		-mno-red-zone \
		-maccumulate-outgoing-args \
		-c $< \
		-o $@

obj/main.so: $(OBJ)
	ld \
	-shared \
	-Bsymbolic \
	-L$(GNU_EFI_DIR)/x86_64/lib \
	-L$(GNU_EFI_DIR)/x86_64/gnuefi \
	-T$(GNU_EFI_DIR)/gnuefi/elf_x86_64_efi.lds \
	$(GNU_EFI_DIR)/x86_64/gnuefi/crt0-efi-x86_64.o \
	$(OBJ) \
	-o $@ \
	-lgnuefi \
	-lefi

obj/BOOTX64.EFI: obj/main.so
	objcopy \
	-j .text -j .sdata -j .data -j .dynamic -j .dynsym  -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc \
	--target efi-app-x86_64 \
	--subsystem=10 \
	$< \
	$@


obj/os.img: obj/BOOTX64.EFI
	dd if=/dev/zero of=$@ bs=1k count=1440
	mformat -i $@ -f 1440 ::
	mmd -i $@ ::/EFI
	mmd -i $@ ::/EFI/BOOT
	mcopy -i $@ $< ::/EFI/BOOT

obj/hdimage.bin: obj/os.img
	mkgpt -o $@ --image-size 4096 --part $< --type system 


#ovmf:
#	mkdir -p ovmf
#	cp /usr/share/OVMF/OVMF_CODE.fd ovmf/.
#	cp /usr/share/OVMF/OVMF_VARS.fd ovmf/.

run: obj/hdimage.bin
	qemu-system-x86_64 \
	-L /usr/share/OVMF \
	-drive if=pflash,format=raw,readonly,file=/usr/share/OVMF/OVMF_CODE.fd \
	-drive file=$<,format=raw,index=0,media=disk

