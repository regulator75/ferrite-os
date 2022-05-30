

include ../Make.defaults


ABSOLUTE_GCC_PREFIX = $(shell realpath -m $(GCC_PREFIX))
ABSOLUTE_GCC_SYSROOT = $(shell realpath -m $(GCC_SYSROOT))

#
# BINUTILS
#

BINUTILS_SRC_LOCATION ?= .
BINUTILS_SRC_LOCATION := $(shell realpath  $(BINUTILS_SRC_LOCATION) )

all: binutils gcc1 newlib gcc2 
#Not supported wiht updated sysroot currently
# gdb libunwind libstdcpp gnu-efi

downloads: binutils-$(BINUTILS_VERSION) gcc-$(GCC_VER) gdb-$(GDB_VER) newlib-$(NEWLIB_VERSION) libunwind-$(LLVM_LIBUNWIND_VERSION).src gnu-efi-$(GNU_EFTI_VERSION)


cleanbuilds:
	rm -rf binutils-build
	rm -rf gcc-build
	rm -rf newlib-build
	rm -rf gdb-build
	rm -rf libunwind-build
	rm -rf gnu-efi-build
	rm -rf autoconf-build
	rm -rf automake-build


## If BINUTILS_BUILD_SOURCE is not set, download and patch the correct version. Otherwise just build with the build source.


binutils: binutils-$(BINUTILS_VERSION)-done

binutils-$(BINUTILS_VERSION).tar.gz:
	curl -O https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.gz

binutils-$(BINUTILS_VERSION)-patched: binutils-$(BINUTILS_VERSION).tar.gz
	tar xf binutils-$(BINUTILS_VERSION).tar.gz
	mv binutils-$(BINUTILS_VERSION) binutils-$(BINUTILS_VERSION)-orig
	patch ./binutils-$(BINUTILS_VERSION)-orig/config.sub          binutils-$(BINUTILS_VERSION)_config_sub.patch    
	patch ./binutils-$(BINUTILS_VERSION)-orig/bfd/config.bfd      binutils-$(BINUTILS_VERSION)_bfd_config_bfd.patch   
	patch ./binutils-$(BINUTILS_VERSION)-orig/ld/configure.tgt    binutils-$(BINUTILS_VERSION)_ld_configure_tgt.patch 
	patch ./binutils-$(BINUTILS_VERSION)-orig/gas/configure.tgt   binutils-$(BINUTILS_VERSION)_gas_configure_tgt.patch
	patch ./binutils-$(BINUTILS_VERSION)-orig/ld/emulparams/elf_i386_ferrite.sh    binutils-$(BINUTILS_VERSION)_ld_emulparams_elf_i366_ferrite_sh.patch
	patch ./binutils-$(BINUTILS_VERSION)-orig/ld/emulparams/elf_x86_64_ferrite.sh  binutils-$(BINUTILS_VERSION)_ld_emulparams_elf_x86_64_ferrite_sh.patch
	patch ./binutils-$(BINUTILS_VERSION)-orig/ld/Makefile.am                       binutils-$(BINUTILS_VERSION)_ld_Makefile_am.patch

	cd ./binutils-$(BINUTILS_VERSION)-orig/ld \
	; aclocal \
	; automake

	mv -T binutils-$(BINUTILS_VERSION)-orig binutils-$(BINUTILS_VERSION)-patched
	touch binutils-$(BINUTILS_VERSION)-patched



BINUTILS_BUILD_SOURCE ?= binutils-$(BINUTILS_VERSION)-patched
BINUTILS_BUILD_SOURCE_ABSOLUTE := $(shell realpath $(BINUTILS_BUILD_SOURCE))
binutils-$(BINUTILS_VERSION)-done: $(BINUTILS_BUILD_SOURCE)
	mkdir -p binutils-build
	mkdir -p $(ABSOLUTE_GCC_PREFIX)
	cd binutils-build \
	; $(BINUTILS_BUILD_SOURCE_ABSOLUTE)/configure \
		--target=$(GCC_TARGET) \
		--prefix=$(ABSOLUTE_GCC_PREFIX) \
		--enable-interwork \
		--disable-multilib \
		--disable-nls \
		--disable-werror
#		--with-sysroot=$(ABSOLUTE_GCC_SYSROOT) 
	make -C binutils-build all -j 24
	make -C binutils-build install

	touch binutils-$(BINUTILS_VERSION)-done



