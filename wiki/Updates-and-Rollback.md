# Updates and Rollback

bazzfin ships Bazzite's update architecture: **uupd owns automatic updates**,
**greenboot guards the boots**, and rpm-ostreed's own automatic-update timer
is out of the way.

## The update stack

| Component | Role | State on the image |
| --------- | ---- | ------------------ |
| `uupd` (COPR `ublue-os/packages`) | One update pass over: system image (bootc/rpm-ostree), Flatpaks, Homebrew, distrobox | installed |
| `uupd.timer` | Runs `uupd.service` periodically (hardware checks first: battery, CPU/mem load, network) | **enabled** |
| `/etc/uupd/config.json` | Per-module switches (`brew`, `distrobox`, `flatpak`, `system`) | defaults |
| `rpm-ostreed` | Native automatic updates | policy `AutomaticUpdatePolicy=none` (`/etc/rpm-ostreed.conf`), `rpm-ostreed-automatic.timer` **masked** |
| `greenboot` + health checks | Runs `greenboot-healthcheck.service` at boot; on failure can roll back to the previous deployment; `greenboot-set-rollback-trigger.service` arms the rollback marker | **enabled** |

Why: uupd's README requires `AutomaticUpdatePolicy` != `stage` on
uBlue-main-derived images so rpm-ostreed's automatic timer never fights uupd
(both changes ship in the image: the config file via the `files` module, the
mask via the `systemd` module — belt and braces).

## The shared recipes just work

`ujust` is provided by `ublue-os-just` (base image) and its recipes are
**uupd-aware**:

- `ujust update` — if `uupd.timer` is enabled, starts `uupd.service` and
  streams its progress; otherwise falls back to manual
  `rpm-ostree update` + `flatpak update` + `distrobox upgrade`.
- `ujust toggle-updates` — enable/disable automatic updates (drives
  `uupd.timer` when it exists, the rpm-ostreed/flatpak timers otherwise).
- `ujust changelogs` — rpm-ostree changelog diff.
- `ujust update-firmware` — fwupd refresh/update.

## Rebasing to a new build

```bash
ujust rebase          # or: ujust update-image
ujust rebase 44       # rebase to a specific tag
```

Reads `/usr/share/ublue-os/image-info.json` for the exact image reference
(nothing hard-coded), then `bootc upgrade` (or `rpm-ostree upgrade`), or
`bootc switch` / `rpm-ostree rebase` for a specific tag. A reboot applies it.

## Rolling back

```bash
ujust rollback
```

`bootc rollback` (or `rpm-ostree rollback`) stages the previous deployment,
then offers to reboot into it. After the reboot, greenboot's health checks
guard the boot; if they fail, greenboot can automatically roll forward back.

Useful companions: `ujust status` (current bootc/rpm-ostree deployment),
`rpm-ostree status`, `journalctl -exu uupd.service` (uupd logs), and
greenboot's `journalctl -b -u greenboot-healthcheck.service`.

## Tuning uupd

Edit `/etc/uupd/config.json` to disable modules or relax hardware checks
(e.g. lower `bat-min-percent` on an always-plugged machine). Changes survive
rebases only if re-applied (they live in `/etc`, which is a persistent merge
of image + local changes — local edits persist but are *not* baked into new
image builds).
