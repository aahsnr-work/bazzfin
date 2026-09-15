# Architecture

## The pipeline

```
recipes/recipe.yml  (declarative: base image + ordered BlueBuild modules)
        |
        v  (bluebuild generate)
Containerfile       (generated, never hand-maintained)
        |
        v  (blue-build/github-action@v1.12 on push/PR/daily cron)
OCI image           (built with podman/buildah in CI)
        |
        v
cosign-signed image pushed to ghcr.io/aahsnr-work/bazzfin
        |
        v  (bootc switch / rpm-ostree rebase on target machines)
Fedora Atomic deployment
```

Everything that defines the image lives in **one file**:
`recipes/recipe.yml` (validated against the
[recipe-v1 schema](https://schema.blue-build.org/recipe-v1.json)).

## Design principles

- **Declarative and ordered.** The module order in the recipe is the build
  order; every module comment explains *why* it exists and *why* it sits where
  it sits.
- **Fail loud, not silent.** Sanity checks are baked in — e.g. the build fails
  if the base image stops shipping `/usr/share/ublue-os/justfile` (the
  `ublue-os-just` package that provides `ujust`).
- **Idempotent, digest-gated runtime scripts.** The first-boot helpers
  (`set-default-shell`, `brew-package-setup`) record the booted deployment
  digest and only re-scan when `ujust rebase`/`ujust update` lands a *new*
  deployment — never on ordinary reboots.
- **No hand-maintained Containerfile.** It is generated from the recipe
  (`just generate`).
- **Third-party repos are transient.** COPRs and repo files added by a dnf
  module are removed at the end of that module (`repos.cleanup: true`) so
  nothing shadows Fedora in the shipped image — see [[Third-Party-Repos]].
- **Same mechanisms as Bazzite.** Kernel swap, gamescope, system management,
  SELinux tweaks all mirror how Bazzite's own `Containerfile` does it.

## Repository layout

```
.
├── recipes/recipe.yml            # The whole build, declared as BlueBuild modules
├── files/
│   ├── dnf/                      # Local .repo files for the `dnf` module (vscode.repo)
│   ├── justfiles/                # ujust recipes shipped in the image
│   │   ├── 10-rebase.just        #   rebase/update-image
│   │   ├── 20-doom.just          #   doom-setup
│   │   ├── 30-home-manager.just  #   home-manager-setup
│   │   ├── 40-gaming.just        #   toggle-scx, fix-reset-steam, protontricks
│   │   └── 50-system.just        #   status, rollback, cockpit, toggle-bpftune
│   ├── scripts/                  # Build-time scripts (ogc kernel, upstream apps, global-remove)
│   └── system/                   # Copied verbatim to / by the `files` module
│       ├── etc/                  #   rpm-ostreed.conf, scx_loader config, zram, nix, profile.d
│       └── usr/                  #   sysctl.d, udev rules, modprobe, dracut, libexec helpers
├── dotfiles/                     # chezmoi source (dot_config, ...) applied to /etc/skel
├── .github/
│   ├── workflows/build.yml       # Build + publish + sign on push/PR/daily cron
│   └── renovate.json5            # Renovate (github-actions; custom ogc-<fedora> bump)
├── Justfile                      # Local dev helpers (wraps the BlueBuild CLI)
├── cosign.pub                    # Public key for verifying deployed images
└── wiki/                         # This wiki (published to the GitHub wiki)
```

## Key runtime components

| Component | Where it comes from | Notes |
| --------- | ------------------- | ----- |
| `ujust` | `ublue-os-just` RPM (base image) + `files/justfiles/*.just` | Shared Universal Blue core + bazzfin extras; see [[ujust-Recipes]] |
| `set-default-shell` | `files/system/usr/libexec/hyprland-image/` | Forces zsh; digest-gated, runs pre-login |
| `brew-package-setup` | same | Installs `/etc/hyprland-image/brew-packages` per user |
| chezmoi init/update services | `chezmoi` module + `dotfiles/` | Applied at build time to `/etc/skel`; services keep it updated |
| uupd + greenboot | system-management dnf module | Automatic updates + boot health checks; see [[Updates-and-Rollback]] |

## Image metadata

The build writes `/usr/share/ublue-os/image-info.json` (image name, vendor,
version, digest). Runtime recipes (`ujust rebase`, `ujust rollback`) read it
to discover the exact image reference — nothing is hard-coded on the machine.