#
# GCC
#

GCC_SRC_LOCATION ?= .
GCC_SRC_LOCATION := $(shell realpath $(GCC_SRC_LOCATION) )

gcc1: gcc-$(GCC_VER)-done-1st

gcc-$(GCC_VER).tar.gz:
	curl -O https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VER)/gcc-$(GCC_VER).tar.gz 

gcc-$(GCC_VER)-patched: gcc-$(GCC_VER).tar.gz
# Ideally this should be in a separate target
	tar xf gcc-$(GCC_VER).tar.gz
	cd gcc-$(GCC_VER) ; ./contrib/download_prerequisites

	mv gcc-$(GCC_VER) gcc-$(GCC_VER)-orig
	patch ./gcc-$(GCC_VER)-orig/config.sub                   gcc-$(GCC_VER)_config_sub.patch
	patch ./gcc-$(GCC_VER)-orig/gcc/config.gcc               gcc-$(GCC_VER)_gcc_config_gcc.patch
	patch ./gcc-$(GCC_VER)-orig/gcc/config/ferrite.h         gcc-$(GCC_VER)_gcc_config_ferrite_h.patch
	patch ./gcc-$(GCC_VER)-orig/libstdc++-v3/crossconfig.m4  gcc-$(GCC_VER)_libstdcpp-v3_crossconfig_m4.patch
	patch ./gcc-$(GCC_VER)-orig/libgcc/config.host           gcc-$(GCC_VER)_libgcc_config_host.patch
	patch ./gcc-$(GCC_VER)-orig/fixincludes/mkfixinc.sh      gcc-$(GCC_VER)_fixincludes_mkfixinc_sh.patch
	patch ./gcc-$(GCC_VER)-orig/config/ferrite_os.mk         gcc-$(GCC_VER)_config_ferrite_os_mk.patch	

	cd ./gcc-$(GCC_VER)-orig/mpfr \
	; aclocal \
	; automake

	cd ./gcc-$(GCC_VER)-orig/isl \
	; aclocal \
	; automake

	cd ./gcc-$(GCC_VER)-orig/libstdc++-v3 \
	; aclocal \
	; automake

	mv -T gcc-$(GCC_VER)-orig gcc-$(GCC_VER)-patched

GCC_BUILD_SOURCE ?= gcc-$(GCC_VER)-patched
GCC_BUILD_SOURCE_ABSOLUTE = $(shell realpath $(GCC_BUILD_SOURCE))
gcc-$(GCC_VER)-done-1st: $(GCC_BUILD_SOURCE) binutils-$(BINUTILS_VERSION)-done
	mkdir -p gcc-build
	cd gcc-build \
	; $(GCC_BUILD_SOURCE_ABSOLUTE)/configure \
		--target=$(GCC_TARGET) \
		--prefix=$(ABSOLUTE_GCC_PREFIX) \
		--disable-nls \
		--disable-libssp \
		--enable-languages=c \
		--disable-multilib \
		--disable-libaquadmath \
		--disable-shared \
		--without-headers \
		--with-build-config=ferrite_os
#		--with-sysroot=$(ABSOLUTE_GCC_SYSROOT)

#		--enable-threads=posix \
#prepare folder structure in sysroot. Seems to be needed
#if its a fresh build
	mkdir -p $(ABSOLUTE_GCC_SYSROOT)/usr
	mkdir -p $(ABSOLUTE_GCC_SYSROOT)/usr/include


	make -C gcc-build all-gcc -j 24
	make -C gcc-build install-gcc

	touch gcc-$(GCC_VER)-done-1st


gcc2:gcc-$(GCC_VER)-done-2nd

gcc-$(GCC_VER)-done-2nd: gcc-$(GCC_VER)-done-1st newlib-$(NEWLIB_VERSION)-done
	mkdir -p gcc-build
	cd gcc-build \
	; $(GCC_BUILD_SOURCE_ABSOLUTE)/configure \
		--target=$(GCC_TARGET) \
		--prefix=$(ABSOLUTE_GCC_PREFIX) \
		--disable-nls \
		--disable-libssp \
		--enable-languages=c,c++ \
		--disable-multilib \
		--disable-libaquadmath \
		--disable-shared \
		--with-build-config=ferrite_os \
		--with-as=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-as \
		--with-ld=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-ld \
		--with-build-time-tools=$(ABSOLUTE_GCC_PREFIX)/$(GCC_TARGET)/bin/ \
		--with-newlib 
