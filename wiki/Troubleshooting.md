# Troubleshooting

Real issues hit during bazzfin's development and how they're solved. Build
failures are easiest to read from the GitHub Actions log — the failing dnf
transaction is printed verbatim before the module error.

## Build failures

### Repo-scoped dependency resolution (the recurring one)

**Symptom:** every solver line says `from <third-party-repo>`; errors like

```
package terra-gamescope-libs ... from terra-extras requires terra-gamescope = ...,
  but none of the providers can be installed
nothing provides libSDL2-2.0.so.0 needed by terra-gamescope-...i686 from terra-extras
```

**Cause:** BlueBuild runs `repo:`-scoped package entries as
`dnf install --repoid <repo>`, which confines dependency resolution to that
single repo. Fedora is invisible; the solver then falls through to the
third-party repo's i686 multilib builds.

**Fix:** install the packages unscoped with the repo enabled via
`repos.files:`/`copr:` — see the full rules in [[Third-Party-Repos]].

### `No match for argument: <package>`

The package doesn't exist in any enabled repo for the image's Fedora release.
Two real cases:

- `bpftune-gaming` — lives in the **terra** repo, not in any ublue COPR
  (checked COPR repodata directly). It's installed in the terra module now.
- A COPR without a chroot for the current Fedora release. Check
  `https://download.copr.fedorainfracloud.org/results/<owner>/<repo>/fedora-<N>-x86_64/`
  before adding a COPR package; drop the package or pick another source.

### `Package X is already installed` in a failed transaction

Informational — dnf lists it as a note next to the real error. If it's the
only complaint, the install is a harmless no-op.

### The build fails on `/usr/share/ublue-os/justfile missing`

The base image stopped shipping `ublue-os-just` (the sanity check in the
third module fails the build on purpose). Pin/re-add the package or switch
base — `ujust` itself depends on it.

## Runtime

### Brave takes a while on first launch / /opt questions

Brave's RPM installs into `/opt`, which doesn't exist as a real directory on a
fresh ostree tree — the build normalizes it (`mkdir -p /usr/lib/opt` + symlink
fix in the third module). First-launch sluggishness is usually font/cache
creation on the first run; if it persists, investigate whether the
`/opt` handling survived the rebase (`ls -la /opt`).

### sealert doesn't start under Hyprland

Expected: Hyprland doesn't process `/etc/xdg/autostart`. Use the CLI —
`sudo sealert -l '*'`, `ausearch -m avc -ts recent` — or add
`exec-once = sealert -b` to the Hyprland config. See [[SELinux]].

### NVIDIA modules fail to load after a rebase

Secure Boot is enabled and the akmods key isn't enrolled: run
`ujust enroll-secure-boot-key` and reboot.

### Updates misbehaving

- uupd logs: `journalctl -exu uupd.service`.
- Make sure `uupd.timer` is enabled (`systemctl status uupd.timer`) and
  `rpm-ostreed-automatic.timer` stays masked — uupd owns updates
  (`/etc/rpm-ostreed.conf`: `AutomaticUpdatePolicy=none`).
- Manual full pass: `ujust update`.

### Boot problems / suspected bad deployment

greenboot runs health checks at boot and arms a rollback trigger. Inspect:

```bash
systemctl status greenboot-healthcheck.service
journalctl -b -u greenboot-healthcheck.service
ujust status     # which deployment is running
ujust rollback   # stage going back one deployment
```

### Which repos are on the system?

The build cleans up every repo it added (module-scoped `cleanup: true`).
Expected on a deployed machine: the Fedora/updates sets, **terra-extras**
(priority 150 — Fedora wins conflicts; needed so terra packages keep
updating), and Flathub. Anything else appearing in `/etc/yum.repos.d/` should
be investigated (see the open log-audit TODO item).

## Things deliberately not done (and why)

- **kitty from the Hyprland COPR** — rejected: kitty must come from Fedora.
- **hyprland from Fedora / non-git** — the recipe uses `hyprland-git` from the
  lionheartp COPR (pkg manifests track which packages may only come from the
  COPR).
- **AMD/Framework hardware packages** — this is an Intel machine; see
  [[Packages]].
