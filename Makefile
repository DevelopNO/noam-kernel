CC := gcc
LD := ld
OBJCOPY := objcopy
QEMU ?= qemu-system-x86_64
GDB ?= gdb
PYTHON ?= python3
CFLAGS := -std=c11 -O2 -g -Wall -Wextra -Werror -ffreestanding -fno-pie -fno-stack-protector -fno-asynchronous-unwind-tables -m64 -mno-red-zone -mgeneral-regs-only
QEMU_FLAGS := -machine pc,accel=tcg -cpu qemu64 -smp 1 -m 64M -display none -monitor none -serial stdio -nic none -no-reboot -no-shutdown -kernel build/kernel.bin

.PHONY: all run test test-gdb debug clean
all: build/kernel.bin
build:
	mkdir -p $@
build/boot.o: src/boot.S | build
	$(CC) -m64 -g -fno-pie -c $< -o $@
build/kernel.o: src/kernel.c | build
	$(CC) $(CFLAGS) -c $< -o $@
build/kernel.elf: build/boot.o build/kernel.o linker.ld
	$(LD) -nostdlib -z max-page-size=0x1000 -T linker.ld -o $@ build/boot.o build/kernel.o
build/kernel.bin: build/kernel.elf
	$(OBJCOPY) -O binary $< $@
run: all
	$(QEMU) $(QEMU_FLAGS)
test: all
	$(PYTHON) tests/boot_test.py --qemu $(QEMU)
test-gdb: all
	$(PYTHON) tests/gdb_test.py --qemu $(QEMU) --gdb $(GDB)
debug: all
	@echo 'In another terminal: $(GDB) -x debug.gdb'
	$(QEMU) $(QEMU_FLAGS) -S -gdb tcp:127.0.0.1:1234
clean:
	rm -rf build
