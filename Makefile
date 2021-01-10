# This is a very crude Makefile, allowing me to experiment with 
# indivudial build options for various files. 
# Needs a cleanup, and CC etc.

GCCVER=10.2.0
PREFIX=/usr/local/ferrite
#CC=$(PREFIX)/bin/x86_64-elf-g++
CC=$(PREFIX)/bin/x86_64-elf-gcc $(INCLUDE)
LD=$(PREFIX)/bin/x86_64-elf-ld
##GCCVER=9.2.0

INCLUDE=-I ./flibc/. -I ./boot_src


#
# BINUTILS
#
toolbuild/binutils-2.33.1:
	mkdir -p toolbuild 
	cd toolbuild ; curl -O https://ftp.gnu.org/gnu/binutils/binutils-2.33.1.tar.gz \
	; tar xf binutils-2.33.1.tar.gz


toolbuild/binutils-2.33.1-done: toolbuild/binutils-2.33.1
	mkdir -p toolbuild/binutils-build
	cd toolbuild/binutils-build ; ../binutils-2.33.1/configure --target=x86_64-elf --prefix=$(PREFIX) --enable-interwork --disable-multilib --disable-nls --disable-werror  \
	; make all \
	; sudo make install

	touch toolbuild/binutils-2.33.1-done

#
# GCC
#

toolbuild/gcc-$(GCCVER):
	mkdir -p toolbuild 
	cd toolbuild ; curl -O https://ftp.gnu.org/gnu/gcc/gcc-$(GCCVER)/gcc-$(GCCVER).tar.gz \
	; tar xf gcc-$(GCCVER).tar.gz

toolbuild/gcc-$(GCCVER)-done-1st: toolbuild/gcc-$(GCCVER) toolbuild/binutils-2.33.1-done
	mkdir -p toolbuild/gcc-build
	cd toolbuild/gcc-build ; ../gcc-$(GCCVER)/configure --target=x86_64-elf --prefix=$(PREFIX) \
	--disable-nls --disable-libssp --enable-languages=c,c++ --disable-multilib \
	--enable-newlib --without-headers --disable-shared\
	; make all-gcc \
	; make all-target-libgcc \
	; sudo make install-gcc \
	; sudo make install-target-libgcc

	touch toolbuild/gcc-$(GCCVER)-done-1st

toolbuild/gcc-$(GCCVER)-done-2nd: toolbuild/gcc-$(GCCVER)-done-1st toolbuild/newlib-3.3.0-done
	mkdir -p toolbuild/gcc-build
	cd toolbuild/gcc-build ; ../gcc-$(GCCVER)/configure --target=x86_64-elf --prefix=$(PREFIX) \
	--disable-nls --disable-libssp --enable-languages=c,c++ --disable-multilib \
	--enable-newlib --without-headers --disable-shared --with-headers=$(PREFIX)/x86_64-elf/include --with-libs=$(PREFIX)/x86_64-elf/lib \
	; make all-gcc \
	; make all-target-libgcc \
	; sudo make install-gcc \
	; sudo make install-target-libgcc

	touch toolbuild/gcc-$(GCCVER)-done-2nd
#
# NEWLIB
#
toolbuild/newlib-3.3.0:
	mkdir -p toolbuild 
	cd toolbuild ; curl -O ftp://sourceware.org/pub/newlib/newlib-3.3.0.tar.gz ; tar xf newlib-3.3.0.tar.gz

toolbuild/newlib-3.3.0-done: toolbuild/newlib-3.3.0 toolbuild/gcc-$(GCCVER)-done-1st toolbuild/binutils-2.33.1-done
	mkdir -p toolbuild/newlib-build
	cd toolbuild/newlib-build ;	../newlib-3.3.0/configure --target=x86_64-elf --prefix=$(PREFIX) \
	CC_FOR_TARGET=$(PREFIX)/bin/x86_64-elf-gcc \
	CXX_FOR_TARGET=$(PREFIX)/bin/x86_64-elf-g++ \
	LD_FOR_TARGET=$(PREFIX)/bin/x86_64-elf-ld \
	AS_FOR_TARGET=$(PREFIX)/bin/x86_64-elf-as \
	NM_FOR_TARGET=$(PREFIX)/bin/x86_64-elf-nm \
	AR_FOR_TARGET=$(PREFIX)/bin/x86_64-elf-ar \
	RANLIB_FOR_TARGET=$(PREFIX)/bin/x86_64-elf-ranlib \
	OBJDUMP_FOR_TARGET=$(PREFIX)/bin/x86_64-elf-objdump \
	; make all \
	; sudo make install 

	touch toolbuild/newlib-3.3.0-done

tools: toolbuild/newlib-3.3.0-done toolbuild/gcc-$(GCCVER)-done-2nd toolbuild/binutils-2.33.1-done

#
# fclib
#
obj/file_operations.o: flibc/file_operations.cpp 
	$(CC)  -ffreestanding -c $< -o $@
obj/newlib_glue_syscalls.o: flibc/newlib_glue_syscalls.cpp 
	$(CC)  -ffreestanding -c $< -o $@
obj/unimplemented.o: flibc/unimplemented.cpp 
	$(CC)  -ffreestanding -c $< -o $@


#
# Kernel-boot
#


obj/boot_sector.bin: boot_src/boot_sector.asm
	nasm -f bin $< -o $@

obj/interrupts_lowlevel.o: boot_src/interrupts_lowlevel.asm
	nasm -f elf64 $< -o $@ 

obj/kernel.o: boot_src/kernel.asm
	nasm -f elf64 $< -o obj/kernel.o

obj/kernel_cpp.o: boot_src/kernel.cpp
	$(CC)  -ffreestanding -c $< -o $@

obj/console.o: boot_src/console.cpp
	$(CC)  -ffreestanding -c $< -o $@

obj/interrupts.o: boot_src/interrupts.cpp
	$(CC)  -ffreestanding -c $< -o $@

obj/memory.o: boot_src/memory.cpp
	$(CC)  -ffreestanding -c $< -o $@

obj/ports.o: boot_src/ports.cpp
	$(CC)  -ffreestanding -c $< -o $@

obj/printf.o: boot_src/printf.c 
	$(CC)  -ffreestanding -c $< -o $@


# 
# Putting it together
# 


obj/kernel_combined.bin: obj/kernel.o obj/kernel_cpp.o obj/console.o obj/interrupts.o obj/interrupts_lowlevel.o obj/memory.o obj/ports.o obj/newlib_glue_syscalls.o obj/printf.o obj/file_operations.o obj/newlib_glue_syscalls.o obj/unimplemented.o 
	$(LD) $^ /usr/local/ferrite/x86_64-elf/lib/libm.a /usr/local/ferrite/x86_64-elf/lib/libc.a /usr/local/ferrite/x86_64-elf/lib/libg.a -o obj/kernel_combined.bin -Ttext 0x10000 -Tdata 0x1B000 --oformat binary 


os.bin: obj/boot_sector.bin obj/kernel_combined.bin
	cat obj/boot_sector.bin obj/kernel_combined.bin > $@


clean:
	rm obj/*.bin 
	rm obj/*.o


