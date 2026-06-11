llvm-rc /c 65001 resources.rc
clang -O3 -nostdlib -Xlinker /SUBSYSTEM:WINDOWS -lkernel32.lib -luser32.lib -o langswitch.exe langswitch.c resources.res