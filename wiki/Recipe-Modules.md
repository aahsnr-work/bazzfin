# Recipe Modules

The build is a strictly ordered list of BlueBuild modules in
`recipes/recipe.yml` (currently 20 modules). Order matters: each module sees
the filesystem state left by the previous ones. This page walks through them
in build order.

## 1. `signing`

Registers the cosign public key with the image so `bootc`/`rpm-ostree` can
verify it as `ostree-image-signed:docker://...` on rebase.

## 2. `files`

Copies `files/system/` verbatim onto `/`: rpm-ostreed update policy, scx_loader
config, zram config, nix config, sysctl/udev/modprobe/dracut drop-ins, and the
`/usr/libexec/hyprland-image/` first-boot helpers. See [[Architecture]].

## 3. `script` — /opt fix, base-image cleanup, fail-loud checks

- Creates `/usr/lib/opt` and normalizes the `/opt` symlink — Brave's RPM
  installs into `/opt`, which does not exist as a real directory on a fresh
  ostree tree.
- Runs `global-remove.sh` (removal list inherited unconditionally from the
  base image; glob patterns supported).
- **Fails the build** if `/usr/share/ublue-os/justfile` is missing — i.e. if
  the base image ever stops shipping `ublue-os-just`, `ujust` would silently
  break. It fails loudly instead.

## 4–5. `copy` + `script` — the ogc gaming kernel

Copies the pre-built ogc (Open Gaming Collective) kernel RPMs from
`ghcr.io/ublue-os/akmods:ogc-44` into the build and swaps them in via
`files/scripts/install-ogc-kernel.sh` — exactly how Bazzite's own build does
it (`build_files/install-kernel-akmods`). This cannot be done by the `akmods`
module itself: per BlueBuild's docs its `base:` field only selects pre-built
kmod sets for an already-running kernel ("custom kernels are not supported").

The `ogc-44` pin is bumped when Universal Blue's base images move to a new
Fedora release; a Renovate custom manager (`.github/renovate.json5`) attempts
to keep it current (treat as a nice-to-have — re-check after any base bump).

## 6. `dnf` — main package set + Terra bootstrap + Brave/VS Code

Installs the large Fedora package list (see [[Packages]]) plus:

- **Terra bootstrap**: adds the Terra repo file and installs
  `terra-release-extras` as a *plain* package, which drops
  `/etc/yum.repos.d/terra-extras.repo` (enabled, `priority=150` — Fedora wins
  conflicts) and the Terra GPG keys onto the image.
- `code` (VS Code, from its repo, with the Microsoft key) and `brave-browser`
  (repo-scoped — safe: leaf packages whose deps are self-contained).

`repos.cleanup: true` removes the added repo files at the end of the module
(the package-installed `terra-extras.repo` persists by design).

## 7. `dnf` — Terra packages, unscoped

Installs `terra-gamescope`, `terra-gamescope-libs`, `zed`, `umu-launcher`,
`umu-wrapper`, `8bitdo-udev-rules`, `bpftune-gaming` **without** repo scoping
so dependency resolution sees Fedora too (`terra-gamescope` needs SDL2/X11
libs that only exist in Fedora). The terra repo file is re-added here because
the previous module's cleanup removed it. Includes `exclude: [zlib]` — a
belt-and-braces guard so terra-extras' conflicting zlib can never displace
Fedora's. See [[Third-Party-Repos]] for the full story.

## 8. `dnf` — Bazzite system-management stack

From the `ublue-os/packages` COPR + Fedora repos:
`uupd`, `greenboot` + `greenboot-default-health-checks`,
`ublue-os-selinux-workarounds`, the Cockpit suite, an Intel-scoped
hardware/monitoring tier, and the SELinux auditing tools. See
[[Updates-and-Rollback]], [[SELinux]] and [[Packages]].

## 9. `dnf` — sched-ext schedulers

`scx-scheds` + `scx-tools` from the `bieszczaders/kernel-cachyos-addons` COPR
(the same source Bazzite uses). The `scx_loader` daemon is enabled in the
systemd module with Bazzite's default config (`scx_lavd`, Auto mode) baked
into `/etc/scx_loader/config.toml`.

## 10. `dnf` — Hyprland & friends

From the `sneexy/zen-browser` and `lionheartp/Hyprland` COPRs:
`hyprland-git`, `xdg-desktop-portal-hyprland`, `hyprpwcenter`, `noctalia-git`,
`nwg-look`, `qt6ct`, `cliphist`, `zen-browser`. (kitty is deliberately **not**
installed from this COPR — see [[Troubleshooting]].)

## 11. `akmods@latest` — NVIDIA + kmods

`base: ogc`, `nvidia-driver: nvidia-open`, extra kmods `xone` and `xpadneo`.
The module also injects the nouveau blacklist and `nvidia-drm.modeset` kernel
arguments itself.

## 12. `kargs`

`bluetooth.disable_ertm=1` — needed by some Bluetooth controllers (e.g.
DualSense over certain dongles).

## 13. `script` — SELinux + Bluetooth tweak + upstream apps

- `UserspaceHID=true` in `/etc/bluetooth/input.conf` (Bazzite's tweak; full
  HID — gyro/rumble — for DualSense/DualShock over Bluetooth).
- `semanage fcontext` + `restorecon` for `/usr/bin/ly` (`xdm_exec_t`).
- The setroubleshoot `util.py` ostree path patch (`/var/lib/selinux` →
  `/etc/selinux`) — see [[SELinux]].
- Installs Obsidian, Zotero and Pyprland from upstream release artifacts
  (scripts in `files/scripts/`; jq/curl are already present).

## 14. `chezmoi`

Registers `https://github.com/aahsnr-work/bazzfin` (`dotfiles/` dir) with
`file-conflict-policy: replace`, and installs the chezmoi init/update services.

## 15. `brew`

Homebrew itself plus update/upgrade timers (update 6h / wait 10m; upgrade 8h /
wait 30m).

## 16. `default-flatpaks`

Flathub remotes for both scopes; user-scope installs: Flatseal,
OnlyOffice, Bitwarden, TickTick, Steam, Lutris, Heroic, protontricks,
ProtonPlus, MangoHud + vkBasalt VulkanLayer extensions (so overlays work
inside the Flatpak sandbox).

## 17. `fonts`

Nerd Fonts (JetBrainsMono, NerdFontsSymbolsOnly) and Google fonts (JetBrains
Mono, Noto Emoji, Noto Color Emoji).

## 18. `justfiles`

Installs `files/justfiles/*.just` into the shared justfile (imported by
`ujust`), `validate: false` (just syntax is checked locally instead).

## 19. `systemd`

Enabled: `accounts-daemon`, `podman.socket`, `nix.mount`, `nix-daemon`,
`set-default-shell`, `input-remapper`, `scx_loader`, `uupd.timer`,
`greenboot-healthcheck`, `greenboot-set-rollback-trigger`.

Masked: `nvidia-persistenced`, `nvidia-powerd`, and
`rpm-ostreed-automatic.timer` (uupd owns automatic updates).

User-enabled: `pyprland`, `brew-packages-setup`.

## 20. `initramfs`

Regenerates the initramfs for the ogc kernel (replaces the old hand-rolled
`build-initramfs.sh` script).
