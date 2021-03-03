# This is a very crude Makefile, allowing me to experiment with 
# indivudial build options for various files. 
# Needs a cleanup, and CC etc.



LLVM_TARGET_TRIPLE=x86_64-pc-none-elf
LLVM_TOOLS = /usr/local/llvm-11.0.1
LLVM_LIBS = /usr/local/ferrite-llvm
LLVM_INCLUDE=-I ./flibc/. -I ./boot_src -I /usr/local/ferrite-llvm/include -I /usr/local/ferrite-llvm/$(GCC_TARGET)/include/

LLVM_CC = $(LLVM_TOOLS)/bin/clang
LLVM_CXX = $(LLVM_TOOLS)/bin/clang++
LLVM_LD=$(LLVM_TOOLS)/bin/ld.lld

### Ferrite target flags. Used by compiler when generating ferrite OS binaries
LLVM_CCFLAGS = -g -fno-unique-section-names --target=x86_64-pc-none-elf -ffreestanding 


#CC=$(GCC_PREFIX)/bin/$(GCC_TARGET)-g++
#-lstdc++ 
GCC_PREFIX=/usr/local/ferrite
GCC_TARGET = x86_64-elf
GCC_VER=10.2.0
GCC_CC=$(GCC_PREFIX)/bin/$(GCC_TARGET)-gcc 
GCC_LD=$(GCC_PREFIX)/bin/$(GCC_TARGET)-ld -L$(GCC_PREFIX)/$(GCC_TARGET)/lib
GCC_INCLUDE=-I ./flibc/. -I ./boot_src -I /usr/local/ferrite/include -I /usr/local/ferrite/$(GCC_TARGET)/include/
GCC_CCFLAGS = -ffreestanding 

GDB_VER=10.1

#CC = $(LLVM_TOOLS)/bin/clang
#CXX = $(LLVM_TOOLS)/bin/clang++
#LD=$(LLVM_TOOLS)/bin/ld.lld

CC=$(GCC_CC)
LD=$(GCC_LD)
CCFLAGS = $(GCC_CCFLAGS)
INCLUDE = $(GCC_INCLUDE)



LLVM_BINDIR = $(LLVM_TOOLS)/bin
#CC=$(LLVM_BINDIR)/clang $(INCLUDE) --target=x86_64-pc-none-elf -stdlib=libc++
LLVMHOSTTOOLS=/usr/local/llvm-11.0.1



#
# BINUTILS
#
toolbuild/binutils-2.33.1:
	mkdir -p toolbuild 
	cd toolbuild ; curl -O https://ftp.gnu.org/gnu/binutils/binutils-2.33.1.tar.gz \
	; tar xf binutils-2.33.1.tar.gz


toolbuild/binutils-2.33.1-done: toolbuild/binutils-2.33.1
	mkdir -p toolbuild/binutils-build
	cd toolbuild/binutils-build ; ../binutils-2.33.1/configure --target=$(GCC_TARGET) --prefix=$(GCC_PREFIX) --enable-interwork --disable-multilib --disable-nls --disable-werror  \
	; make all \
	; sudo make install

	touch toolbuild/binutils-2.33.1-done

#
# libunwind
# 
toolbuild/libunwind-1.5.0:
	mkdir -p toolbuild 
	cd toolbuild ; wget http://download.savannah.nongnu.org/releases/libunwind/libunwind-1.5.0.tar.gz \
	; tar xf libunwind-1.5.0.tar.gz

toolbuild/libunwind-1/5/0-done:
	cd toolbuild/libunwind \
	./configure CC=$(GCC_CC) CXX=$(GCC_CC) CFLAGS="$(GCC_CCFLAGS)" PREFIX=$(GCC_PREFIX) --host=x86_64-linux-gnu


toolbuild/libunwind-11.0.0:
	mkdir -p toolbuild
	cd toolbuild ; wget https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/libunwind-11.0.0.src.tar.xz \
	; tar xf libunwind-11.0.0.src.tar.xz

toolbuild/libunwind-11.0.0-done:
	mkdir -p toolbuild/libunwind-11-build/
	cd toolbuild/libunwind-11-build \
	; cmake -G "Unix Makefiles" ../libunwind-11.0.0.src/ \
	-DLIBUNWIND_ENABLE_STATIC=ON \
	-DLIBUNWIND_ENABLE_SHARED=OFF \
	-DCMAKE_CXX_COMPILER=$(GCC_PREFIX)/bin/$(GCC_TARGET)-g++ \
	-DCMAKE_INSTALL_PREFIX=$(GCC_PREFIX)/$(GCC_TARGET) \
	-DCMAKE_CXX_FLAGS="--verbose -D_LIBUNWIND_IS_BAREMETAL=1" \
	-DLIBUNWIND_ENABLE_THREADS=OFF


