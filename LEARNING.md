# Kernel learning path

## Starting point

The working implementation and its reported validation are described in
README.md and PROGRESS.md. Existing tests exercise boot and GDB entry.
The owner has not yet run the project or worked through its mechanisms.
No lesson below is marked understood.

The learning objective is to reconstruct the system in explainable steps.
Keep a verified reference and compare each experiment against it.

## Lesson record

For each lesson record the baseline commit, experiment commit, commands,
prediction, observed result, explanation in the owner's own words, open
questions, and one next exercise. Use separate fields for "execution verified"
and "understanding confirmed". Only the owner can confirm understanding.

At the start, record the full reference commit and preserve it with the
checkpoint/boot-reference tag. Create lesson branches from an explicit commit.
Use GitHub's file diffs and commit comparisons to inspect every small change.
Use a detached checkout or a separate worktree when revisiting a checkpoint.

## Lessons

| Lesson | Mechanism | Observable exercise |
| --- | --- | --- |
| 00 | Build, artifacts, and the loader | Run the existing boot test. Identify the command that launches QEMU, the image it loads, and where the observed output is stored. |
| 01 | C code and serial I/O | Trace the message from kernel_main through outb to QEMU serial output. Predict what changing the message does to the current marker-based test, then try it in an experiment branch. |
| 02 | ELF, raw image, and linker layout | Compare readelf and objdump output with linker.ld. Find the entry address and explain why raw bytes need a loading contract. |
| 03 | Multiboot entry and assembly | Trace the header and _start. Inspect 32-bit disassembly and the GDT/segment setup. Identify the state supplied by QEMU's loader and the state established by our code. |
| 04 | BSS, stack, and the C calling convention | Inspect stack alignment at kernel_main in GDB. Explain what call pushes and why memory reserved for a stack needs an initial stack pointer. |
| 05 | Page-table construction | Decode the PML4, PDPT and large-page entries. Explain the shifts, flags and identity mapping, then inspect the actual entries in GDB. |
| 06 | Transition to long mode | Step through CR4, CR3, EFER, CR0 and the far jump. Predict which state changes at each step and compare with register values. |
| 07 | Guided reconstruction | Start a separate learning branch/workspace. Rebuild the milestone using understood components, with an explicitly described bootstrap scaffold where needed. |
| 08 | First exception | After the owner confirms the bootstrap lessons, add IDT handling for int3 and prove the handler ran using serial diagnostics and a bounded QEMU test. |

Later lessons cover physical allocation, virtual memory, scheduling, user mode,
syscalls, ramfs and a small shell. Revise the pace based on demonstrated
understanding.

## First session

Focus on lesson 00 and the beginning of lesson 01.

1. Read the existing Makefile and identify the build/run/test entry points.
2. Run make all and make test in the configured cloud environment.
3. Inspect src/kernel.c. Follow kernel_main, serial_init, inb and outb.
4. Explain why this program writes a device port instead of calling printf.
5. Predict what happens to the test if only the printed marker changes.
6. Perform that change in an experiment branch when the owner is ready.
7. Inspect the diff and observed test result, then return to the reference.

Avoid treating a failed test after deliberately changing its expected marker as
proof that the kernel failed to boot. Inspect the guest serial output.

## Current learning state

- Working boot milestone exists in the repository.
- Build, QEMU and GDB success are recorded in PROGRESS.md.
- Owner-side execution is not yet confirmed.
- Lesson 00 has not started.
- Next action: explain the existing build/run/test entry points with the owner,
  then run the first agreed experiment.
