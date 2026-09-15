# Packages

Everything baked into the image. `recipes/recipe.yml` is the authoritative,
commented list — this page is the readable map.

## Base

Built on `ghcr.io/ublue-os/base-main` (desktop-free Universal Blue base,
Fedora 44). The base image's package inventory is tracked in `package.list`
(for reference/auditing only — it is not an input to the build).

## Kernel & drivers

| | |
| - | - |
| ogc kernel | Bazzite's Open Gaming Collective kernel, staged from `ghcr.io/ublue-os/akmods:ogc-44` |
| NVIDIA (open) | via the `akmods` module (`nvidia-driver: nvidia-open`) |
| kmods | `xone`, `xpadneo` (controller drivers) |

## Desktop / compositor

`hyprland-git`, `xdg-desktop-portal-hyprland`, `hyprpwcenter`, `ly`,
`noctalia-git`, `nwg-look`, `qt5ct`, `qt6ct`, `gtk4-layer-shell`,
`gsettings-desktop-schemas`, `gnome-tweaks` (dconf/gsettings tooling),
`xdg-desktop-portal`, `xdg-user-dirs(-gtk)`, `polkit` via `accountsservice`,
`gnome-keyring`, `plymouth` (+spinner theme).

## CLI / terminal

`kitty` (+shell integration +terminfo), `zsh`, `neovim`, `emacs-pgtk`,
`fastfetch`, `bleachbit`, `cronie`, `curl`, `git`, `jq`, `man-db`, `nodejs`,
`npm`, `cargo`, `go`, `cmake`, `ninja-build`, `gcc-c++`, `tree-sitter-cli`,
`direnv`, `pipx`, `inotify-tools`, `sqlite`, `distrobox`, `podman`
(+`podman-sequoia`), `fail2ban`, `lynis`, `logrotate`, `nix`, `nix-daemon`,
`winetricks`.

## Apps

- **From repos:** `brave-browser`, `brave-origin`, `code` (VS Code), `zed`,
  `thunar` (+archive-plugin, media-tags, vcs-plugin, volman),
  `transmission-gtk`, `mpv`, `imv`, `swappy`, `grim`, `slurp`, `xhost`,
  `ImageMagick`, `file-roller`, `papers`, `zathura` (+pdf-poppler,
  plugins-all), `pymol`, `ddcutil`.
- **From upstream releases (build-time scripts):** Obsidian, Zotero, Pyprland.

## Fonts

Nerd Fonts: JetBrainsMono, NerdFontsSymbolsOnly. Google: JetBrains Mono,
Noto Emoji, Noto Color Emoji. Plus `liberation-fonts`, `hunspell` (en,
en-GB, en-US), `papirus-icon-theme`, `fonts-filesystem`.

## Gaming stack (Bazzite parity)

`terra-gamescope`, `terra-gamescope-libs` (Terra's patched gamescope,
terra-extras), `umu-launcher`, `umu-wrapper`, `winetricks`, `mangohud`,
`scx-scheds`, `scx-tools`, `input-remapper`, `evtest`, `linuxconsoletools`,
`vulkan-tools`, `8bitdo-udev-rules`. Flatpaks: Steam, Lutris, Heroic,
protontricks, ProtonPlus, MangoHud + vkBasalt VulkanLayers. See
[[Gaming-Stack]].

## System management (Bazzite stack)

- **Updates:** `uupd` (COPR `ublue-os/packages`) — enabled by default via
  `uupd.timer`; see [[Updates-and-Rollback]].
- **Boot health:** `greenboot`, `greenboot-default-health-checks`.
- **Kernel tuning:** `bpftune-gaming` (from the **terra** repo — not in any
  ublue COPR).
- **SELinux:** `setroubleshoot`, `setroubleshoot-server`,
  `setroubleshoot-plugins`, `setools-console`, `udica`,
  `ublue-os-selinux-workarounds` — see [[SELinux]].
- **Web console:** `cockpit-system`, `cockpit-networkmanager`,
  `cockpit-podman`, `cockpit-selinux`, `cockpit-files`, `cockpit-storaged`
  (installed but OFF by default — `ujust cockpit`).
- **App store:** `bazaar` (the modern Flathub app store, from the
  `ublue-os/packages` COPR).
- **Portal:** `bazzfin-portal` (GTK3/PyGObject app + YAML config, baked in
  from `files/system/`) — see [[Bazzfin-Portal]].

## Hardware & monitoring (Intel machine)

`lm_sensors`, `i2c-tools`, `iio-sensor-proxy`, `intel-gpu-tools`, `btop`,
`duf`, `stress-ng`, `ydotool`, `ddcutil`, `libinput-utils`.

Not included (deliberately): `ryzenadj`/`amdsmi` (AMD-only), Framework EC
tools (`fw-ectool`, `fw-fanctrl`, `framework-system`), btrfs snapshot tooling
(`snapper`, `bees`, `btrfs-assistant`), `tailscale` (opt-in VPN),
`ScopeBuddy`/`bazzite-portal`/`ds-inhibit` (gamescope-session tooling).

## Flatpaks (user scope)

Flatseal, OnlyOffice Desktop Editors, Bitwarden, TickTick, Steam, Lutris,
Heroic, protontricks, ProtonPlus, MangoHud (VulkanLayer), vkBasalt
(VulkanLayer). System scope: none.

## Homebrew

Homebrew itself plus the package list at
`/etc/hyprland-image/brew-packages`, installed per-user on first login by
`brew-packages-setup.service`.

## Dotfiles & shells

chezmoi (`dotfiles/`), zsh (forced as login shell), plus Doom Emacs / Nix Home
Manager bootstrap recipes (opt-in) — see [[Dotfiles-and-Shell]].
