set pagination off
file build/kernel.elf
target remote 127.0.0.1:1234
hbreak kernel_main
continue
info registers rip rsp cr0 cr3 cr4 efer
x/4i $rip
