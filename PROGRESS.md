# Noam Kernel progress

## 2026-11-06 — Initial milestone

### Decisions and implementation

- Inspected `DevelopNO/noam-kernel`: it was empty. Added the owner's `AGENTS.md`.
- Created a small C11/Assembly skeleton with Multiboot v1 and explicit load fields.
- Produced an ELF64 file with debug symbols and a separate raw image for QEMU,
  following the preferred approach in `AGENTS.md`.
- Implemented a GDT, BSS clearing, a stack, identity mapping, and transition to
  long mode, followed by UART output from `kernel_main`. Interrupts stay disabled.
- Added Make targets, a bounded boot test, a GDB test, and reproducible setup
  documentation.

### Validation evidence

Verified in Codex Cloud on Linux x86_64 / Debian 13. Build tools were already
installed; QEMU and GDB were extracted from Debian packages into the workspace
using the included script. No host program simulates kernel output.

Verified versions: GCC 14.2.0, binutils 2.44, QEMU 10.0.13, GDB 16.3, and
Python 3.12.14.

- `make all`: passed. `readelf` identifies an x86-64 EXEC with entry `0x100020`
  and debug symbols; `nm -u build/kernel.elf` returns no unresolved symbols.
- `make test`: passed with a real QEMU guest using TCG. The Multiboot header is
  aligned, within the first 8 KiB, and has a valid checksum and address fields.
  Load address: `0x100000`; entry: `0x100020`; BSS end: `0x108000`.
- Guest serial output: `KERNEL_BOOT_OK`. The test has a 10-second limit; the
  marker arrived before the deadline, then the test terminated QEMU. Details
  are saved in `build/boot-result.json` and output in `build/serial.log`.
- `make test-gdb`: passed. GDB stopped at `kernel_main` with `RIP=0x1000e0`,
  `RSP=0x107ff8`, `CR0=0x80000011`, `CR3=0x101000`, `CR4=0x20`, and
  `EFER=0x500`. Verified paging, PAE, active long mode, stack alignment, and
  disabled interrupts. `GDB_ENTRY_OK` was saved in `build/gdb.log`.

### Resolved environment limitations

- Network access inside the sandbox failed to connect to the proxy. Git and APT
  downloads used the same proxy through approved execution outside the sandbox.
- System installation failed because the dpkg lock was inaccessible. Packages
  were downloaded and extracted locally without changing system packages.
- Two downloads returned temporary HTTP 503 errors; retrying succeeded. APT also
  warned about permissions when reading retry configuration and cleaning the
  system cache. Local downloads completed. The setup script records the commands.
- Local extraction required an explicit SeaBIOS path, added to the QEMU wrapper.
- The sandbox blocked local sockets. The GDB test ran through approved execution
  with a loopback-only listener. The initial milestone was verified locally.

### Initial repository publication blocker

Code and instructions were committed locally. `git push -u origin main` failed
with HTTP 403 (`Permission denied`). Creating `AGENTS.md` through the GitHub tool
also failed with `Resource not accessible by integration`. Kernel files and
instructions had not yet reached the remote. User metadata reported push/admin
permissions, but actual integration writes failed. A complete Git bundle was
saved outside the repository.

### Retry after remote README creation

The owner added README commit `5dce7ba`. It was fetched and merged into local
history without removing the remote commit. With the owner's authorization,
the README content was replaced by the complete project documentation. Both
`git push` and GitHub tool creation of `AGENTS.md` still failed with HTTP 403.
Creating an initial remote commit did not resolve the write failure.

### Write access resolved and publication completed

After the owner updated the connection, `git push -u origin main` succeeded.
The remote advanced from `5dce7ba` to `aa3374b`, publishing the kernel,
`AGENTS.md`, tests, and documentation on `main`. Commit `ded30ad` recorded the
resolution. The 403 failures above are historical; the write blocker is resolved.
Kernel code has not changed since the successful tests recorded above.

### Documentation language

The owner requires all project documentation, Markdown files, code comments,
commit messages, PR descriptions, and other repository text to be in English.
Translated README and progress history into English and updated `AGENTS.md` to
make this requirement durable. Checked tracked text for Hebrew characters and
reviewed the documentation diff for whitespace errors. This change affects only
documentation; kernel tests were not rerun.

### Next step

Implement an IDT and one exception handler, then prove in a QEMU test that `int3`
reaches the handler and prints serial diagnostics while external interrupts
remain disabled.
