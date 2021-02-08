# This is a very crude Makefile, allowing me to experiment with 
# indivudial build options for various files. 
# Needs a cleanup, and CC etc.

TARGET_TRIPLE=x86_64-pc-none-elf
LLVM_TOOLS = /usr/local/llvm-11.0.1
LLVM_LIBS = /usr/local/ferrite-llvm

CC = $(LLVM_TOOLS)/bin/clang
CXX = $(LLVM_TOOLS)/bin/clang++
LD=$(LLVM_TOOLS)/bin/ld.lld

CCFLAGS = -g -fno-unique-section-names


LLVMDIR = $(LLVM_TOOLS)/bin
#CC=$(LLVMDIR)/clang $(INCLUDE) --target=x86_64-pc-none-elf -stdlib=libc++
LLVMHOSTTOOLS=/usr/local/llvm-11.0.1




INCLUDE=-I ./flibc/. -I ./boot_src -I /usr/local/ferrite-llvm/include -I /usr/local/ferrite-llvm/x86_64-elf/include/



#
# Build clang used to build libraries. This is not about cross-compilation at all. 
#
toolbuild/llvm-11.0.1:
	mkdir -p toolbuild 
	cd toolbuild ; git clone https://github.com/llvm/llvm-project.git ; cd llvm-project ; git checkout llvmorg-11.0.1
	mv toolbuild/llvm-project toolbuild/llvm-11.0.1

toolbuild/llvm-11.0.1-host:
	mkdir -p toolbuild/llvm-11.0.1-host
	cd toolbuild/llvm-11.0.1-host ; \
		cmake -G "Unix Makefiles" \
		-DLLVM_ENABLE_PROJECTS="clang;lld" \
		-DLLVM_DEFAULT_TARGET_TRIPLE=$(TARGET_TRIPLE) \
		-DCMAKE_INSTALL_PREFIX=$(LLVMHOSTTOOLS) \
		-DCMAKE_BUILD_TYPE=Release \
		-DLVM_INSTALL_BINUTILS_SYMLINKS=True \
		../llvm-11.0.1/llvm \
	; make -j 4 \
	; make install


toolbuild/ferritelibs-build:
	mkdir -p toolbuild/ferritelibs-build
	cd toolbuild/ferritelibs-build \
	; cmake -DCMAKE_C_COMPILER=$(CC) \
		-DCMAKE_CXX_COMPILER=$(CXX) \
		-DCMAKE_LINKER=$(LD) \
		-DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_CROSSCOMPILING=True \
		-DCMAKE_INSTALL_PREFIX=$(LLVM_LIBS) \
		-DCMAKE_CXX_FLAGS="-target $(TARGET_TRIPLE)" \
		../llvm-11.0.1/llvm

#$ git clone https://github.com/llvm/llvm-project.git
#$ cd llvm-project
#$ mkdir build && cd build
#$ cmake -DCMAKE_C_COMPILER=clang \
#        -DCMAKE_CXX_COMPILER=clang++ \
#        -DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi" \
# /       ../llvm
#$ make # Build
#$ make check-cxx # Test
#$ make install-cxx install-cxxabi # Install


#
# NEWLIB
#
toolbuild/newlib-3.3.0:
	mkdir -p toolbuild 
	cd toolbuild ; curl -O ftp://sourceware.org/pub/newlib/newlib-3.3.0.tar.gz ; tar xf newlib-3.3.0.tar.gz

#	CXX_FOR_TARGET=$(LLVMDIR)/clang++ \


toolbuild/newlib-clang-3.3.0-done: toolbuild/newlib-3.3.0 toolbuild/gcc-$(GCCVER)-done-1st toolbuild/binutils-2.33.1-done
	mkdir -p toolbuild/newlib-build
	cd toolbuild/newlib-build ;	../newlib-3.3.0/configure --target=x86_64-elf --prefix=$(LLVM_PREFIX)/newlib \
	CC_FOR_TARGET=$(LLVMDIR)/clang \
	LD_FOR_TARGET=$(LLVMDIR)/ld64.lld  \
	AS_FOR_TARGET=$(LLVMDIR)/llvm-as \
	NM_FOR_TARGET=$(LLVMDIR)/llvm-nm \
	AR_FOR_TARGET=$(LLVMDIR)/llvm-ar \
	CFLAGS_FOR_TARGET="--target=x86_64-pc-none-elf" \
	RANLIB_FOR_TARGET=$(LLVMDIR)/llvm-ranlib \
	OBJDUMP_FOR_TARGET=$(LLVMDIR)/llvm-objdump \
	; make all

	touch toolbuild/newlib-clang-3.3.0-done


