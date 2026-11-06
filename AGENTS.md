# Noam Kernel — project instructions

## Goal

Build an educational operating-system kernel from scratch. The owner, Noam,
confirmed this direction on 2026-11-01. All project documentation, Markdown
files, source comments, commit messages, PR descriptions, and other repository
text must be in English only. Use readable English identifiers in source code.

## Development environment

Develop and test in Codex Cloud on Linux x86_64. The kernel target is x86_64.
Use C11 and a small amount of GNU Assembly, GNU Make, binutils, QEMU and GDB.
Use Python 3 for integration-test orchestration.

First inspect the repository and available tools. Install missing dependencies
through the supported environment setup, and record reproducible commands.
Typical Ubuntu dependencies are build-essential, binutils, qemu-system-x86,
gdb and python3. Report concrete installation failures with their causes.

Use QEMU software emulation (TCG), so KVM and nested virtualization are optional.
Run headlessly with serial output and networking disabled. Keep any GDB listener
bound to loopback. Do not attach host disks or personal directories to the guest.

## Initial milestone

Deliver a minimal kernel with all of the following working end to end.

1. A documented build creates a bootable image and an ELF with debug symbols.
2. QEMU loads the image and enters our kernel.
3. Our startup code establishes a stack, clears BSS and enters 64-bit mode.
4. A C entry point initializes the serial port and prints KERNEL_BOOT_OK.
5. A bounded automated test boots the real guest and checks its serial output.
6. GDB can stop at the C entry point and inspect registers.

Provide make targets named all, run, test, debug and clean. Preserve useful
existing targets if the repository already has them.

For the first milestone, prefer a Multiboot v1 image with explicit load-address
fields and a 32-bit entry trampoline that switches to long mode. A raw image
can be paired with an ELF debug file. Verify actual QEMU loader compatibility.
If a different boot protocol is needed, document the reason and its contract.

Compile freestanding, without host libc, PIE, the stack protector or the red zone.
Avoid compiler-generated floating-point/SIMD instructions until the relevant CPU
state is initialized. Make linker layout and the entry point explicit.

## Verification and reporting

Run the normal build and actual QEMU boot test. Keep the timeout, guest serial
log and exit/failure information. Validate image headers and unresolved symbols.
Exercise the GDB workflow when the environment permits it.

A successful compile establishes only that the code builds. Report separately
whether boot, the serial marker, the integration test and GDB were verified.
Do not fabricate output or use a host program that prints the success marker
as a substitute for guest execution.

## Learning workflow

Implement one milestone at a time. Keep code small, readable and easy to debug.
Explain the path from the loader to the C entry point and why each component is
needed. Noam is an experienced backend engineer and OS lecturer who wants hands-on
kernel-development experience.

After the initial milestone, proceed to exception handling and IDT, physical and
virtual memory management, scheduling, user mode and syscalls, then a small ramfs
and shell. Keep hardware interrupts disabled until handlers are installed.
Start with one CPU. Defer networking, USB and graphics until the foundations work.

## Durable progress

Maintain README.md with build, run, test and debug instructions.
Maintain PROGRESS.md with dates, completed work, validation evidence, blockers
and exactly one concrete next step. Distinguish proposals from decisions and
verified execution. Commit coherent changes in the connected repository, and
include meaningful validation in change summaries.

## Handoff status on 2026-11-06

The owner chose cloud development. Another conversation produced a small C/Assembly
prototype that compiled, but its QEMU boot and GDB workflow were not verified.
Those source files may not be present in this repository. Inspect the repository
before deciding whether to reuse code or implement the initial skeleton.

This kernel is a separate project from Noam's security sensor, which is planned
around Linux, Go and C/eBPF. Keep sensor implementation in its own repository.