#DLIBUNWIND_GCC_TOOLCHAIN=/usr/local/ferrite/x86_64-elf/bin/ \
# 	-DLIBUNWIND_TARGET_TRIPLE=$(GCC_TARGET)




#
# GCC
#

toolbuild/gcc-$(GCC_VER):
	mkdir -p toolbuild 
	cd toolbuild ; curl -O https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VER)/gcc-$(GCC_VER).tar.gz \
	; tar xf gcc-$(GCC_VER).tar.gz \
	; cd gcc-$(GCC_VER) \
	; ./contrib/download_prerequisites

#--enable-newlib 
toolbuild/gcc-$(GCC_VER)-done-1st: toolbuild/gcc-$(GCC_VER) toolbuild/binutils-2.33.1-done
	mkdir -p toolbuild/gcc-build
	cd toolbuild/gcc-build ; ../gcc-$(GCC_VER)/configure --target=$(GCC_TARGET) --prefix=$(GCC_PREFIX) \
	--disable-nls --disable-libssp --enable-languages=c,c++ --disable-multilib --disable-libaquadmath \
	--without-headers --disable-shared \
	; make all-gcc -j 24\
	; sudo make install-gcc

	touch toolbuild/gcc-$(GCC_VER)-done-1st

# --with-newlib 
# toolbuild/newlib-3.3.0-done
# toolbuild/newlib-3.3.0-done
toolbuild/gcc-$(GCC_VER)-done-2nd: toolbuild/gcc-$(GCC_VER)-done-1st 
	mkdir -p toolbuild/gcc-build
	cd toolbuild/gcc-build ; ../gcc-$(GCC_VER)/configure --target=$(GCC_TARGET) --prefix=$(GCC_PREFIX) \
	--disable-nls --disable-libssp --enable-languages=c,c++ --disable-multilib --disable-libaquadmath \
	--disable-shared --with-as=$(GCC_PREFIX)/bin/$(GCC_TARGET)-as --with-ld=$(GCC_PREFIX)/bin/$(GCC_TARGET)-ld --with-build-time-tools=$(GCC_PREFIX)/$(GCC_TARGET)/bin/ \
	; make all-gcc -j 24 \
	; make all-target-libgcc -j 24 \
	; make all-target-libstdc++-v3 -j 24 \
	; sudo make install-target-libgcc \
	; sudo make install-gcc \
	; sudo make install-target-libstdc++-v3 

	touch toolbuild/gcc-$(GCC_VER)-done-2nd


#
# GDB
#
toolbuild/gdb-$(GDB_VER):
	mkdir -p toolbuild 
	cd toolbuild ; curl -O http://ftp.gnu.org/gnu/gdb/gdb-$(GDB_VER).tar.xz \
	; tar xf gdb-$(GDB_VER).tar.xz

toolbuild/gdb-done: toolbuild/gdb-$(GDB_VER)
	mkdir -p toolbuild/gdb-build
	cd toolbuild/gdb-build ; ../gdb-$(GDB_VER)/configure \
	--target=$(GCC_TARGET) \
	--prefix=$(GCC_PREFIX) \
	--with-python=/usr/bin/python3 \
	--host=x86_64-linux-gnu \
	make \
	make install

	touch toolbuild/gdb-done

#
# Build clang used to build libraries. This is not about cross-compilation at all. 
#
toolbuild/llvm-11.0.1:
	mkdir -p toolbuild 
	cd toolbuild ; git clone https://github.com/llvm/llvm-project.git ; cd llvm-project ; git checkout llvmorg-11.0.1
	mv toolbuild/llvm-project toolbuild/llvm-11.0.1

toolbuild/llvm-11.0.1-host-:
	mkdir -p toolbuild/llvm-11.0.1-host
	cd toolbuild/llvm-11.0.1-host ; \
		cmake -G "Unix Makefiles" \
		-DLLVM_ENABLE_PROJECTS="clang;lld" \
		-DLLVM_DEFAULT_TARGET_TRIPLE=$(LLVM_TARGET_TRIPLE) \
		-DCMAKE_INSTALL_PREFIX=$(LLVMHOSTTOOLS) \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_INSTALL_BINUTILS_SYMLINKS=True \
		../llvm-11.0.1/llvm \
	; make -j 4
	#make install


