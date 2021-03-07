

include ../Make.defaults

#
# BINUTILS
#

all: binutils gcc1 gcc2 gdb newlib libunwind libstdcpp gnu-efi

downloads: binutils-$(BINUTILS_VERSION) gcc-$(GCC_VER) gdb-$(GDB_VER) newlib-$(NEWLIB_VERSION) libunwind-$(LLVM_LIBUNWIND_VERSION).src gnu-efi-$(GNU_EFTI_VERSION)


cleanbuilds:
	rm -rf binutils-build
	rm -rf gcc-build
	rm -rf gdb-build
	rm -rf newlib-build
	rm -rf libunwind-build
	rm -rf binutils-build


binutils: binutils-$(BINUTILS_VERSION)-done

binutils-$(BINUTILS_VERSION):
	curl -O https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.gz \
	; tar xf binutils-$(BINUTILS_VERSION).tar.gz


binutils-$(BINUTILS_VERSION)-done: binutils-$(BINUTILS_VERSION)
	mkdir -p binutils-build
	cd binutils-build ; ../binutils-$(BINUTILS_VERSION)/configure --target=$(GCC_TARGET) --prefix=$(GCC_PREFIX) --enable-interwork --disable-multilib --disable-nls --disable-werror  \
	; make all \
	; sudo make install

	touch binutils-$(BINUTILS_VERSION)-done



#
# GCC
#

gcc1: gcc-$(GCC_VER)-done-1st

gcc-$(GCC_VER):
	curl -O https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VER)/gcc-$(GCC_VER).tar.gz 
	tar xf gcc-$(GCC_VER).tar.gz
	cd gcc-$(GCC_VER) ; ./contrib/download_prerequisites


gcc-$(GCC_VER)-done-1st: gcc-$(GCC_VER) binutils-$(BINUTILS_VERSION)-done
	mkdir -p gcc-build
	cd gcc-build ; ../gcc-$(GCC_VER)/configure --target=$(GCC_TARGET) --prefix=$(GCC_PREFIX) \
	--disable-nls --disable-libssp --enable-languages=c,c++ --disable-multilib --disable-libaquadmath \
	--without-headers --disable-shared \
	; make all-gcc -j 24\
	; sudo make install-gcc

	touch gcc-$(GCC_VER)-done-1st


gcc2:gcc-$(GCC_VER)-done-2nd

gcc-$(GCC_VER)-done-2nd: gcc-$(GCC_VER)-done-1st 
	mkdir -p gcc-build
	cd gcc-build ; ../gcc-$(GCC_VER)/configure --target=$(GCC_TARGET) --prefix=$(GCC_PREFIX) \
	--disable-nls --disable-libssp --enable-languages=c,c++ --disable-multilib --disable-libaquadmath \
	--disable-shared --with-as=$(GCC_PREFIX)/bin/$(GCC_TARGET)-as --with-ld=$(GCC_PREFIX)/bin/$(GCC_TARGET)-ld --with-build-time-tools=$(GCC_PREFIX)/$(GCC_TARGET)/bin/ \
	; make all-gcc -j 24 \
	; make all-target-libgcc -j 24 \
	; make all-target-libstdc++-v3 -j 24 \
	; sudo make install-target-libgcc \
	; sudo make install-gcc


	touch gcc-$(GCC_VER)-done-2nd


#
# GDB
#
gdb: gdb-$(GDB_VER)-done

gdb-$(GDB_VER):
	curl -O http://ftp.gnu.org/gnu/gdb/gdb-$(GDB_VER).tar.xz
	tar xf gdb-$(GDB_VER).tar.xz

gdb-$(GDB_VER)-done: gdb-$(GDB_VER)
	mkdir -p gdb-build
	cd gdb-build ; ../gdb-$(GDB_VER)/configure \
	--target=$(GCC_TARGET) \
	--prefix=$(GCC_PREFIX) \
	--with-python=/usr/bin/python3 \
	--host=x86_64-linux-gnu \
	make \
	make install

	touch gdb-$(GDB_VER)-done



#
# NEWLIB
#

newlib: newlib-$(NEWLIB_VERSION)-done

newlib-$(NEWLIB_VERSION):
	curl -O ftp://sourceware.org/pub/newlib/newlib-$(NEWLIB_VERSION).tar.gz
	tar xf newlib-$(NEWLIB_VERSION).tar.gz


newlib-$(NEWLIB_VERSION)-done: newlib-$(NEWLIB_VERSION) gcc-$(GCC_VER)-done-1st binutils-$(BINUTILS_VERSION)-done
	mkdir -p newlib-build
	cd newlib-build ;	../newlib-$(NEWLIB_VERSION)/configure --target=$(GCC_TARGET) --prefix=$(GCC_PREFIX) \
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

	$(GCC_PREFIX)/bin/$(GCC_TARGET)-as ../crt0.s -o crt0.o
	sudo cp crt0.o $(GCC_PREFIX)/$(GCC_TARGET)/lib/.

	touch newlib-$(NEWLIB_VERSION)-done




