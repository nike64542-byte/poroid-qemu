# poroid-qemu

Podroid QEMU + native tools builder for Android ARM64.

Produces:

- `libqemu-system-aarch64.so` — QEMU (aarch64-softmmu, TCG) for Android Bionic.
- `libslirp.so` — slirp networking backend.
- `libpodroid-bridge.so` — serial bridge (built from `podroid-bridge.c`).
- `libpodroid-launcher.so` — `PR_SET_PDEATHSIG` wrapper (built from `podroid-launcher.c`).
- `qemu-assets.tar.gz` — `efi-virtio.rom` + keymaps.

Consumed by [poroid-apk](https://github.com/nike64542-byte/poroid-apk): its CI
downloads the four `.so` files (into `jniLibs/arm64-v8a`) and
`qemu-assets.tar.gz` (into `app/src/main/assets/qemu/`) from this repo's
`latest` GitHub Release.

Includes the Android-specific patches: PAC-free coroutine setjmp shim, libusb
no-device-discovery for fd-wrapped USB passthrough, Bionic shims for
shm_open/iconv/attr, and `-z max-page-size=16384` for 16 KB page alignment.

## Build

```bash
./build.sh              # QEMU 11.0.4
./build.sh 11.0.2       # specific version
```

Output lands in `out/` as `jniLibs/*.so` and `assets/qemu/*`.

## CI

- `push` to `main` (when `Dockerfile`, `podroid-bridge.c`,
  `podroid-launcher.c`, `build-tools/**` change) or `workflow_dispatch`
  builds QEMU and uploads the `.so` files + `qemu-assets.tar.gz` to the
  `latest` Release.
