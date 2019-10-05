# ferrite-os
This operating system intends to run the V8 scripting engine on bare metal

Inspiration for OS bringup taken from https://github.com/cfenollosa/os-tutorial

## Plan
1. Create boot-sector and kernel that takes computer to 64 bit mode [DONE]
2. Get V8 building with custom toolchain with no libc to identify missing symbols for memory allocation etc
3. Create LibC to fill in the gaps
4. Real work begins. 


## Method for building V8
- Script checks out V8
- Script chekcs tool dependencies (My "Cross compilers")
- Scripts configures build system to generate binary

## Usefull links
https://gitlab.com/noencoding/OS-X-Chromium-with-proprietary-codecs/wikis/List-of-all-gn-arguments-for-Chromium-build