#		--with-sysroot=$(ABSOLUTE_GCC_SYSROOT)
#		--enable-threads=posix \


	make -C gcc-build all-gcc -j 24
	make -C gcc-build install-gcc	
	#make -C gcc-build all-target-libgcc -j 24
	#make -C gcc-build install-target-libgcc



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
	cd gdb-build \
	; ../gdb-$(GDB_VER)/configure \
		--target=$(GCC_TARGET) \
		--prefix=$(ABSOLUTE_GCC_PREFIX) \
		--with-python=/usr/bin/python3 \
		--host=x86_64-linux-gnu 
#		--with-sysroot=$(ABSOLUTE_GCC_SYSROOT)
	make -C gdb-build -j 24
	make -C gdb-build install

	touch gdb-$(GDB_VER)-done



#
# CRT
#

# This section builds crt0.o and installs it
crt: $(ABSOLUTE_GCC_PREFIX)/$(GCC_TARGET)/lib/crt0.o

$(ABSOLUTE_GCC_PREFIX)/$(GCC_TARGET)/lib/crt0.o: ../crt0.s
	$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-as ../crt0.s -o crt0.o
	cp crt0.o $@


#
# NEWLIB
#

NEWLIB_SRC_LOCATION ?= newlib-$(NEWLIB_VERSION)-patched

newlib: newlib-$(NEWLIB_VERSION)-done

newlib-$(NEWLIB_VERSION).tar.gz:
	curl -O ftp://sourceware.org/pub/newlib/newlib-$(NEWLIB_VERSION).tar.gz


newlib-$(NEWLIB_VERSION)-patched: newlib-$(NEWLIB_VERSION).tar.gz autotools-bin/bin/automake autotools-bin/bin/autoconf
	tar xf newlib-$(NEWLIB_VERSION).tar.gz
	mv newlib-$(NEWLIB_VERSION) newlib-$(NEWLIB_VERSION)-orig
	patch ./newlib-$(NEWLIB_VERSION)-orig/config.sub                           newlib-$(NEWLIB_VERSION)_config_sub.patch                  
	patch ./newlib-$(NEWLIB_VERSION)-orig/newlib/configure.host                newlib-$(NEWLIB_VERSION)_newlib_configure_hostg.patch      
	patch ./newlib-$(NEWLIB_VERSION)-orig/newlib/libc/sys/configure.in         newlib-$(NEWLIB_VERSION)_newlib_libc_sys_configure_in.patch
###	entire folder requires different patch method. -p2 strips two levels of folders from input patch and applies relative to current folder.
	cd ./newlib-$(NEWLIB_VERSION)-orig/   ;  patch -p2 < ../newlib-3.3.0_newlib_libc_sys_ferrite.patch

# Run the special versions of autoconf and automake. stick in in a sh so the path dont leak
	sh -e -c "PATH=$(shell realpath ./ )/autotools-bin/bin:$(PATH) ; cd $(shell realpath ./ )/newlib-3.3.0-orig/newlib/libc/sys ; autoconf"
	sh -e -c "PATH=$(shell realpath ./ )/autotools-bin/bin:$(PATH) ; cd $(shell realpath ./ )/newlib-3.3.0-orig/newlib/libc/sys/ferrite ; autoreconf"

	mv newlib-$(NEWLIB_VERSION)-orig newlib-$(NEWLIB_VERSION)-patched



newlib-$(NEWLIB_VERSION)-done: $(NEWLIB_SRC_LOCATION) gcc-$(GCC_VER)-done-1st binutils-$(BINUTILS_VERSION)-done
	mkdir -p newlib-build
	cd newlib-build \
	; $(shell realpath $(NEWLIB_SRC_LOCATION) )/configure \
		--target=$(GCC_TARGET) \
		--prefix=$(ABSOLUTE_GCC_PREFIX) \
		--exec_prefix=$(ABSOLUTE_GCC_PREFIX)\
		CC_FOR_TARGET=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-gcc \
		CXX_FOR_TARGET=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-g++ \
		LD_FOR_TARGET=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-ld \
		AS_FOR_TARGET=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-gcc-as \
		NM_FOR_TARGET=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-gcc-nm \
		AR_FOR_TARGET=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-ar \
		RANLIB_FOR_TARGET=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-ranlib \
		OBJDUMP_FOR_TARGET=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-objdump
	make -C newlib-build all -j 24
	make -C newlib-build install 

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

