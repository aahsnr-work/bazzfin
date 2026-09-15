# Gaming Stack

bazzfin integrates Bazzite's gaming userland using the same mechanisms
Bazzite's own build uses. This page maps each piece to where it comes from and
how to control it.

## Kernel: ogc (Open Gaming Collective)

The same gaming-oriented kernel Bazzite ships, staged from
`ghcr.io/ublue-os/akmods:ogc-44` and swapped in at build time by
`files/scripts/install-ogc-kernel.sh` (mirroring Bazzite's
`build_files/install-kernel-akmods`).

- The BlueBuild `akmods` module can't do kernel swaps itself (its `base:` only
  selects pre-built kmod sets for an already-running kernel), hence the
  hand-rolled swap.
- The `ogc-44` tag is pinned in the recipe; Renovate tries to bump it when the
  base image moves Fedora releases (verify manually after a bump).
- Versionlocked only for the remainder of the build; the running system
  updates the kernel normally.

## GPU: NVIDIA (open)

Via the `akmods@latest` module: `base: ogc`, `nvidia-driver: nvidia-open`,
plus `xone`/`xpadneo` kmods. The module injects the nouveau blacklist and
`nvidia-drm.modeset` kargs itself. `nvidia-persistenced` and `nvidia-powerd`
are masked in the systemd module (Bazzite's laptop-first defaults).

## Schedulers: sched-ext

`scx-scheds` + `scx-tools` from the `bieszczaders/kernel-cachyos-addons` COPR
(Bazzite's source), with the `scx_loader` D-Bus daemon **enabled** and
Bazzite's default (`scx_lavd`, Auto mode) baked into `/etc/scx_loader/config.toml`.

- `ujust toggle-scx` — status / enable / disable (also `ujust scx`).
- `scxctl get` / `scxctl list` — live scheduler info.

## Gamescope & Proton tooling

| Package | Source | Purpose |
| ------- | ------ | ------- |
| `terra-gamescope`, `terra-gamescope-libs` | terra-extras (Terra's patched build) | Bazzite's gamescope; note the unscoped install + `exclude: [zlib]` guard, see [[Third-Party-Repos]] |
| `umu-launcher`, `umu-wrapper` | terra | Unified launcher for Windows emulators / Proton prefix management |
| `winetricks` | terra | Prefix tweaking inside Proton/Wine |
| `ntsync` preload | `usr/lib/modules-load.d/wine-ntsync.conf` (same file Bazzite ships) | Proton's NTsync synchronization primitive |
| `mangohud` | terra | Overlay/HUD |

## Input & controllers

- `input-remapper` — enabled by default (`input-remapper.service`).
- `8bitdo-udev-rules`, `evtest`, `linuxconsoletools`, `xone`, `xpadneo`.
- `UserspaceHID=true` in `/etc/bluetooth/input.conf` (Bazzite's tweak):
  DualSense/DualShock expose their full HID profile — gyro, rumble — over
  Bluetooth instead of the reduced SPP profile.

## System tuning (Bazzite parity)

- `vm.max_map_count=2147483642` — `usr/lib/sysctl.d/70-gaming.conf`.
- Disk scheduler udev rule — `usr/lib/udev/rules.d/60-schedulers.rules`
  (kyber for SSDs/NVMe, bfq for HDDs/removables).
- ZRAM: zstd, `min(ram/2, 16 GiB)` — `etc/systemd/zram-generator.conf`.
- `bluetooth.disable_ertm=1` kernel arg.

## Gaming Flatpaks (user scope)

Steam, Lutris, Heroic Games Launcher, protontricks, ProtonPlus, and the
Flathub `MangoHud`/`vkBasalt` VulkanLayer extensions — the latter so overlays
and post-processing work *inside* the Flatpak sandbox (the same approach
Bazzite's installer uses).

## Gaming ujust recipes

- `ujust toggle-scx [status|enable|disable]` — sched-ext daemon control.
- `ujust fix-reset-steam` — reinstall a broken Steam Flatpak, Bazzite-style.
- `ujust protontricks` — Flatpak-aware protontricks wrapper.
