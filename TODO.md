# TODO

- [ ] Make sure the order of operations in the recipe.yml is correct and using best practices (verified 2026-09-15 — see "Verified audit" in changes.md)
- [x] Determine how https://github.com/fu5ha/winter and https://github.com/fu5ha/nix-home-manager implement nix on top of the oci image.
- [x] kitty* packages must not be installed from hyprland copr
- [ ] Determine if there is a way to bake my dotfiles directly into my custom image by putting them in /etc/skel from aahsnr-configs/dots and then make chezmoi selectively apply the config files into the home folder.
- [x] make zsh the default shell when building the image
- [x] integrate bazzite gaming related features and functionalities (done 2026-09-15: terra-gamescope/terra-mangohud from terra-extras, scx-scheds/scx-tools + scx_loader, umu-launcher, winetricks, input-remapper, 8bitdo-udev-rules, ntsync module preload, disk-scheduler udev rule, UserspaceHID bluetooth tweak, Steam/Lutris/Heroic/protontricks/ProtonPlus + MangoHud/vkBasalt VulkanLayer flatpaks, fix-reset-steam/toggle-scx/protontricks ujust recipes -- see the gaming dnf module in recipes/recipe.yml)
- [x] integrate bazzite packages for system management and bazzite tooling system. (done 2026-09-15: uupd from ublue-os/packages COPR enabled by default via uupd.timer with rpm-ostreed AutomaticUpdatePolicy=none + rpm-ostreed-automatic.timer masked, greenboot + greenboot-default-health-checks boot health checks, ublue-os-selinux-workarounds, bpftune-gaming from the terra repo (NOT in any ublue COPR), Cockpit suite (off by default, ujust cockpit), Intel-scoped hardware/monitoring tier (lm_sensors, i2c-tools, iio-sensor-proxy, intel-gpu-tools, btop, duf, stress-ng, ydotool), and ujust rollback/status/cockpit/toggle-bpftune recipes in files/justfiles/50-system.just -- shared ublue-os-just's ujust update/toggle-updates drive uupd automatically)
- [x] Determine the ujust and just files are setup properly for the bazzfin project.
- [x] make zsh the default shell when building the custom image. search the web and determine how that can be done
- [ ] brave-browser is being detected in /usr/bin/brave-browser directory using which brave-browser but takes a while to show on the 1st try. What about the issue of brave-browser installing /opt directory during building image but that directly does not exist during the build?
- [ ] make sure important selinux packages since ublue-os base-image might not install them by default (partially addressed 2026-09-15: ublue-os-selinux-workarounds installed via the bazzite system-management dnf module; still worth auditing policy packages)
- [ ] determine if bluebuild's akmods module installs nvidia drivers from negativo17.org repos and if negativo17.org is enabled in the ublue-os/base-main image. It should be disabled after custom image is done build. Copr repo for akmods owned by ublue-os and negativo17.org nvidia repo should also be disabled after custom image is built.
- [x] Perform a final audit and review on `files/system/usr/libexec/hyprland-image/set-default-shell`, `files/system/usr/libexec/hyprland-image/brew-package-setup`, `files/systemd/system/set-default-shell.service`, `files/systemd/user/brew-packages-setup.service` in the bazzfin project to make sure there are no errors and issues and then rewrite the files again with any changes and corrections. Make sure to use best practices.
- [ ] Should sh scripts in /etc/profile.d/*.sh be executable?
- [x] Make sure packages from hyprland copr are only installed from the copr
- [ ] set-default-shell should only run once after user first logs in after rebase is done. Determine if that is even possible, otherwise you don't need to take any actions on this part. But make sure zsh be set default for both user and root account, assuming that root account is disabled and accessed using sudo -i.
- [ ] From the logs make sure all non-fedora repos are removed after package is installed from it. Also make sure that everything is correct and in order and that the github workflow performed without issues.
- [ ] Move global-remove.sh from scripts to recipe.yml
- [x] Either use https://github.com/ublue-os/uupd or ujust update bazzite ujust documentation (resolved 2026-09-15: chose uupd -- installed from the ublue-os/packages COPR and enabled by default; the shared ublue-os-just recipes already detect and drive it)
- [ ]

# `ujust:`

## Yes — but sharing happens at two different layers

### Layer 1: A genuinely shared core package (all three distros) ✅

The real "core set" is the **`ublue-os-just` RPM package** in [`ublue-os/packages`](https://github.com/ublue-os/packages/tree/main/packages/ublue-os-just) (`src/recipes/*.just`). This package is installed on **every Universal Blue image** — Bazzite, Bluefin, and Aurora — and ships these common recipes:

`update`, `changelogs`, `bios`, `bios-info`, `device-info`, `clean-system`, `logs-last-boot`, `logs-this-boot`, `enroll-secure-boot-key`, `setup-luks-tpm-unlock`, `remove-luks-tpm-unlock`, `toggle-updates`, `toggle-user-motd`, `toggle-nvk`, `check-idle-power-draw`, `check-local-overrides`, `update-firmware`, `setup-distrobox-app`, `distrobox-assemble`, `distrobox-new`, `install-resolve`, `configure-broadcom-wl`

This explains something I noticed earlier: `enroll-secure-boot-key` appears in **none** of Bazzite's 26 own `.just` files — it comes from this shared package (same for `bios`, `logs-last-boot`, `device-info`, etc. in Bluefin/Aurora).

### Layer 2: Bluefin ↔ Aurora share a forked recipe set ✅

`projectbluefin/common` (Bluefin) and `get-aurora-dev/common` (Aurora) are forks of the same codebase — same file names, and I diffed the actual contents:

- **Identical or near-identical:** `powerwash` is byte-for-byte the same; `update` bodies differ only trivially (`#!/usr/bin/bash` vs `#!/usr/bin/env bash`); `shared.just` differs by 1 line
- **~19 recipe names in common:** `update`, `changelogs`, `bios`, `bios-info`, `device-info`, `clean-system`, `logs-last-boot`, `logs-this-boot`, `powerwash`, `enroll-secure-boot-key`, `install-jetbrains-toolbox`, `install-opentabletdriver`, `jetbrains-toolbox`, `toggle-tpm2`, `toggle-updates`, `toggle-user-motd`, `benchmark`, `check-idle-power-draw`, `check-local-overrides`
- **Diverged:** `system.just` (637 lines differ — Bluefin's includes `bonedigger`, `install-asus`, `install-ai-tools`; Aurora's includes `toggle-tailscale`, `configure-boot-to-windows`, `rebase-helper`), plus `apps.just` and `default.just`

### Bazzite does NOT share the per-distro layer ❌

Bazzite's 96 recipes are its own, almost all namespaced (`bazzite-*` or domain-specific like `fix-reset-steam`, `setup-decky`, `configure-waydroid`). Only trivial name overlaps exist (`benchmark`, `configure-grub`). Bazzite predates the Bluefin/Aurora common-repo restructure and maintains its ujust scripts directly in `ublue-os/bazzite`.

### Bottom line

|             | Shared core (`ublue-os-just` pkg) | Bluefin/Aurora forked set        |
| ----------- | --------------------------------- | -------------------------------- |
| **Bazzite** | ✅ yes                            | ❌ no — own 96 recipes           |
| **Bluefin** | ✅ yes                            | ✅ yes (`projectbluefin/common`) |
| **Aurora**  | ✅ yes                            | ✅ yes (`get-aurora-dev/common`) |

So: **a small maintenance/update/troubleshooting core is truly shared by all three** via the `ublue-os-just` package, and Bluefin + Aurora additionally share a much larger forked recipe set between themselves — but there is no single shared upstream repo that all three distro-specific recipes flow from.