# Setting _POSIX_THREADS is needed so that pthread from newlib
# exposes the right stuff.
libunwind-$(LLVM_LIBUNWIND_VERSION)-done: libunwind-$(LLVM_LIBUNWIND_VERSION).src
	mkdir -p libunwind-build/
	cd libunwind-build \
	; cmake -G "Unix Makefiles" ../libunwind-$(LLVM_LIBUNWIND_VERSION).src/ \
		-DLIBUNWIND_ENABLE_STATIC=ON \
		-DLIBUNWIND_ENABLE_SHARED=OFF \
		-DCMAKE_CXX_COMPILER=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-g++ \
		-DCMAKE_ASM_COMPILER=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-as \
		-DCMAKE_INSTALL_PREFIX=$(ABSOLUTE_GCC_PREFIX)/$(GCC_TARGET) \
		-DCMAKE_CXX_FLAGS="--verbose -D_LIBUNWIND_IS_BAREMETAL=1 -D_POSIX_THREADS=1" \
		-DLIBUNWIND_ENABLE_THREADS=ON 
	make -C libunwind-build
	make -C libunwind-build install-unwind



#
# libstdc++
#
libstdcpp: libstdcpp-$(GCC_VER)-done

libstdcpp-$(GCC_VER)-done: gcc-$(GCC_VER)-done-2nd
	#mkdir -p toolbuild/gcc-build-libstdcpp
	#cp -a toolbuild/gcc-build/. toolbuild/gcc-build-libstdcpp
	cd gcc-build \
	; make distclean \
	; $(GCC_SRC_LOCATION)/gcc-$(GCC_VER)/configure \
		--target=$(GCC_TARGET) \
		--prefix=$(ABSOLUTE_GCC_PREFIX) \
		--disable-nls \
		--disable-libssp \
		--enable-languages=c,c++ \
		--disable-multilib \
		--with-newlib \
		--disable-shared \
		--disable-libaquadmath \
		--enable-threads=posix \
		--with-build-sysroot=$(ABSOLUTE_GCC_PREFIX) \
		--with-build-config=ferrite_os \
		--with-build-time-tools=$(ABSOLUTE_GCC_PREFIX)/$(GCC_TARGET)/bin/
#		--with-sysroot=$(ABSOLUTE_GCC_SYSROOT)

	make -C gcc-build all-target-libstdc++-v3 -j 24
	make -C gcc-build install-target-libstdc++-v3

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
	make -C gnu-efi-$(GNU_EFTI_VERSION)   \
		CC=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-gcc   \
		AS=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-as \
		LD=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-ld \
		AR=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-ar \
		RANLIB=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-ranlib   \
		OBJCOPY=$(ABSOLUTE_GCC_PREFIX)/bin/$(GCC_TARGET)-objcopy \
		ARCH=x86_64

	
	make -C gnu-efi-$(GNU_EFTI_VERSION) PREFIX=$(ABSOLUTE_GCC_PREFIX) install 

	touch gnu-efi-$(GNU_EFTI_VERSION)-done



#
# Automake 1.11 EXACT VERSION BECUASE NEWLIB REQUIRES CYGWIN STYLE AND ITS ONLY AVALIABLE IN OLDER VERSIONS
# Autoconf
#
GNU_AUTOMAKE_VERSION := 1.11.6
automake: automake-$(GNU_AUTOMAKE_VERSION)-done
autotools-bin/bin/automake : automake-$(GNU_AUTOMAKE_VERSION)-done

automake-$(GNU_AUTOMAKE_VERSION).tar.xz:
	wget https://ftp.gnu.org/gnu/automake/automake-$(GNU_AUTOMAKE_VERSION).tar.xz

automake-$(GNU_AUTOMAKE_VERSION)-done: automake-$(GNU_AUTOMAKE_VERSION).tar.xz
	tar xf automake-$(GNU_AUTOMAKE_VERSION).tar.xz
	mkdir -p automake-build
	cd automake-build \
	; ../automake-$(GNU_AUTOMAKE_VERSION)/configure --prefix $(shell realpath -m autotools-bin ) \
	; make \
	; make install 
	touch automake-$(GNU_AUTOMAKE_VERSION)-done


