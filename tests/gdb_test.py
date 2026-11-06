"""Stop the guest at its C entry point and verify long-mode CPU state."""
import argparse
from pathlib import Path
import socket
import subprocess
import time

from boot_test import qemu_command


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--qemu", default="qemu-system-x86_64")
    parser.add_argument("--gdb", default="gdb")
    args = parser.parse_args()
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    command = qemu_command(args.qemu, "file:build/gdb-serial.log")
    command += ["-S", "-gdb", f"tcp:127.0.0.1:{port}"]
    with Path("build/gdb-qemu.stderr.log").open("wb") as stderr:
        process = subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=stderr)
        try:
            deadline = time.monotonic() + 5
            while True:
                try:
                    with socket.create_connection(("127.0.0.1", port), timeout=0.1):
                        break
                except OSError:
                    if process.poll() is not None or time.monotonic() >= deadline:
                        raise RuntimeError("QEMU GDB listener did not start")
                    time.sleep(0.02)
            gdb = [args.gdb, "-nx", "-batch", "build/kernel.elf"]
            commands = ["set pagination off", "set confirm off",
                        f"target remote 127.0.0.1:{port}", "hbreak kernel_main", "continue",
                        "info registers rip rsp cr0 cr3 cr4 efer",
                        "python assert int(gdb.parse_and_eval('$rip')) == int(gdb.parse_and_eval('&kernel_main'))",
                        "python assert int(gdb.parse_and_eval('$efer')) & (1 << 10)",
                        "python assert int(gdb.parse_and_eval('$cr0')) & (1 << 31)",
                        "python assert int(gdb.parse_and_eval('$cr4')) & (1 << 5)",
                        "python assert int(gdb.parse_and_eval('$rsp')) % 16 == 8",
                        "python assert int(gdb.parse_and_eval('$eflags')) & (1 << 9) == 0",
                        "echo GDB_ENTRY_OK\\n", "detach"]
            for command in commands:
                gdb += ["-ex", command]
            completed = subprocess.run(gdb, capture_output=True, text=True, timeout=15)
            output = completed.stdout + completed.stderr
            Path("build/gdb.log").write_text(output)
            print(output, end="")
            assert completed.returncode == 0 and "GDB_ENTRY_OK" in output, "GDB verification failed"
        finally:
            if process.poll() is None:
                process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=2)


if __name__ == "__main__":
    main()
