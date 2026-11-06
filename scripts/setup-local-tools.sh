#!/bin/sh
# Optional Debian setup for a workspace without root access.
set -eu
tools_dir=${1:-"$PWD/.local-tools"}
mkdir -p "$tools_dir"
tools_dir=$(cd "$tools_dir" && pwd)
mkdir -p "$tools_dir/apt/lists/partial" "$tools_dir/apt/cache/archives/partial"
apt-get -o "Dir::State::lists=$tools_dir/apt/lists" \
    -o "Dir::Cache=$tools_dir/apt/cache" update
apt-get -o Debug::NoLocking=1 -o "Dir::State::lists=$tools_dir/apt/lists" \
    -o "Dir::Cache=$tools_dir/apt/cache" --download-only --no-install-recommends \
    -y install qemu-system-x86 gdb
mkdir -p "$tools_dir/root" "$tools_dir/bin"
for package in "$tools_dir"/apt/cache/archives/*.deb; do
    dpkg-deb -x "$package" "$tools_dir/root"
done
cat > "$tools_dir/bin/qemu-system-x86_64" <<'WRAPPER'
#!/bin/sh
tools_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
export LD_LIBRARY_PATH="$tools_dir/root/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export QEMU_MODULE_DIR="$tools_dir/root/usr/lib/x86_64-linux-gnu/qemu"
exec "$tools_dir/root/usr/bin/qemu-system-x86_64" -L "$tools_dir/root/usr/share/qemu" -L "$tools_dir/root/usr/share/seabios" "$@"
WRAPPER
cat > "$tools_dir/bin/gdb" <<'WRAPPER'
#!/bin/sh
tools_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
export LD_LIBRARY_PATH="$tools_dir/root/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$tools_dir/root/usr/bin/gdb" --data-directory="$tools_dir/root/usr/share/gdb" "$@"
WRAPPER
chmod +x "$tools_dir/bin/qemu-system-x86_64" "$tools_dir/bin/gdb"
printf 'Tools ready. Add this directory to PATH: %s/bin\n' "$tools_dir"
