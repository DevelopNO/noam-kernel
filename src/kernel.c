#include <stdint.h>

#define COM1 0x3f8

static inline void outb(uint16_t port, uint8_t value)
{
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline uint8_t inb(uint16_t port)
{
    uint8_t value;
    __asm__ volatile ("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

static void serial_init(void)
{
    outb(COM1 + 1, 0x00); /* Disable UART interrupts. */
    outb(COM1 + 3, 0x80); /* Set baud divisor to 1: 115200 baud. */
    outb(COM1 + 0, 0x01);
    outb(COM1 + 1, 0x00);
    outb(COM1 + 3, 0x03); /* Eight data bits, no parity, one stop bit. */
    outb(COM1 + 2, 0xc7);
    outb(COM1 + 4, 0x03);
}

void kernel_main(void)
{
    serial_init();
    const char *message = "KERNEL_BOOT_OK\r\n";
    while (*message) {
        while (!(inb(COM1 + 5) & 0x20)) {
            __asm__ volatile ("pause");
        }
        outb(COM1, (uint8_t)*message++);
    }
    for (;;) {
        __asm__ volatile ("cli; hlt");
    }
}
