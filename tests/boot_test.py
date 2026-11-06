"""Validate the raw Multiboot image, then boot a real bounded QEMU guest."""
import argparse
import json
from pathlib import Path
import struct
import subprocess
import time


def validate_image():
    data = Path("build/kernel.bin").read_bytes()
    magic = struct.pack("<I", 0x1BADB002)
    offsets = [i for i in range(0, min(len(data), 8192) - 31, 4)
               if data[i:i + 4] == magic]
    assert len(offsets) == 1, "Expected one aligned Multiboot header"
    offset = offsets[0]
    header = struct.unpack_from("<8I", data, offset)
    _, flags, checksum, address, load, end, bss_end, entry = header
    assert sum(header[:3]) & 0xFFFFFFFF == 0, "Invalid checksum"
    assert flags == 0x10003, "Unexpected Multiboot flags"
    assert address - load == offset and load == 0x100000
    assert end - load == len(data) and bss_end > end
    assert address + 32 <= entry < end
    undefined = subprocess.check_output(["nm", "-u", "build/kernel.elf"], text=True)
    assert not undefined.strip(), f"Unresolved symbols: {undefined}"
    print(f"HEADER_OK load={load:#x} entry={entry:#x} bss_end={bss_end:#x}")


def qemu_command(qemu, serial):
    return [qemu, "-machine", "pc,accel=tcg", "-cpu", "qemu64", "-smp", "1",
            "-m", "64M", "-display", "none", "-monitor", "none", "-serial", serial,
            "-nic", "none", "-no-reboot", "-no-shutdown", "-kernel", "build/kernel.bin"]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--qemu", default="qemu-system-x86_64")
    parser.add_argument("--timeout", type=float, default=10)
    args = parser.parse_args()
    validate_image()
    log = Path("build/serial.log")
    log.write_bytes(b"")
    result = {"timeout_seconds": args.timeout, "marker_seen": False}
    started = time.monotonic()
    with Path("build/qemu.stderr.log").open("wb") as stderr:
        process = subprocess.Popen(qemu_command(args.qemu, f"file:{log}"),
                                   stdout=subprocess.DEVNULL, stderr=stderr)
        try:
            while time.monotonic() - started < args.timeout:
                if b"KERNEL_BOOT_OK\r\n" in log.read_bytes():
                    result["marker_seen"] = True
                    break
                if process.poll() is not None:
                    break
                time.sleep(0.02)
        finally:
            result["exited_before_cleanup"] = process.poll() is not None
            if process.poll() is None:
                process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=2)
            result["qemu_exit_code"] = process.returncode
            result["elapsed_seconds"] = round(time.monotonic() - started, 3)
            result["timed_out"] = not result["marker_seen"] and not result["exited_before_cleanup"]
            Path("build/boot-result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(log.read_text(errors="replace"), end="")
    print(json.dumps(result))
    assert result["marker_seen"] and not result["exited_before_cleanup"], \
        "Guest boot failed; see build/serial.log and build/qemu.stderr.log"


if __name__ == "__main__":
    main()