#
# libunwind
# 
##libunwind-1.5.0:
##	wget http://download.savannah.nongnu.org/releases/libunwind/libunwind-1.5.0.tar.gz \
##	; tar xf libunwind-1.5.0.tar.gz

##libunwind-1/5/0-done:
##	cd libunwind \
##	./configure CC=$(GCC_CC) CXX=$(GCC_CC) CFLAGS="$(GCC_CCFLAGS)" PREFIX=$(GCC_PREFIX) --host=x86_64-linux-gnu

libunwind : libunwind-$(LLVM_LIBUNWIND_VERSION)-done

libunwind-$(LLVM_LIBUNWIND_VERSION).src:
	wget https://github.com/llvm/llvm-project/releases/download/llvmorg-$(LLVM_LIBUNWIND_VERSION)/libunwind-$(LLVM_LIBUNWIND_VERSION).src.tar.xz
	tar xf libunwind-$(LLVM_LIBUNWIND_VERSION).src.tar.xz

libunwind-$(LLVM_LIBUNWIND_VERSION)-done: libunwind-$(LLVM_LIBUNWIND_VERSION).src
	mkdir -p libunwind-build/
	cd libunwind-build \
	; cmake -G "Unix Makefiles" ../libunwind-$(LLVM_LIBUNWIND_VERSION).src/ \
	-DLIBUNWIND_ENABLE_STATIC=ON \
	-DLIBUNWIND_ENABLE_SHARED=OFF \
	-DCMAKE_CXX_COMPILER=$(GCC_PREFIX)/bin/$(GCC_TARGET)-g++ \
	-DCMAKE_INSTALL_PREFIX=$(GCC_PREFIX)/$(GCC_TARGET) \
	-DCMAKE_CXX_FLAGS="--verbose -D_LIBUNWIND_IS_BAREMETAL=1" \
	-DLIBUNWIND_ENABLE_THREADS=OFF \
	cd libunwind-build \
	; make \
	; sudo make install-unwind



#
# libstdc++
#
libstdcpp: libstdcpp-$(GCC_VER)-done

libstdcpp-$(GCC_VER)-done: gcc-$(GCC_VER)-done-2nd
	#mkdir -p toolbuild/gcc-build-libstdcpp
	#cp -a toolbuild/gcc-build/. toolbuild/gcc-build-libstdcpp
	cd gcc-build \
	; make distclean \
	;../gcc-$(GCC_VER)/configure \
	--target=$(GCC_TARGET) --prefix=$(GCC_PREFIX) \
	--disable-nls --disable-libssp --enable-languages=c,c++ --disable-multilib \
	--with-newlib --disable-shared --disable-libaquadmath \
	--with-build-sysroot=$(GCC_PREFIX) \
	; make all-target-libstdc++-v3 -j 24 \
	; sudo make install-target-libstdc++-v3

	touch libstdcpp-$(GCC_VER)-done


#
# EFI
#
gnu-efi: gnu-efi-$(GNU_EFTI_VERSION)-done

gnu-efi-$(GNU_EFTI_VERSION):
	wget https://sourceforge.net/projects/gnu-efi/files/gnu-efi-$(GNU_EFTI_VERSION).tar.bz2
	tar xf gnu-efi-$(GNU_EFTI_VERSION).tar.bz2
	echo "\n\nPATCHING Make.defaults TO REMOVE WARNINGS AS ERRORS SINCE NEW COMPILERS WILL COMPLAIN MORE\n\n"
	patch gnu-efi-$(GNU_EFTI_VERSION)/Make.defaults gnu-efi-remove-werror.patch


gnu-efi-$(GNU_EFTI_VERSION)-done: gnu-efi-$(GNU_EFTI_VERSION)
	mkdir -p gnu-efi-build
	cd gnu-efi-$(GNU_EFTI_VERSION) ; 
		make    \
		CC=$(GCC_PREFIX)/bin/$(GCC_TARGET)-gcc   \
		AS=$(GCC_PREFIX)/bin/$(GCC_TARGET)-as \
		LD=$(GCC_PREFIX)/bin/$(GCC_TARGET)-ld \
		AR=$(GCC_PREFIX)/bin/$(GCC_TARGET)-ar \
		RANLIB=$(GCC_PREFIX)/bin/$(GCC_TARGET)-ranlib   \
		OBJCOPY=$(GCC_PREFIX)/bin/$(GCC_TARGET)-objcopy \
		ARCH=x86_64

	cd gnu-efi-$(GNU_EFTI_VERSION) ; \
		sudo make install \
		PREFIX=$(GCC_PREFIX)

	touch gnu-efi-$(GNU_EFTI_VERSION)-done



