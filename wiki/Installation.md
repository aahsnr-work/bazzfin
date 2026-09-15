# Installation

## Prerequisites

- A machine already running a Fedora Atomic / bootc-based image (Silverblue,
  Kinoite, any uBlue image, ...) — bazzfin rebases onto those. A fresh Fedora
  Atomic install (anything, even Silverblue) is the easiest starting point.
- Secure Boot: if enabled, enroll the akmods signing key once (see
  [Secure Boot](#secure-boot)). Otherwise the NVIDIA/ogc kernel modules will
  fail to load.
- This machine is Intel (the hardware/monitoring package tier is Intel-scoped;
  see [[Packages]]).

## Deploy the image

```bash
# Pin to the version tag (tracks the Fedora release of the base image):
sudo bootc switch ostree-image-signed:docker://ghcr.io/aahsnr-work/bazzfin:latest
systemctl reboot
```

Or, on a machine already running any Universal Blue image, from a terminal:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/aahsnr-work/bazzfin:latest
systemctl reboot
```

Tags published:

- `ghcr.io/aahsnr-work/bazzfin:latest` — floating, rebuilt daily
- `ghcr.io/aahsnr-work/bazzfin:44` — tracks the Fedora release of the base
  image (`image-version` in the recipe)

## Verify the signature

The image is signed with [cosign](https://github.com/sigstore/cosign); the
public key is committed as [`cosign.pub`](https://github.com/aahsnr-work/bazzfin/blob/main/cosign.pub).

```bash
# For private packages, log in first:
podman login ghcr.io

cosign verify --key cosign.pub "ghcr.io/aahsnr-work/bazzfin:latest"
```

GitHub packages start **private**. To let any machine pull without
authenticating, flip visibility: GitHub profile → **Packages → bazzfin →
Package settings → Change visibility → Public**.

## First login

1. **ly** presents the login prompt on the active VT (tty2); log in.
2. Hyprland starts. The shell is **zsh** — it is forced for root and all real
   local users at deploy time by `set-default-shell.service` (runs before any
   login is permitted; see [[Dotfiles-and-Shell]]).
3. Dotfiles are already in place: chezmoi applied them at build time into
   `/etc/skel`, so the home directory is populated on first login.
4. Flatpaks (Steam, Lutris, Heroic, Bitwarden, ...) are pre-installed.
5. Homebrew packages from `/etc/hyprland-image/brew-packages` install in the
   background on first login (`brew-packages-setup.service`); nothing to do.
6. If Doom Emacs or Nix Home Manager is wanted, run the one-time bootstraps:
   `ujust doom-setup` and `ujust home-manager-setup` (see [[ujust-Recipes]]).

## Secure Boot

The ogc kernel and NVIDIA/akmods modules are signed by Universal Blue's
build key. With Secure Boot enabled, enroll it once:

```bash
ujust enroll-secure-boot-key
```

(Shared recipe from the `ublue-os-just` package — see [[ujust-Recipes]].)

## Updating afterwards

Automatic updates are on by default via **uupd**; on the deployed machine just
let it run, or manage it manually — see [[Updates-and-Rollback]].