GNU_AUTOCONF_VERSION := 2.67
autoconf: autoconf-$(GNU_AUTOCONF_VERSION)-done
autotools-bin/bin/autoconf: autoconf-$(GNU_AUTOCONF_VERSION)-done
autoconf-$(GNU_AUTOCONF_VERSION).tar.xz:
	wget https://ftp.gnu.org/gnu/autoconf/autoconf-$(GNU_AUTOCONF_VERSION).tar.xz

# 
# The mkdir at the end is to avoid a weird error mesage for aclocal while running autoreconf for newlib. 
# https://wiki.osdev.org/Porting_Newlib
# https://stackoverflow.com/questions/40119977/autoreconf-ignores-ac-config-macro-dir
autoconf-$(GNU_AUTOCONF_VERSION)-done: autoconf-$(GNU_AUTOCONF_VERSION).tar.xz
	tar xf autoconf-$(GNU_AUTOCONF_VERSION).tar.xz
	mkdir -p autoconf-build
	cd autoconf-build \
	; ../autoconf-$(GNU_AUTOCONF_VERSION)/configure --prefix $(shell realpath -m autotools-bin/ ) \
	; make \
	; make install
	mkdir -p autotools-bin/share/aclocal
	touch autoconf-$(GNU_AUTOCONF_VERSION)-done

# Assume downloaded original is in X and modified version is in DEV
#
# GCC_MODIFIED_SRC this is where the source for the GCC tools that you have modified are.
# GCC_ORIGINAL_SRC this is the plain unpacked folder from the downloaded files from the internetz
# This target will generate the neccesary patches so that others can download the original source
# and re-create the GCC tools that you have just tinkered with on your machine.
# The arget cherry picks files to avoid pulling in Autoconf et al crap.
GCC_MODIFIED_SRC ?= NOT_SET_DONT_EXIST
GCC_ORIGINAL_SRC ?= NOT_SET_DONT_EXIST
GCC_MODIFIED_SRC := $(shell realpath $(GCC_MODIFIED_SRC) )
GCC_ORIGINAL_SRC := $(shell realpath $(GCC_ORIGINAL_SRC) )

# Patch work inspired by https://wiki.osdev.org/OS_Specific_Toolchain#ld.2Femulparams.2Felf_i386_myos.sh
gcc-dev-make-patches: gcc-dev-make-patches-binutils gcc-dev-make-patches-gcc gcc-dev-make-patches-newlib



gcc-dev-make-patches-binutils:
	echo "Creating patch assuming modified code is in " $(GCC_MODIFIED_SRC) " and original is in " $(GCC_ORIGINAL_SRC)
#binutils
	diff -Naur $(GCC_ORIGINAL_SRC)/binutils-$(BINUTILS_VERSION)/config.sub        $(GCC_MODIFIED_SRC)/binutils-$(BINUTILS_VERSION)/config.sub        > binutils-$(BINUTILS_VERSION)_config_sub.patch         ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/binutils-$(BINUTILS_VERSION)/bfd/config.bfd    $(GCC_MODIFIED_SRC)/binutils-$(BINUTILS_VERSION)/bfd/config.bfd    > binutils-$(BINUTILS_VERSION)_bfd_config_bfd.patch     ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/binutils-$(BINUTILS_VERSION)/ld/configure.tgt  $(GCC_MODIFIED_SRC)/binutils-$(BINUTILS_VERSION)/ld/configure.tgt  > binutils-$(BINUTILS_VERSION)_ld_configure_tgt.patch   ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/binutils-$(BINUTILS_VERSION)/gas/configure.tgt $(GCC_MODIFIED_SRC)/binutils-$(BINUTILS_VERSION)/gas/configure.tgt > binutils-$(BINUTILS_VERSION)_gas_configure_tgt.patch  ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/binutils-$(BINUTILS_VERSION)/ld/emulparams/elf_i386_ferrite.sh     $(GCC_MODIFIED_SRC)/binutils-$(BINUTILS_VERSION)/ld/emulparams/elf_i386_ferrite.sh     > binutils-$(BINUTILS_VERSION)_ld_emulparams_elf_i366_ferrite_sh.patch     ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/binutils-$(BINUTILS_VERSION)/ld/emulparams/elf_x86_64_ferrite.sh   $(GCC_MODIFIED_SRC)/binutils-$(BINUTILS_VERSION)/ld/emulparams/elf_x86_64_ferrite.sh   > binutils-$(BINUTILS_VERSION)_ld_emulparams_elf_x86_64_ferrite_sh.patch   ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/binutils-$(BINUTILS_VERSION)/ld/Makefile.am                        $(GCC_MODIFIED_SRC)/binutils-$(BINUTILS_VERSION)/ld/Makefile.am                        > binutils-$(BINUTILS_VERSION)_ld_Makefile_am.patch                        ; [ $$? -eq 1 ]