#toolbuild/
#cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DLLVM_BUILD_DOCS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local/ferrite-llvm -DCMAKE_CROSSCOMPILING=True -DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi;clang;lld" -DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-pc-none-eabi -DLLVM_TARGET_ARCH=X86 -DLLVM_TARGETS_TO_BUILD=X86 ../llvm-project-11.0.0/llvm



#mkdir build-newlib-llvm
#cd build-newlib-llvm
#export AS_FOR_TARGET=/home/olivier/Toolchains/gcc-arm-none-eabi-4_9-2014q4/bin/arm-none-eabi-as
#export CC_FOR_TARGET=/usr/bin/clang-3.6
#export CFLAGS_FOR_TARGET="-target arm-none-eabi"


#
# fclib
#
obj/file_operations.o: flibc/file_operations.cpp 
	$(CC) $(CCFLAGS) $(INCLUDE) --target=x86_64-pc-none-elf -ffreestanding -c $< -o $@
obj/newlib_glue_syscalls.o: flibc/newlib_glue_syscalls.cpp 
	$(CC) $(CCFLAGS) $(INCLUDE) --target=x86_64-pc-none-elf -ffreestanding -c $< -o $@
obj/unimplemented.o: flibc/unimplemented.cpp 
	$(CC) $(CCFLAGS) $(INCLUDE) --target=x86_64-pc-none-elf -ffreestanding -c $< -o $@


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
	$(CC) $(CCFLAGS) $(INCLUDE) --target=x86_64-pc-none-elf -ffreestanding -c $< -o $@

obj/console.o: boot_src/console.cpp
	$(CC) $(CCFLAGS) $(INCLUDE) --target=x86_64-pc-none-elf -ffreestanding -c $< -o $@

obj/interrupts.o: boot_src/interrupts.cpp
	$(CC) $(CCFLAGS) $(INCLUDE) --target=x86_64-pc-none-elf -ffreestanding -c $< -o $@

obj/memory.o: boot_src/memory.cpp
	$(CC) $(CCFLAGS) $(INCLUDE) --target=x86_64-pc-none-elf -ffreestanding -c $< -o $@

obj/ports.o: boot_src/ports.cpp
	$(CC) $(CCFLAGS) $(INCLUDE) --target=x86_64-pc-none-elf -ffreestanding -c $< -o $@

obj/printf.o: boot_src/printf.c 
	$(CC) $(CCFLAGS) $(INCLUDE) --target=x86_64-pc-none-elf -ffreestanding -c $< -o $@


obj/zeros.0:
	dd if=/dev/zero of=$@ bs=1000000 count=1
# 
# Putting it together
# 

#	-Ttext 0x10000 \
#	-Tdata 0x1B000 

obj/kernel_combined.bin: obj/kernel.o obj/kernel_cpp.o obj/console.o obj/interrupts.o obj/interrupts_lowlevel.o obj/memory.o obj/ports.o obj/newlib_glue_syscalls.o obj/printf.o obj/file_operations.o obj/newlib_glue_syscalls.o obj/unimplemented.o 
	$(LD) -v $^ /usr/local/ferrite/x86_64-elf/lib/libm.a /usr/local/ferrite/x86_64-elf/lib/libc.a /usr/local/ferrite/x86_64-elf/lib/libg.a -o obj/kernel_combined.bin \
	-Tlinker_map.map \
	--oformat binary 


os.bin: obj/zeros.0 obj/boot_sector.bin obj/kernel_combined.bin
	cat obj/boot_sector.bin obj/kernel_combined.bin obj/zeros.0 > $@


clean:
	rm obj/*.bin 
	rm obj/*.o


