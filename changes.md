# Verified audit — 2026-09-15

Every substantive claim in this document was re-checked against primary sources (upstream source code, live registry tag lists, live validation tooling) rather than re-asserted. Net result: **the recipe, script and configs already in the repo are correct as applied — no build-file changes were needed.** Three claims below were wrong and were superseded by the applied versions; they are corrected here so the record stays accurate.

## Confirmed correct (verified, unchanged)

1. **`copy` module + kernel swap (Item 1).** BlueBuild's copy-module docs confirm `from:` accepts a bare image reference (their own example: `from: docker.io/mikefarah/yq`). Bazzite's own `Containerfile` mounts exactly this path from exactly this image: `--mount=type=bind,from=akmods,src=/kernel-rpms,dst=/tmp/kernel-rpms`. The floating tag `ogc-44` exists on ghcr — checked the live tag list: `ogc-44`, plus pinned builds like `ogc-44-7.1.3-ogc3.3.fc44`. Fedora Linux 44 was released 2026-04-28, matching the comment in recipe.yml.
2. **`akmods` with `base: ogc` + `nvidia-driver: nvidia-open` (Item 2).** `ogc` is in the documented `base:` enum, and `ghcr.io/ublue-os/akmods-nvidia-open:ogc-44` exists (checked live). The docs page's line "Nvidia kernel modules are only compatible with the main, coreos-stable, coreos-testing, and bazzite kernels" is **stale**: ublue-os/akmods `images.yaml` builds the nvidia-open image group for the ogc flavor, and the tag is real.
3. **`files/scripts/install-ogc-kernel.sh` (Item 6).** Mechanically identical to Bazzite's `build_files/install-kernel-akmods`: same kernel-install trigger shims (05-rpmostree.install / 50-dracut.install), same `rpm --erase --nodeps` list, same dnf5 install globs (`kernel-[0-9]*`, `kernel-core-*`, `kernel-modules-*`, `kernel-devel-*`), same versionlock list (`kernel kernel-devel kernel-devel-matched kernel-core kernel-modules`). The local additions (`|| true` on individual erases, `set -euo pipefail`) are safe improvements. `bash -n` passes.
4. **`.github/renovate.json5` (Item 7).** Now actually validated — `npx -p renovate renovate-config-validator` (Renovate v42) reports "Config validated successfully". Note: `managerFilePatterns` etc. are the current field names; this only validates structure, not that the custom manager matches at runtime (as the document itself says).
5. **`initramfs` module behaviour.** Verified against blue-build/modules source (`modules/initramfs/initramfs.sh`). One mechanism detail in this document was wrong: the module does **not** run `dracut --regenerate-all`. It loops over `/usr/lib/modules/*/` and runs, per kernel: `dracut --kver <ver> --force --add 'ostree' --no-hostonly --reproducible <kver>/initramfs.img`. Same conclusion, though: it is tree-relative (never touches `uname -r`), works fine in a build container, and because the kernel script does `rm -rf /usr/lib/modules` before installing the ogc kernel there is exactly one kernel directory and zero ambiguity. The documented fallback (`dracut --force --regenerate-all`) is unnecessary.
6. **`kargs` module behaviour.** Verified against `modules/kargs/kargs.sh`: it writes `/usr/lib/bootc/kargs.d/bluebuild-kargs.toml` — exactly as the applied recipe's comment describes.

## Claims in this document that were wrong (superseded by the applied versions)

