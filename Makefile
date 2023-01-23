
# Kernel_asm must be first, so its entry point lands at 0x10000
OBJ= \
	 obj/kernel_asm.o \
	 obj/console.o \
	 obj/interrupts.o \
	 obj/kernel.o \
	 obj/memory.o \
	 obj/ports.o \
	 obj/interrupts_lowlevel.o

# 	 obj/printf.o  obj/main.o obj/memory_stuff.o \
#	 boot_sect_disk.o \
	 boot_sect_print.o \
	 64bit-switch.o \
	 64bit_print.o \
	 64bit-gdt.o\
	 32bit-switch.o\

	 
	\


obj/%.o: src/%.c
	gcc \
		-ffreestanding \
		-fno-stack-protector \
		-fno-stack-check \
		-mno-red-zone \
		-g \
		-c $< \
		-o $@

#		-fpic \
#		-fshort-wchar \
#		-maccumulate-outgoing-args \


obj/%.o: src/%.asm
	nasm -g -f elf64 $< -o $@

#ovmf:
#	mkdir -p ovmf
#	cp /usr/share/OVMF/OVMF_CODE.fd ovmf/.
#	cp /usr/share/OVMF/OVMF_VARS.fd ovmf/.

#run: obj/hdimage.bin
#	qemu-system-x86_64 \
#	-L /usr/share/OVMF \
#	-drive if=pflash,format=raw,readonly,file=/usr/share/OVMF/OVMF_CODE.fd \
#	-drive file=$<,format=raw,index=0,media=disk



# This is a very crude Makefile, allowing me to experiment with 
# indivudial build options for various files. 
# Needs a cleanup, and CC etc.

# include Make.defaults


#
# fclib
#

FLIB_OBJ = obj/file_operations.o obj/newlib_glue_syscalls.o obj/unimplemented.o obj/file_handles.o

obj/%.o: flibc/%.cpp 
	$(CC) $(CCFLAGS) $(INCLUDE) -c $< -o $@


obj/boot_sector.bin: src/boot_sector.asm
	nasm -g -l obj/boot_sector.lst -f bin $< -o $@


obj/zeros.0:
	mkdir -p obj/
	dd if=/dev/zero of=$@ bs=1000000 count=1

obj/kernel_combined.bin:  $(OBJ) #$(FLIB_OBJ)
	$(LD) --verbose -v $^ \
	-o obj/kernel_combined.bin \
	-Tlinker_map.map \
	--oformat binary \
	--eh-frame-hdr \
	-Map obj/linkmap.map --verbose
#	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libsupc++.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libunwind.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libstdc++.a  \

#	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libnosys.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libm.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libc.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libg.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/pthread.a 

## DEBUGGING ONLY, identical to above exceot no --oformat binary
obj/kernel_combined.elf: $(OBJ) #$(FLIB_OBJ)
	$(LD) --verbose -v $^ \
	-o obj/kernel_combined.elf \
	-Tlinker_map.map \
	--eh-frame-hdr

# 	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libsupc++.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libunwind.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libstdc++.a  \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libnosys.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libm.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libc.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libg.a 

os.elf: obj/kernel_combined.elf
	cp $< $@


debug: os.elf os.bin
	qemu-system-x86_64 -s -S -hda os.bin &
	gdb -ex "target remote localhost:1234" -ex "symbol-file os.elf" -ex "break *0x7c00" -ex "layout split" -ex "break *0x10000"

run: os.bin
	qemu-system-x86_64 -hda os.bin

__debug: os.bin
	qemu-system-x86_64 -s -S -hda os.bin &
	gdb -ex "target remote localhost:1234" -ex "break *0x7c00" -ex "layout split" -ex "break *0x10000"

#-lstdc++
#	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libucontext.a  \

os.bin: obj/zeros.0 obj/boot_sector.bin obj/kernel_combined.bin
	cat obj/boot_sector.bin obj/kernel_combined.bin obj/zeros.0 > $@


clean:
	rm obj/*.bin 
	rm obj/*.o
	rm os.bin
	rm os.elf
	rm obj/kernel_combined.elf	
