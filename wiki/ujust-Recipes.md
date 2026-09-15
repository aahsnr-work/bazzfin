# ujust Recipes

`ujust` = the shared Universal Blue just runner. Recipes come from two
sources:

1. **`ublue-os-just`** (RPM, base image) — the shared core shipped on every
   Universal Blue image (Bazzite/Bluefin/Aurora). bazzfin deliberately does
   not override it, so all the standard recipes stay available.
2. **bazzfin's own** `files/justfiles/*.just`, installed by the `justfiles`
   module into the same justfile.

## Shared core (ublue-os-just)

| Recipe | What it does |
| ------ | ------------ |
| `update` (alias `upgrade`) | Full update; drives uupd when `uupd.timer` is enabled, else runs rpm-ostree/flatpak/distrobox updates manually. Accepts `full\|minimal\|prompt` verbosity. |
| `toggle-updates` (alias `auto-update`) | Enable/disable automatic updates (uupd-aware). |
| `changelogs` | rpm-ostree changelog diff. |
| `update-firmware` | fwupd refresh + update. |
| `bios`, `bios-info` | Firmware/BIOS helpers. |
| `device-info` | Hardware inventory. |
| `clean-system` | System cleanup. |
| `logs-last-boot`, `logs-this-boot` | Journal digests. |
| `enroll-secure-boot-key` | Enroll Universal Blue's signing key (needed for Secure Boot + akmods/NVIDIA). |
| `setup-luks-tpm-unlock`, `remove-luks-tpm-unlock` | LUKS TPM2 auto-unlock. |
| `toggle-user-motd`, `toggle-nvk` | Misc toggles. |
| `check-idle-power-draw`, `check-local-overrides` | Diagnostics. |
| `setup-distrobox-app`, `distrobox-assemble`, `distrobox-new` | Distrobox helpers. |
| `install-resolve`, `configure-broadcom-wl` | Special-case installs. |
| `ugum` | Interactive chooser used inside recipes (enable/disable prompts). |

## 10-rebase.just — group `system`

| Recipe | What it does |
| ------ | ------------ |
| `rebase [tag]` (alias `update-image`) | Rebase/upgrade this machine onto the bazzfin image; reads the image reference from `/usr/share/ublue-os/image-info.json`; uses `bootc` when available, `rpm-ostree` otherwise. Default tag `latest`. |

## 20-doom.just — group `doom`

| Recipe | What it does |
| ------ | ------------ |
| `doom-setup` | One-time Doom Emacs bootstrap: clones `aahsnr-configs/doom` into `~/.config/doom` (aborts if it exists), clones doomemacs/core, runs `doom install` + `doom sync`. Start with `emacs`. |

## 30-home-manager.just — group `nix`

| Recipe | What it does |
| ------ | ------------ |
| `home-manager-setup` | One-time standalone Home Manager bootstrap via `nix run home-manager/master -- init --switch`; aborts if `~/.config/home-manager` exists. Requires the baked-in nix (`nix.mount` + `nix-daemon`). |

## 40-gaming.just — group `gaming`

| Recipe | What it does |
| ------ | ------------ |
| `toggle-scx [status\|enable\|disable]` (alias `scx`) | scx_loader daemon control; `status` also shows the running/available schedulers via `scxctl`. |
| `fix-reset-steam` | Reinstall a broken Steam Flatpak (Bazzite-style). |
| `protontricks` | Flatpak-aware protontricks wrapper. |

## 50-system.just — group `system`

| Recipe | What it does |
| ------ | ------------ |
| `status` | Current bootc/rpm-ostree deployment status. |
| `rollback` | Stage a rollback to the previous deployment, then offer to reboot into it (`bootc rollback` / `rpm-ostree rollback`). |
| `cockpit [status\|enable\|disable]` | Manage the Cockpit web console (https://localhost:9090). Installed but OFF by default. |
| `toggle-bpftune [status\|enable\|disable]` (alias `bpftune`) | Manage the bpftune adaptive kernel-tuning daemon. |

## Adding a recipe

1. Pick / create the right `NN-name.just` file in `files/justfiles/` (the number
   orders imports; group via `[group("...")]`).
2. Use `#!/usr/bin/bash` + `set -euo pipefail` in script recipes; prefer
   `ugum choose` for interactive toggles (matches upstream style).
3. `just validate` still passes (the recipe doesn't depend on just syntax),
   and `just --justfile files/justfiles/<file>.just --list` parses the file.
4. Don't shadow shared-core recipe names.