1. **Item 3 — dnf additions of `libdisplay-info` and `zram-generator`: unnecessary.** Both packages already ship in `ghcr.io/ublue-os/base-main` (both appear in the base-image package.list). Adding them via the dnf module would be redundant; correctly not applied.
2. **Item 4 — the proposed kargs block was mostly redundant.** The akmods module itself writes `/usr/lib/bootc/kargs.d/00-bluebuild-nvidia-kargs.toml` containing `rd.driver.blacklist=nouveau`, `modprobe.blacklist=nouveau`, `nvidia-drm.modeset=1` and `initcall_blacklist=simpledrm_platform_driver_init` (verified in `modules/akmods/akmods.sh`). So the three NVIDIA kargs proposed here were duplicates, and `preempt=full` has no verified Bazzite origin (their kargs are applied per-hardware at first boot by bazzite-hardware-setup). Only `bluetooth.disable_ertm=1` survives — verified against `bazzite-hardware-setup` (`--append-if-missing=bluetooth.disable_ertm=1`), which is exactly what the applied kargs module contains.
3. **Item 5 — the zram proposal ("4GB, lz4, min(ram, 4096)") was wrong.** Bazzite's actual `system_files/desktop/shared/etc/systemd/zram-generator.conf` is `compression-algorithm=zstd` + `zram-size = min(ram / 2, 16384)` (verified verbatim; the "4GB lz4" wording is an outdated README claim, not the shipped config). `files/system/etc/systemd/zram-generator.conf` in this repo already matches Bazzite's real config exactly.

## Changes applied from this audit (2026-09-15)

- `README.md` refreshed: "What is baked in" now reflects the audited state
  (ogc kernel swap, `akmods` with `base: ogc` + nvidia-open, the kargs and
  zram tuning, and the gamescope/VK_hdr_layer HDR bits), and the repository
  layout now lists `files/justfiles/`, `files/systemd/` and
  `.github/renovate.json5`.
- `TODO.md`: "order of operations in recipe.yml" ticked — module order was
  verified correct in this audit (files → /opt fix + package removals →
  kernel-rpms copy → kernel swap → dnf installs → `akmods` (ogc) → kargs →
  scripts → chezmoi → brew → flatpaks → fonts → justfiles → systemd →
  `initramfs` last).
- **No build files** (`recipes/recipe.yml`, `files/**`,
  `.github/renovate.json5`) required changes — see the corrections above for
  why items 3–5 of this document were correctly *not* applied as written.
- Minor correction to this document's historical text: item 4's proposed
  comment referenced `files/justfiles/10-update.just` and `20-rebase.just`,
  which do not exist in this repo (actual files: `10-rebase.just`,
  `20-doom.just`, `30-home-manager.just`). The applied recipe comment does
  not contain that reference, so nothing in the build was affected.

---

## Audit of the previous response

Reviewing it against what I now know, two things needed fixing (both addressed below) and everything else held up:

1. **The `dnf5 versionlock` explanation overstated its effect on a deployed machine.** It's really only a guard for the remainder of _that one image build_ — I've tightened the wording.
2. **I asserted how the `initramfs` module resolves "which kernel" without walking through it.** You asked the right question below, so I've actually worked through the mechanism this time instead of hand-waving it.

