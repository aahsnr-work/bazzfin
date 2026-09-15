# SELinux

The base image ships the core SELinux policy stack; bazzfin adds Bazzite's
SELinux tooling and two verified fixes needed on ostree/bootc systems.

## What the base image already provides (audited)

`selinux-policy` + `selinux-policy-targeted` (the policy itself),
`policycoreutils` + `policycoreutils-python-utils` (`semanage`/`semodule` —
used by the build's own snippets), `checkpolicy`, `libselinux(-utils)`,
`python3-setools`, `container-selinux`, `flatpak-selinux`, `rpm-plugin-selinux`,
`smartmontools-selinux`, `passt-selinux`.

## What bazzfin adds (system-management dnf module)

| Package | Role |
| ------- | ---- |
| `setroubleshoot` | `sealert` frontend for analyzing AVC denials |
| `setroubleshoot-server` | `setroubleshootd` system service + audit-database analysis |
| `setroubleshoot-plugins` | Denial-analysis plugins for sealert |
| `setools-console` | CLI policy audit tools: `sesearch`, `seinfo`, ... |
| `udica` | Generate SELinux policies for containers from their runtime spec |
| `ublue-os-selinux-workarounds` | Custom policy module (`ublue_os_composefs_execmem`): mitigation for Linux 7.0 composefs/overlay backing-file mmap checks flagging legitimate execmem mappings as `kernel_t` |

Note on provenance (verified against the Fedora 44 RPMs and Bazzite's build):
Bazzite **never installs** setroubleshoot itself — its `cockpit-selinux`
package has a hard dependency on `setroubleshoot-server >= 3.3.3`, so the
backend arrives implicitly (the `sealert` frontend does not). bazzfin ships
the full trio explicitly so both the backend and the frontend exist on a
desktop-free base.

## The ostree `util.py` patch (build-time)

`setroubleshoot`'s `util.py` (`get_store_root()`) reads
`/etc/selinux/semanage.conf` for a `store-root` parameter and **falls back to
the hardcoded `/var/lib/selinux`** otherwise. On Fedora 44, `semanage.conf`
sets no `store-root` — so on ostree/bootc systems, where the policy store
lives under `/etc/selinux`, `setroubleshootd` would look in the wrong place
and fail to analyze denials.

The build therefore applies Bazzite's exact fix after the packages install:

```bash
sed -i 's#/var/lib/selinux#/etc/selinux#g' \\
  /usr/lib/python3.*/site-packages/setroubleshoot/util.py
```

(guarded — it only runs if the file exists). The same sed is in Bazzite's own
finalize stage. `util.py` belongs to `setroubleshoot-server`; on Fedora 44 it
lives under `/usr/lib/python3.14/site-packages/setroubleshoot/`.

## ly's label (build-time)

`/usr/bin/ly` gets `xdm_exec_t` via `semanage fcontext` + `restorecon` so the
login manager starts cleanly under enforcing SELinux.

## Using it under Hyprland

The sealert applet normally autostarts via `/etc/xdg/autostart`, which Hyprland
does not process. Use the CLI instead:

```bash
sudo sealert -l '*'          # analyze all recent denials
sealert -b                   # start the applet manually if wanted
ausearch -m avc -ts recent   # raw AVC history (audit)
journalctl -t setroubleshoot # setroubleshootd log
```

or add `exec-once = sealert -b` to your Hyprland config. The Cockpit SELinux
page (after `ujust cockpit`) presents the same denials in the browser.
