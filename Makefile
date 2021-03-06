# This is a very crude Makefile, allowing me to experiment with 
# indivudial build options for various files. 
# Needs a cleanup, and CC etc.

include Make.defaults

#toolbuild/
#cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DLLVM_BUILD_DOCS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local/ferrite-llvm -DCMAKE_CROSSCOMPILING=True -DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi;clang;lld" -DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-pc-none-eabi -DLLVM_TARGET_ARCH=X86 -DLLVM_TARGETS_TO_BUILD=X86 ../llvm-project-11.0.0/llvm

# --with-headers=$(GCC_PREFIX)/$(GCC_TARGET)/include --with-libs=$(GCC_PREFIX)/$(GCC_TARGET)/lib  

toolbuild/libstdcpp-done: toolbuild/gcc-$(GCC_VER)-done-2nd
	#mkdir -p toolbuild/gcc-build-libstdcpp
	#cp -a toolbuild/gcc-build/. toolbuild/gcc-build-libstdcpp
	cd toolbuild/gcc-build ; ../gcc-$(GCC_VER)/configure \
	--target=$(GCC_TARGET) --prefix=$(GCC_PREFIX) \
	--disable-nls --disable-libssp --enable-languages=c,c++ --disable-multilib \
	--with-newlib --disable-shared --disable-libaquadmath \
	--with-build-sysroot=$(GCC_PREFIX) \
	; make all-target-libstdc++-v3 -j 24 \
	; sudo make install-target-libstdc++-v3

	touch toolbuild/libstdcpp-done


#
# fclib
#
obj/file_operations.o: flibc/file_operations.cpp 
	$(CC) $(CCFLAGS) $(INCLUDE) -c $< -o $@
obj/newlib_glue_syscalls.o: flibc/newlib_glue_syscalls.cpp 
	$(CC) $(CCFLAGS) $(INCLUDE) -c $< -o $@
obj/unimplemented.o: flibc/unimplemented.cpp 
	$(CC) $(CCFLAGS) $(INCLUDE) -c $< -o $@
obj/file_handles.o: flibc/file_handles.c
	$(CC) $(CCFLAGS) $(INCLUDE) -c $< -o $@


# Kernel-boot
#


obj/boot_sector.bin: boot_src/boot_sector.asm
	nasm -f bin $< -o $@

obj/interrupts_lowlevel.o: boot_src/interrupts_lowlevel.asm
	nasm -f elf64 $< -o $@ 

obj/kernel.o: boot_src/kernel.asm
	nasm -f elf64 $< -o $@

obj/kernel_cpp.o: boot_src/kernel.cpp
	$(CC) $(CCFLAGS) $(INCLUDE) -c $< -o $@

obj/console.o: boot_src/console.cpp
	$(CC) $(CCFLAGS) $(INCLUDE) -c $< -o $@

obj/interrupts.o: boot_src/interrupts.cpp
	$(CC) $(CCFLAGS) $(INCLUDE) -c $< -o $@

obj/memory.o: boot_src/memory.cpp
	$(CC) $(CCFLAGS) $(INCLUDE) -c $< -o $@

obj/ports.o: boot_src/ports.cpp
	$(CC) $(CCFLAGS) $(INCLUDE) -c $< -o $@

obj/printf.o: boot_src/printf.c 
	$(CC) $(CCFLAGS) $(INCLUDE) -c $< -o $@

obj/zeros.0:
	dd if=/dev/zero of=$@ bs=1000000 count=1



#
# EFI kernel
#
efi_obj/efi_main.o : efi_boot_src/efi_main.c
	$(CC) $(EFI_CCFLAGS) $(EFI_INCLUDE) -c $< -o $@

efi_obj/console.o : boot_src/console.cpp
	$(CC) $(EFI_CCFLAGS) $(EFI_INCLUDE) -c $< -o $@
# 
# Putting it together
# 

#	-Ttext 0x10000 \
#	-Tdata 0x1B000 

obj/kernel_combined.bin: obj/file_handles.o obj/kernel.o obj/kernel_cpp.o obj/console.o obj/interrupts.o obj/interrupts_lowlevel.o obj/memory.o obj/ports.o obj/newlib_glue_syscalls.o obj/printf.o obj/file_operations.o obj/newlib_glue_syscalls.o obj/unimplemented.o
	$(LD) --verbose -v $^ \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libsupc++.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libunwind.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libstdc++.a  \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libnosys.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libm.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libc.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libg.a \
	-o obj/kernel_combined.bin \
	-Tlinker_map.map \
	--oformat binary \
	--eh-frame-hdr

## DEBUGGING ONLY, identical to above exceot no --oformat binary
obj/kernel_combined.elf: obj/file_handles.o obj/kernel.o obj/kernel_cpp.o obj/console.o obj/interrupts.o obj/interrupts_lowlevel.o obj/memory.o obj/ports.o obj/newlib_glue_syscalls.o obj/printf.o obj/file_operations.o obj/newlib_glue_syscalls.o obj/unimplemented.o
	$(LD) --verbose -v $^ \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libsupc++.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libunwind.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libstdc++.a  \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libnosys.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libm.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libc.a \
	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libg.a \
	-o obj/kernel_combined.elf \
	-Tlinker_map.map \
	--eh-frame-hdr

os.elf: obj/kernel_combined.elf
	cp $< $@


debug: os.elf
	qemu-system-x86_64 -s -S -hda os.bin &
	 $(GCC_PREFIX)/bin/$(GCC_TARGET)-gdb -ex "target remote localhost:1234" -ex "symbol-file os.elf"

run: os.bin
	qemu-system-x86_64 -hda os.bin

#-lstdc++
#	$(GCC_PREFIX)/$(GCC_TARGET)/lib/libucontext.a  \

os.bin: obj/zeros.0 obj/boot_sector.bin obj/kernel_combined.bin
	cat obj/boot_sector.bin obj/kernel_combined.bin obj/zeros.0 > $@


clean:
	rm obj/*.bin 
	rm obj/*.o



efi_obj/os.so: efi_obj/efi_main.o efi_obj/console.o
	$(GCC_PREFIX)/bin/$(GCC_TARGET)-ld -shared -Bsymbolic -L$(GCC_PREFIX)/lib -T$(GCC_PREFIX)/lib/elf_x86_64_efi.lds \
	$(GCC_PREFIX)/lib/crt0-efi-x86_64.o $^ \
	-o $@ -lgnuefi -lefi

efi_obj/os.efi: efi_obj/os.so
	# TODO update binutils above to use 2.36 so this command can work with the localized version.
	objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym  -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10 $< $@
	#$(GCC_PREFIX)/bin/$(GCC_TARGET)-objcopy

os.img: efi_obj/os.efi
	dd if=/dev/zero of=os.img bs=512 count=93750
	parted os.img -s -a minimal mklabel gpt
	parted os.img -s -a minimal mkpart EFI FAT16 2048s 93716s
	parted os.img -s -a minimal toggle 1 boot

	dd if=/dev/zero of=efi_obj/tmp_part.img bs=512 count=91669
	mformat -i efi_obj/tmp_part.img -h 32 -t 32 -n 64 -c 1

	mcopy -i efi_obj/tmp_part.img $< ::

	dd if=efi_obj/tmp_part.img of=os.img bs=512 count=91669 seek=2048 conv=notrunc

	rm efi_obj/tmp_part.img