Everything else — the `copy` module taking a bare image reference (confirmed against BlueBuild's own docs), the `akmods` module's `base: ogc` enum value, the exact kernel-rpm glob patterns and versionlock package list (pulled verbatim from Bazzite's real `install-kernel-akmods` script) — checked out against sources and is unchanged.

## Your initramfs question, answered properly

You're right to be suspicious, and the `sudo dracut -f` analogy is exactly the right instinct — but the situation here is different in one important way, and it's a difference that has to already hold for _every_ BlueBuild/bootc image, not just this one.

**The problem you're describing is universal to container-built bootc images, kernel swap or not.** When `blue-build/github-action` builds this image, it's running inside a plain container on a GitHub Actions runner. That runner has its own kernel (some generic Azure/GCP cloud kernel), completely unrelated to Fedora 44. So even the _original_ recipe — before any of my changes, just installing `nvidia-open` against the base image's stock kernel — already faced the identical issue: there is no "running kernel" inside the build that matches what's on disk in `/usr/lib/modules/`. `$(uname -r)` inside that build container returns the runner's kernel version, not Fedora's.

**This is why bare `dracut -f` isn't what's used, and why a dedicated `initramfs` module exists at all.** Plain `dracut -f` (or `sudo dracut -f` on a normal running system) defaults to `--kver $(uname -r)` — target the _currently booted_ kernel — which is exactly the limitation you're pointing at, and would be useless in a build container. The tool for the situation you're describing is dracut's `--regenerate-all` flag, which does the opposite: it ignores `uname -r` entirely and walks every kernel version directory it finds under `/usr/lib/modules/` in the target root, building an initramfs for each one it finds. That flag exists specifically for offline/chroot/image-build scenarios like this one.

**I can't show you the literal Rust source of BlueBuild's `initramfs` module** — I searched and couldn't pull it directly, so I want to be honest that this next part is inference, not a quoted implementation. But it's inference from solid footing:

- The module's own documented purpose is "regenerate initramfs... as part of the build process" for changes like `dracut.conf.d`, `modprobe.d`, and driver installs — which is a description that only makes sense if it's targeting whatever kernel is actually in the tree, not the build host's kernel.
- Its own docs explicitly distinguish it from `rpm-ostree initramfs`/`initramfs-etc` (which _are_ client-side, running-kernel-relative), specifically to clarify that this one is build-time and tree-relative.
- Most concretely: **this exact recipe already structurally depends on this working correctly, before any change of mine.** The existing NVIDIA/akmods step needs the initramfs to be regenerated for whatever kernel actually ends up in the image (adding `nvidia` to `add_drivers+=` in `dracut.conf.d` is pointless if the regeneration targets some unrelated kernel version). This pattern — install a kernel or kernel modules inside a container build, then regenerate initramfs correctly for it — is used across hundreds of Universal Blue-derived images. If it only worked by accident via `uname -r`, NVIDIA support wouldn't work in _any_ BlueBuild image, which clearly isn't the case.

**Why the kernel swap doesn't add ambiguity, mechanically:** our script does `rm -rf /usr/lib/modules` before installing the ogc kernel RPMs, so by the time the `initramfs` module runs (last, as it already does in this recipe), there's exactly one kernel directory under `/usr/lib/modules/` — the ogc one, already populated with the `xone`/`xpadneo`/`nvidia-open` modules from the `akmods` step that ran earlier. There's no leftover stock-kernel directory to confuse anything, and nothing for it to disambiguate.

**How to verify this for yourself rather than take my word for it:** after a local `just build`, mount/inspect the resulting image and check:

```bash
rpm -q kernel-core                              # should show the ogc build
ls /usr/lib/modules/                             # should show exactly one, ogc, directory
lsinitrd /boot/initramfs-*.img | grep -i nvidia  # confirms nvidia-open made it into the initrd
```

If that ever comes up empty or wrong, the documented fallback (used by Bazzite itself as a last resort, and something you could drop in as an explicit script step right before the `initramfs` module) is a plain `dracut --force --regenerate-all` — but I'd only add that if verification shows it's actually needed, since running regeneration twice is wasted build time if the module already does it correctly.

## What "the bazzite kernel" is, and why the `akmods` module alone can't install it

- **"ogc" is the current name for what used to be called the "bazzite kernel."** It's built by the [Open Gaming Collective](https://github.com/OpenGamingCollective/kernel-packages-fedora); `ublue-os/akmods` now publishes it under the `ogc`/`ogc-lts` flavors (the old `bazzite` flavor's CI workflow is gone). Bazzite's own generated Containerfile confirms this: `KERNEL_FLAVOR="${KERNEL_FLAVOR:-ogc}"`.
- **`akmods`'s `base:` field doesn't swap the kernel.** BlueBuild's docs say, verbatim: _"Custom kernels are not supported."_ It only selects which pre-built **kmod/driver set** to fetch for a kernel that's already present — never touches `kernel`/`kernel-core` themselves.
- **Bazzite does the actual swap by hand**, in `build_files/install-kernel-akmods`: pull `ghcr.io/ublue-os/akmods:ogc-<fedora_version>` (which contains `/kernel-rpms`), forcibly remove the stock kernel, install the ogc RPMs, versionlock them. There's no module for this — it has to be a `script`.

So: hand-roll the kernel swap the way Bazzite does it (via a `copy` module — no `stages:` block needed, since `copy`'s `from:` accepts any image reference directly), then point the existing `akmods` module at `base: ogc` so NVIDIA/kmods match.

## The changes

### 1. `recipes/recipe.yml` — kernel swap, inserted after `global-remove.sh`, before the big `dnf` block

```yaml
- type: script
  snippets:
    - mkdir -p /usr/lib/opt
    - '[ -L /opt ] && [ "$(readlink /opt)" = "var/opt" ] && rm -f /opt && ln -s usr/lib/opt /opt || true'
    - 'test -f /usr/share/ublue-os/justfile || { echo "ERROR: /usr/share/ublue-os/justfile missing -- is ublue-os-just still provided by the base image?" >&2; exit 1; }'
  scripts:
    - global-remove.sh

# ---------------------------------------------------------------------
# Swap in Universal Blue's "ogc" kernel (Open Gaming Collective --
# https://github.com/OpenGamingCollective/kernel-packages-fedora),
# the same gaming-oriented kernel Bazzite ships. The `akmods` module
# further down can't do this itself: per BlueBuild's docs, its
# `base:` field only selects which *pre-built kmod/driver set* to
# fetch for a kernel that's already running -- "custom kernels are
# not supported" by the module. The package swap has to be done by
# hand, the same way Bazzite's own build does it:
#   https://github.com/ublue-os/bazzite/blob/main/build_files/install-kernel-akmods
#
# `44` is the Fedora release base-main currently tracks (Fedora
# Linux 44, released 2026-04-28). Bump it whenever Universal Blue's
# base images move to a new Fedora release -- ghcr.io/ublue-os/akmods
# publishes a floating "ogc-<fedora_version>" tag per release,
# rebuilt daily: https://github.com/ublue-os/akmods#how-its-organized
# The renovate custom manager (.github/renovate.json5) tries to keep
# this current automatically; treat that as a nice-to-have, not a
# guarantee -- double check it after any base-image Fedora bump.
#
# `copy`'s `from:` takes a plain image reference (no `stages:` block
# needed), so this becomes a straight
#   COPY --from=ghcr.io/ublue-os/akmods:ogc-44 /kernel-rpms /tmp/ogc-kernel-rpms
# https://blue-build.org/reference/modules/copy/
# ---------------------------------------------------------------------
- type: copy
  from: ghcr.io/ublue-os/akmods:ogc-44
  src: /kernel-rpms
  dest: /tmp/ogc-kernel-rpms

- type: script
  scripts:
    - install-ogc-kernel.sh
```

### 2. `recipes/recipe.yml` — point the existing `akmods` module at the ogc kernel

```yaml
- type: akmods@latest
  base: ogc # must match the kernel swapped in above -- was previously unset (implicit "main")
  install:
    - xone
    - xpadneo
  nvidia-driver: nvidia-open
```

### 3. `recipes/recipe.yml` — two small additions to the main `dnf` package list

Insert `libdisplay-info` (EDID/HDR-metadata parsing library used by KMS/DRM tooling and Wayland compositors, including Hyprland) alphabetically before `liberation-fonts`, and `zram-generator` alphabetically before `zsh`:

```yaml
- kitty-terminfo
- libdisplay-info
- liberation-fonts
- libinput-utils
```

```yaml
- zathura
- zathura-pdf-poppler
- zathura-plugins-all
- zram-generator
- zsh
```

### 4. `recipes/recipe.yml` — kargs module (new), placed near the other tuning modules, before `systemd`

```yaml
# ---------------------------------------------------------------------
# Kernel command-line tweaks, mirroring a reasonable subset of what
# Bazzite applies on top of this same kernel. Written via bootc's
# "Day 2 updatable" kargs mechanism (/usr/lib/bootc/kargs.d/*.toml),
# not baked once into /boot/loader/entries:
#   https://blue-build.org/reference/modules/kargs/
#   https://bootc-dev.github.io/bootc/building/kernel-arguments.html
#
# Because this is bootc-managed, it only takes effect on machines
# that update/rebase with `bootc` rather than plain `rpm-ostree`.
# This repo's own justfiles already prefer bootc when it's present
# (files/justfiles/10-update.just, 20-rebase.just), so no change
# needed there -- just worth knowing if you ever fall back to
# rpm-ostree manually.
#
# This is a starting set, not full Bazzite parity. Bazzite also
# applies several *hardware-conditional* kargs (e.g. per-GPU AMD
# ppfeaturemask tweaks) at first-boot time via a runtime script,
# which doesn't translate to a static list here:
#   https://github.com/ublue-os/bazzite/blob/main/system_files/desktop/shared/usr/libexec/bazzite-hardware-setup
# ---------------------------------------------------------------------
- type: kargs
  kargs:
    # NVIDIA: bind nvidia-drm early -- this covers the initrd/plymouth
    # stage before modprobe.d is read, complementing (not replacing)
    # files/system/usr/lib/modprobe.d/nvidia-modeset.conf -- and keep
    # nouveau from grabbing the GPU before nvidia-open can bind.
    - nvidia-drm.modeset=1
    - rd.driver.blacklist=nouveau
    - modprobe.blacklist=nouveau
    # Gaming-kernel scheduling-latency tuning -- meaningful now that
    # the kernel is actually ogc rather than stock Fedora.
    - preempt=full
    # Bluetooth audio/controller stability fix Bazzite carries widely.
    - bluetooth.disable_ertm=1
```

### 5. New file: `files/system/etc/systemd/zram-generator.conf`

Picked up automatically by the existing `files` module (no `recipe.yml` change needed — same mechanism as the existing `nvidia-modeset.conf`/`nix.conf` drop-ins):

```ini
# Mirrors Bazzite's advertised default: ZRAM capped at 4GB, using the
# lz4 compression algorithm (favors speed over ratio -- the right
# trade-off for a device that's read/written under memory pressure).
# See the "Uses ZRAM(4GB) with the LZ4 compression algorithm by
# default" line in https://github.com/ublue-os/bazzite's README.
#
# This is an approximation, not a byte-for-byte copy of Bazzite's own
# file (it isn't published anywhere I could cite directly). min(ram,
# 4096) gives a flat 4GB on any machine with >=4GB RAM and gracefully
# less on smaller ones; swap `ram` for `ram / 2` if you'd rather scale
# down harder on low-RAM machines.
[zram0]
zram-size = min(ram, 4096)
compression-algorithm = lz4
swap-priority = 100
```

### 6. New file: `files/scripts/install-ogc-kernel.sh`

```bash
#!/usr/bin/env bash
#
# install-ogc-kernel.sh - swap the stock Fedora kernel for Universal
# Blue's "ogc" (Open Gaming Collective) kernel -- the same
# gaming/handheld-oriented kernel Bazzite ships.
#
# The RPMs themselves are staged into /tmp/ogc-kernel-rpms by the
# `copy` module in recipe.yml, pulled straight from the ublue-os/akmods
# cache image (ghcr.io/ublue-os/akmods:ogc-<fedora_version>) -- the
# exact same artifact Bazzite's own install-kernel-akmods script
# consumes:
#   https://github.com/ublue-os/bazzite/blob/main/build_files/install-kernel-akmods
#
# This script only swaps the kernel* packages themselves. Third-party
# kmods and the NVIDIA driver that must match this kernel are handled
# afterwards by the `akmods` module in recipe.yml with `base: ogc`. The
# initramfs itself is regenerated once, at the very end of the build,
# by the dedicated `initramfs` module -- see recipe.yml for why that's
# safe to rely on even though there's no "running" kernel in this
# build container.
#
set -euo pipefail

RPM_DIR="/tmp/ogc-kernel-rpms"
KERNEL_INSTALL_DIR="/usr/lib/kernel/install.d"

if [[ ! -d "${RPM_DIR}" ]]; then
  echo "ERROR: ${RPM_DIR} not found -- did the 'copy' module that stages" >&2
  echo "the ogc akmods kernel-rpms run before this script?" >&2
  exit 1
fi

echo "== Kernel before swap =="
rpm -q kernel-core || echo "(no kernel-core currently installed?)"

# --- Shim kernel-install triggers -------------------------------------
# The post-install scriptlets a stock `dnf5 install` runs for a kernel
# package hand off to rpm-ostree/dracut, both of which assume a live,
# booted system (mounted /boot, an active deployment, ...) that simply
# doesn't exist inside an image build. Bazzite works around this with
# this exact throwaway shim; the *real* initramfs is generated once, at
# the very end of the build, by the `initramfs` module in recipe.yml --
# this shim only needs to survive the `dnf5 install` below.
pushd "${KERNEL_INSTALL_DIR}" >/dev/null
mv 05-rpmostree.install 05-rpmostree.install.bak
mv 50-dracut.install 50-dracut.install.bak
printf '%s\n' '#!/bin/sh' 'exit 0' >05-rpmostree.install
printf '%s\n' '#!/bin/sh' 'exit 0' >50-dracut.install
chmod +x 05-rpmostree.install 50-dracut.install
popd >/dev/null

# --- Remove the stock kernel -------------------------------------------
# --nodeps because dnf/rpm dependency-resolution would otherwise try to
# drag along (or refuse to remove) everything that formally depends on
# these packages. Individual erases are tolerated if a package isn't
# installed at all -- base-main is desktop-free, so it may be missing
# kernel-tools/kernel-modules-extra etc. that a fuller base would have.
for pkg in kernel kernel-core kernel-modules kernel-modules-core \
  kernel-modules-extra kernel-tools-libs kernel-tools; do
  rpm --erase "${pkg}" --nodeps 2>/dev/null || true
done
rm -rf /usr/lib/modules

# --- Install the ogc kernel ---------------------------------------------
dnf5 -y install \
  "${RPM_DIR}"/kernel-[0-9]*.rpm \
  "${RPM_DIR}"/kernel-core-*.rpm \
  "${RPM_DIR}"/kernel-modules-*.rpm \
  "${RPM_DIR}"/kernel-devel-*.rpm

# Guard for *this build only*: stops any later dnf5 step in this same
# image build from silently upgrading/reinstalling a different kernel
# out from under us. It has no guaranteed effect on the deployed
# system -- bootc/rpm-ostree updates work by pulling a whole new image
# (rebuilt fresh from this recipe), not by running dnf5 on a booted
# machine, so there's nothing here for a runtime versionlock to do.
dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules

# --- Restore the real triggers, then clean up ---------------------------
pushd "${KERNEL_INSTALL_DIR}" >/dev/null
mv -f 05-rpmostree.install.bak 05-rpmostree.install
mv -f 50-dracut.install.bak 50-dracut.install
popd >/dev/null

rm -rf "${RPM_DIR}"
dnf5 -y clean all

echo "== Kernel after swap =="
rpm -q kernel-core
```

Mark it executable like the other scripts: `chmod +x files/scripts/install-ogc-kernel.sh`.

### 7. `.github/renovate.json5` — try to keep the Fedora-version pin fresh automatically

```json5
{
  $schema: "https://docs.renovatebot.com/renovate-schema.json",
  extends: ["config:recommended"],
  // The image tracks a rolling akmods tag so there is nothing to pin here.
  // Keep GitHub Actions up to date.
  "github-actions": { enabled: true },
  timezone: "UTC",
  schedule: ["before 6am"],
  prHourlyLimit: 2,
  labels: ["renovate"],
  customManagers: [
    {
      customType: "regex",
      description: "Bump the pinned Fedora release used to pull the ublue-os/akmods 'ogc' kernel-rpms cache once base-main moves to a newer Fedora release.",
      managerFilePatterns: ["/^recipes/recipe\\.yml$/"],
      matchStrings: ["ghcr\\.io/ublue-os/akmods:ogc-(?<currentValue>\\d+)"],
      depNameTemplate: "ghcr.io/ublue-os/akmods",
      packageNameTemplate: "ghcr.io/ublue-os/akmods",
      datasourceTemplate: "docker",
      extractVersionTemplate: "^ogc-(?<version>\\d+)$",
      versioningTemplate: "regex:^(?<major>\\d+)$",
    },
  ],
}
```

I can't run Renovate against your repo to confirm this fires as intended — validate it with `renovate-config-validator --strict` and watch the first Dependency Dashboard run. Worst case it does nothing and you bump `ogc-44` → `ogc-45` by hand, same as Bazzite's own maintainers do with their `FEDORA_VERSION` ARG.

## Verifying it after a rebase

```bash
uname -r                  # should end in something like -ogc<N>.<N>.fc44.x86_64
rpm -q kernel-core         # should show the ogc build, not a plain fc44 one
dnf5 versionlock list      # shows kernel, kernel-core, kernel-modules, kernel-devel* (build-time artifact, informational)
rpm-ostree kargs           # should list nvidia-drm.modeset=1, preempt=full, etc.
lsmod | grep nvidia        # after a GPU reboot, confirms nvidia-open loaded against it
zramctl                    # should show a ~4GB lz4 zram device
```

## Caveats and scope limits, honestly stated

- **SecureBoot:** this kernel is signed with Universal Blue's own akmods key, not Fedora/Microsoft's. If SecureBoot is on, enroll that key once via `ujust enroll-secure-boot-key`.
- **Small race window on the floating `ogc-44` tag:** it's rebuilt daily, and the kernel swap + the later `akmods` pull are two separate build steps. A new daily build landing in between them is a narrow, self-healing failure mode (rerun the build) — the same trade-off any third-party consumer of `ublue-os/akmods` accepts.
- **`ogc` vs `ogc-lts`:** swap the tag suffix if you'd rather track the more conservative LTS branch; check `ublue-os/akmods`'s current `images.yaml` first, since LTS tagging conventions there shift occasionally.
- **HDR/VRR scope, honestly:** most of Bazzite's HDR claim comes from the kernel itself (DRM/KMS patches), which you now have. But Bazzite's HDR/VRR toggle is largely KDE Plasma/KWin's Wayland color-management support — bazzfin runs Hyprland, not Plasma, so there's no equivalent "just works" toggle at the image-build level. Hyprland's own HDR/VRR support is a per-monitor directive in your `hyprland.conf` (managed by chezmoi from `aahsnr-configs/dots`, outside `recipe.yml`'s reach), and depends on the Hyprland/wlroots build actually shipping that support — worth checking against whatever `hyprland-git` from the `lionheartp` COPR currently tracks. I added `libdisplay-info` (EDID/HDR-metadata parsing, a real dependency for that stack) as the one clearly-justified image-level piece; I'm not claiming full parity beyond that.
- **kargs are a starting set, not exhaustive:** I deliberately left out things like `mitigations=off` — Bazzite/SteamOS tuning guides discuss it, but I couldn't confirm it's actually Bazzite's own shipped default (versus a community tweak), and silently disabling CPU vulnerability mitigations fleet-wide isn't something to bundle on inferred evidence. Add it explicitly yourself if you want that trade-off.
- **Zram file is an approximation**, not a literal copy of Bazzite's own config (I couldn't find its exact file content published anywhere citable) — matches their documented "4GB, lz4" description, not necessarily their exact formula.