toolbuild/ferritelibs-build-:
	mkdir -p toolbuild/ferritelibs-build
	cd toolbuild/ferritelibs-build \
	; cmake -DCMAKE_C_COMPILER=$(CC) \
		-DCMAKE_CXX_COMPILER=$(CXX) \
		-DCMAKE_LINKER=$(LD) \
		-DLLVM_TARGET_ARCH=x86_64 \
		-DLLVM_TARGETS_TO_BUILD=x86_64 \
		-DLLVM_ENABLE_PROJECTS="compiler-rt;libcxx;libcxxabi" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_CROSSCOMPILING=True \
		-DCMAKE_INSTALL_PREFIX=$(LLVM_LIBS) \
		-DCMAKE_CXX_FLAGS="-target $(LLVM_TARGET_TRIPLE)" \
		-DLD=/usr/local/llvm-11.0.1/bin/ld64.lld \
		../llvm-11.0.1/llvm

toolbuild/makelinks:
	sudo ln -s $(GCCPREFIX)/$(GCC_TARGET)-gcc $(LLVM_TOOLS)/bin/gcc
	sudo ln -s $(GCCPREFIX)/$(GCC_TARGET)-ld $(LLVM_TOOLS)/bin/ld


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

#	CXX_FOR_TARGET=$(LLVM_BINDIR)/clang++ \


toolbuild/newlib-clang-3.3.0-done: toolbuild/newlib-3.3.0 toolbuild/gcc-$(GCC_VER)-done-1st toolbuild/binutils-2.33.1-done
	mkdir -p toolbuild/newlib-build
	cd toolbuild/newlib-build ;	../newlib-3.3.0/configure --target=$(GCC_TARGET) --prefix=$(LLVM_PREFIX)/newlib \
	CC_FOR_TARGET=$(LLVM_BINDIR)/clang \
	LD_FOR_TARGET=$(LLVM_BINDIR)/ld64.lld  \
	AS_FOR_TARGET=$(LLVM_BINDIR)/llvm-as \
	NM_FOR_TARGET=$(LLVM_BINDIR)/llvm-nm \
	AR_FOR_TARGET=$(LLVM_BINDIR)/llvm-ar \
	CFLAGS_FOR_TARGET="--target=x86_64-pc-none-elf" \
	RANLIB_FOR_TARGET=$(LLVM_BINDIR)/llvm-ranlib \
	OBJDUMP_FOR_TARGET=$(LLVM_BINDIR)/llvm-objdump \
	; make all

	touch toolbuild/newlib-clang-3.3.0-done


toolbuild/newlib-3.3.0-done: toolbuild/newlib-3.3.0 toolbuild/gcc-$(GCC_VER)-done-1st toolbuild/binutils-2.33.1-done
	mkdir -p toolbuild/newlib-build
	cd toolbuild/newlib-build ;	../newlib-3.3.0/configure --target=$(GCC_TARGET) --prefix=$(GCC_PREFIX) \
	CC_FOR_TARGET=$(GCC_PREFIX)/bin/$(GCC_TARGET)-gcc \
	CXX_FOR_TARGET=$(GCC_PREFIX)/bin/$(GCC_TARGET)-g++ \
	LD_FOR_TARGET=$(GCC_PREFIX)/bin/$(GCC_TARGET)-ld \
	AS_FOR_TARGET=$(GCC_PREFIX)/bin/$(GCC_TARGET)-gcc-as \
	NM_FOR_TARGET=$(GCC_PREFIX)/bin/$(GCC_TARGET)-gcc-nm \
	AR_FOR_TARGET=$(GCC_PREFIX)/bin/$(GCC_TARGET)-ar \
	RANLIB_FOR_TARGET=$(GCC_PREFIX)/bin/$(GCC_TARGET)-ranlib \
	OBJDUMP_FOR_TARGET=$(GCC_PREFIX)/bin/$(GCC_TARGET)-objdump \
	; make all -j 24 \
	; sudo make install 

	$(GCC_PREFIX)/bin/$(GCC_TARGET)-as crt0.s -o obj/crt0.o
	sudo cp obj/crt0.o $(GCC_PREFIX)/$(GCC_TARGET)/lib/

	touch toolbuild/newlib-3.3.0-done



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




#mkdir build-newlib-llvm
#cd build-newlib-llvm
#export AS_FOR_TARGET=/home/olivier/Toolchains/gcc-arm-none-eabi-4_9-2014q4/bin/arm-none-eabi-as
#export CC_FOR_TARGET=/usr/bin/clang-3.6
#export CFLAGS_FOR_TARGET="-target arm-none-eabi"



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


