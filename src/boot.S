/* QEMU's Multiboot v1 loader starts here in 32-bit protected mode. */
.section .multiboot,"a"
.balign 4
.long 0x1badb002
.long 0x00010003
.long -(0x1badb002 + 0x00010003)
.long __image_start
.long __image_start
.long __load_end
.long __bss_end
.long _start

.section .text.boot,"ax"
.code32
.global _start
.type _start, @function
_start:
    cli
    cld
    /* Load known flat segments before accessing memory. */
    lgdt gdt_pointer
    ljmp $0x08, $protected_entry
protected_entry:
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    mov %ax, %fs
    mov %ax, %gs
    xor %eax, %eax
    mov $__bss_start, %edi
    mov $__bss_end, %ecx
    sub %edi, %ecx
    rep stosb
    mov $stack_top, %esp

    /* Identity-map the first GiB with 512 two-MiB pages. */
    mov $pdpt, %eax
    or $3, %eax
    mov %eax, pml4
    mov $page_directory, %eax
    or $3, %eax
    mov %eax, pdpt
    xor %ecx, %ecx
1:
    mov %ecx, %eax
    shl $21, %eax
    or $0x83, %eax
    mov %eax, page_directory(,%ecx,8)
    inc %ecx
    cmp $512, %ecx
    jne 1b

    mov %cr4, %eax
    or $(1 << 5), %eax
    mov %eax, %cr4
    mov $pml4, %eax
    mov %eax, %cr3
    mov $0xc0000080, %ecx
    rdmsr
    or $(1 << 8), %eax
    wrmsr
    mov %cr0, %eax
    or $(1 << 31), %eax
    mov %eax, %cr0
    ljmp $0x18, $long_mode_entry

.code64
long_mode_entry:
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    mov $stack_top, %rsp
    xor %ebp, %ebp
    call kernel_main
2:
    cli
    hlt
    jmp 2b
.size _start, . - _start

.section .rodata
.balign 8
gdt:
    .quad 0
    .quad 0x00cf9a000000ffff /* 32-bit code */
    .quad 0x00cf92000000ffff /* flat data */
    .quad 0x00af9a000000ffff /* 64-bit code */
gdt_end:
gdt_pointer:
    .word gdt_end - gdt - 1
    .long gdt

.section .bss,"aw",@nobits
.balign 4096
pml4: .skip 4096
pdpt: .skip 4096
page_directory: .skip 4096
.balign 16
stack_bottom: .skip 16384
stack_top:
.section .note.GNU-stack,"",@progbits
