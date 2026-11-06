# Noam Kernel

An educational x86_64 kernel written in C11 and GNU Assembly. The first milestone
is implemented: Multiboot v1 loading, entry into 64-bit mode, and printing
`KERNEL_BOOT_OK` from the kernel.

## Development environment and build

Use Linux x86_64 with GCC, binutils, GNU Make, Python 3, QEMU, and GDB.
On Debian/Ubuntu with permission to install system packages:

```sh
sudo apt-get update
sudo apt-get install --no-install-recommends build-essential binutils qemu-system-x86 gdb python3
make all
make test
make test-gdb
```

In the current cloud environment, the compiler is already installed and root
access is unavailable. The following script downloads Debian/Ubuntu packages
from the configured repositories, extracts them locally, and creates wrappers
with library and firmware paths. It does not install system packages. It assumes
the machine already has build tools and their basic dependencies.

```sh
sh scripts/setup-local-tools.sh
export PATH="$PWD/.local-tools/bin:$PATH"
make all
make test
make test-gdb
```

The script accepts an alternative directory. The verified setup used
`sh scripts/setup-local-tools.sh /workspace/kernel-tools`, followed by adding
`/workspace/kernel-tools/bin` to `PATH`. Package downloads require network access.
Rerun the script after a temporary download failure; downloaded archives remain
cached.

## Artifacts and commands

| Command | Result |
| --- | --- |
| `make all` | Loadable `build/kernel.bin` and `build/kernel.elf` with debug symbols |
| `make run` | QEMU with serial output in the terminal; press Ctrl-C to stop |
| `make test` | Header and symbol validation, followed by a real guest boot with a 10-second limit |
| `make test-gdb` | Stop at `kernel_main` and verify registers, long mode, and stack alignment |
| `make debug` | Paused QEMU with GDB listening on `127.0.0.1:1234` |
| `make clean` | Remove the build directory |

Override `QEMU`, `GDB`, and `PYTHON` through Make as needed. Run tests from the
repository root. The boot test saves `build/serial.log`, `build/qemu.stderr.log`,
and `build/boot-result.json`, which records the timeout, exit code, and termination
information. The kernel halts with `hlt` after printing; the test terminates QEMU
after observing the marker. The exit code alone does not establish boot success.

The GDB test uses an available loopback port and saves `build/gdb.log` and
`build/gdb-qemu.stderr.log`. It is bounded and cleans up QEMU even on failure.
A sandbox that blocks local sockets must allow this test to run.

For manual debugging, use two terminals:

```sh
# Terminal 1
make debug
# Terminal 2, from the repository root
gdb -x debug.gdb
```

GDB stops at the C entry point and displays registers and the next instructions.
Use `continue` to let the kernel print. `hbreak` sets a breakpoint before firmware
loads the kernel into memory.

## Boot path

1. QEMU loads `kernel.bin` through `-kernel`. Its Multiboot v1 header sets flag
   `0x10000` and explicit address fields: load address `0x100000`, end of file
   contents, end of BSS, and entry address. This raw image is for direct loading,
   rather than an ISO or disk image. Compatibility with this QEMU loader has
   been verified by executing the guest.
2. `src/boot.S` starts in 32-bit mode with interrupts disabled, loads a GDT and
   flat segments, clears BSS, and establishes a stack. `linker.ld` explicitly
   defines the memory layout and entry point.
3. Startup code builds page tables in cleared memory and identity-maps the first
   GiB with 2 MiB pages. After enabling PAE, loading CR3, setting EFER.LME, and
   enabling paging, a far jump selects a 64-bit code segment.
4. Startup code establishes a 16 KiB stack aligned according to the ABI and calls
   `kernel_main`. C code initializes the COM1 16550 UART to 115200 baud and prints
   the marker. The CPU then waits with interrupts disabled until exception
   handling and an IDT are implemented.

The initial target is one QEMU `qemu64` CPU with long mode, PAE, and large pages
available. There is no CPUID capability detection or guarantee of booting on
arbitrary hardware yet. Multiboot boot information is not consumed yet.

Compilation is freestanding, without libc, PIE, the stack protector, or the red
zone. `-mgeneral-regs-only` prevents compiler-generated SIMD/floating-point
instructions before the required CPU state is initialized. QEMU uses TCG with
networking disabled and no host disks or directories attached. KVM is optional.

See [PROGRESS.md](PROGRESS.md) for validation evidence and the next step.
