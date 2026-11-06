OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)
ENTRY(_start)
SECTIONS
{
    . = 0x100000;
    __image_start = .;
    .multiboot : { KEEP(*(.multiboot)) }
    .text ALIGN(16) : { *(.text.boot) *(.text .text.*) }
    .rodata ALIGN(16) : { *(.rodata .rodata.*) }
    .data ALIGN(16) : { *(.data .data.*) }
    __load_end = .;
    .bss ALIGN(4096) (NOLOAD) : {
        __bss_start = .;
        *(.bss .bss.*) *(COMMON)
        __bss_end = .;
    }
    /DISCARD/ : { *(.eh_frame*) *(.note*) *(.comment*) }
}