gcc-dev-make-patches-gcc:
#gcc	
	diff -Naur $(GCC_ORIGINAL_SRC)/gcc-$(GCC_VER)/config.sub                   $(GCC_MODIFIED_SRC)/gcc-$(GCC_VER)/config.sub                   > gcc-$(GCC_VER)_config_sub.patch                  ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/gcc-$(GCC_VER)/gcc/config.gcc               $(GCC_MODIFIED_SRC)/gcc-$(GCC_VER)/gcc/config.gcc               > gcc-$(GCC_VER)_gcc_config_gcc.patch              ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/gcc-$(GCC_VER)/gcc/config/ferrite.h         $(GCC_MODIFIED_SRC)/gcc-$(GCC_VER)/gcc/config/ferrite.h         > gcc-$(GCC_VER)_gcc_config_ferrite_h.patch        ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/gcc-$(GCC_VER)/libstdc++-v3/crossconfig.m4  $(GCC_MODIFIED_SRC)/gcc-$(GCC_VER)/libstdc++-v3/crossconfig.m4  > gcc-$(GCC_VER)_libstdcpp-v3_crossconfig_m4.patch ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/gcc-$(GCC_VER)/libgcc/config.host           $(GCC_MODIFIED_SRC)/gcc-$(GCC_VER)/libgcc/config.host           > gcc-$(GCC_VER)_libgcc_config_host.patch          ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/gcc-$(GCC_VER)/fixincludes/mkfixinc.sh      $(GCC_MODIFIED_SRC)/gcc-$(GCC_VER)/fixincludes/mkfixinc.sh      > gcc-$(GCC_VER)_fixincludes_mkfixinc_sh.patch     ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/gcc-$(GCC_VER)/config/ferrite_os.mk         $(GCC_MODIFIED_SRC)/gcc-$(GCC_VER)/config/ferrite_os.mk         > gcc-$(GCC_VER)_config_ferrite_os_mk.patch     ; [ $$? -eq 1 ]
	
gcc-dev-make-patches-newlib:
#gcc	
	diff -Naur $(GCC_ORIGINAL_SRC)/newlib-$(NEWLIB_VERSION)/config.sub                   $(GCC_MODIFIED_SRC)/newlib-$(NEWLIB_VERSION)/config.sub                   > newlib-$(NEWLIB_VERSION)_config_sub.patch                    ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/newlib-$(NEWLIB_VERSION)/newlib/configure.host        $(GCC_MODIFIED_SRC)/newlib-$(NEWLIB_VERSION)/newlib/configure.host        > newlib-$(NEWLIB_VERSION)_newlib_configure_hostg.patch        ; [ $$? -eq 1 ]
	diff -Naur $(GCC_ORIGINAL_SRC)/newlib-$(NEWLIB_VERSION)/newlib/libc/sys/configure.in $(GCC_MODIFIED_SRC)/newlib-$(NEWLIB_VERSION)/newlib/libc/sys/configure.in > newlib-$(NEWLIB_VERSION)_newlib_libc_sys_configure_in.patch  ; [ $$? -eq 1 ]
# All relevatn files in the sys/ferrite folder
	diff -Naur -x aclocal.m4 -x autom4te.cache -x Makefile.in -x configure $(GCC_ORIGINAL_SRC)/newlib-$(NEWLIB_VERSION)/newlib/libc/sys/ferrite/     $(GCC_MODIFIED_SRC)/newlib-$(NEWLIB_VERSION)/newlib/libc/sys/ferrite/     > newlib-$(NEWLIB_VERSION)_newlib_libc_sys_ferrite.patch       ; [ $$? -eq 1 ]




