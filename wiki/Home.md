# Welcome to the bazzfin wiki

**bazzfin** is a single custom **Fedora Atomic / bootc** image: a desktop-free
Universal Blue base with the **NVIDIA (open) driver**, the **Hyprland** Wayland
compositor and the **ly** display manager baked in, plus every application,
font, Flatpak, dotfile and Homebrew package needed at first login — ready to
boot straight into a working Hyprland session.

It is built with [BlueBuild](https://blue-build.org) on top of
`ghcr.io/ublue-os/base-main`, described declaratively in
[`recipes/recipe.yml`](https://github.com/aahsnr-work/bazzfin/blob/main/recipes/recipe.yml),
built and signed by GitHub Actions, and published to GHCR. Bazzite's gaming
userland ("ogc" kernel, patched gamescope, sched-ext schedulers, Proton
tooling) and Bazzite's system-management stack (uupd, greenboot, Cockpit,
SELinux tooling) are integrated the same way Bazzite's own build does it.

---

## Quick start

```bash
# Deploy on a fresh machine (Atomic/base already installed):
sudo bootc switch ostree-image-signed:docker://ghcr.io/aahsnr-work/bazzfin:latest
systemctl reboot

# Already running this image (or another Atomic base)?
ujust rebase

# Verify the image signature (works before or after deploying):
cosign verify --key cosign.pub "ghcr.io/aahsnr-work/bazzfin:latest"
```

The first login drops you into **Hyprland** with `ly` on tty2 as the display
manager, zsh as the shell, chezmoi-managed dotfiles and all Flatpaks already
installed. Homebrew packages install themselves in the background
(`brew-packages-setup.service`).

---

## Wiki contents

| Page | What it covers |
| ---- | -------------- |
| [[Installation]] | Deploying, rebasing, verifying the signature, first login |
| [[Architecture]] | How the image is built: BlueBuild pipeline, module order, repo layout |
| [[Recipe-Modules]] | Every module in `recipes/recipe.yml`, with the why behind each one |
| [[Packages]] | Everything baked into the image, categorized |
| [[Third-Party-Repos]] | Terra/COPR usage, repo priorities, the repo-scoping pitfall and its fix |
| [[Updates-and-Rollback]] | uupd, greenboot, rpm-ostreed policy, update/rebase/rollback workflows |
| [[Gaming-Stack]] | ogc kernel, NVIDIA, sched-ext, gamescope, Proton/Wine tooling, system tuning |
| [[ujust-Recipes]] | Complete `ujust` command reference (shared + bazzfin-specific) |
| [[SELinux]] | SELinux tooling shipped, policy workarounds, and the ostree util.py patch |
| [[Dotfiles-and-Shell]] | chezmoi, /etc/skel, zsh default shell, Homebrew, Doom Emacs, Home Manager |
| [[Bazzfin-Portal]] | The GTK3 portal: declarative YAML-driven management app, Bazaar integration |
| [[Troubleshooting]] | Known build/runtime issues and how they were solved |
| [[CI-CD]] | GitHub Actions build, cosign signing, secrets, Renovate |
| [[Local-Development]] | Building locally, validating, linting, contributing conventions |

---

## At a glance

| | |
| - | - |
| **Base image** | `ghcr.io/ublue-os/base-main` (desktop-free), currently Fedora 44 |
| **Kernel** | Bazzite's "ogc" gaming kernel (Open Gaming Collective), staged from `ghcr.io/ublue-os/akmods:ogc-44` |
| **GPU driver** | NVIDIA (open) via the BlueBuild `akmods` module |
| **Compositor** | Hyprland (git) from the `lionheartp/Hyprland` COPR |
| **Display manager** | ly (tty2) |
| **Shell** | zsh (forced for all real users at deploy time) |
| **Updates** | uupd (system + Flatpak + Homebrew + distrobox) with greenboot boot health checks |
| **Image tags** | `ghcr.io/aahsnr-work/bazzfin:44` (pinned) and `:latest` |
| **Signing** | cosign, public key committed as `cosign.pub` |
