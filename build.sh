#!/bin/bash
# Podroid QEMU + native tools builder for Android ARM64.
# Produces libqemu-system-aarch64.so, libslirp.so, libpodroid-bridge.so,
# libpodroid-launcher.so plus qemu assets (efi-virtio.rom, keymaps).
#
# Usage: ./build.sh [QEMU_VERSION] [OUT_DIR]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QEMU_VERSION="${1:-11.0.4}"
OUT="${2:-${SCRIPT_DIR}/out}"

log() { printf "\033[1;34m==>\033[0m %s\n" "$*"; }

verify_16kb_align() {
    local lib="$1"
    python3 - "$lib" << 'EOF'
import struct, sys
path = sys.argv[1]
with open(path, 'rb') as f:
    data = f.read()
e_phoff = struct.unpack_from('<Q', data, 32)[0]
e_phentsize = struct.unpack_from('<H', data, 54)[0]
e_phnum = struct.unpack_from('<H', data, 56)[0]
aligns = []
for i in range(e_phnum):
    off = e_phoff + i * e_phentsize
    if struct.unpack_from('<I', data, off)[0] == 1:
        aligns.append(struct.unpack_from('<Q', data, off + 48)[0])
ok = all(a >= 16384 for a in aligns)
if not ok:
    print(f"FAILED: {path} is not 16KB page aligned!")
    sys.exit(1)
EOF
}

log "Building QEMU ${QEMU_VERSION} for Android ARM64 (Docker)..."
docker build --build-arg "QEMU_VERSION=${QEMU_VERSION}" \
    -t podroid-qemu-builder --target qemu-builder "${SCRIPT_DIR}"

log "Extracting artifacts..."
docker rm -f podroid-qemu-extract 2>/dev/null || true
docker create --name podroid-qemu-extract podroid-qemu-builder /bin/true

mkdir -p "${OUT}/jniLibs" "${OUT}/assets/qemu/keymaps"
docker cp podroid-qemu-extract:/opt/qemu-out/libqemu-system-aarch64.so "${OUT}/jniLibs/"
docker cp podroid-qemu-extract:/opt/qemu-out/libslirp.so               "${OUT}/jniLibs/"
docker cp podroid-qemu-extract:/opt/qemu-out/libpodroid-bridge.so      "${OUT}/jniLibs/"
docker cp podroid-qemu-extract:/opt/qemu-out/libpodroid-launcher.so    "${OUT}/jniLibs/"
docker cp podroid-qemu-extract:/opt/qemu-out/share/qemu/efi-virtio.rom "${OUT}/assets/qemu/"
docker cp podroid-qemu-extract:/opt/qemu-out/share/qemu/keymaps/.       "${OUT}/assets/qemu/keymaps/"
docker rm podroid-qemu-extract >/dev/null

verify_16kb_align "${OUT}/jniLibs/libqemu-system-aarch64.so"
echo "QEMU ready in: ${OUT}"
