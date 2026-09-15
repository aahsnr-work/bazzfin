# Third-Party Repos

How bazzfin uses repositories beyond Fedora, and the pitfalls that come with
them (this page documents issues that actually broke the build — see
[[Troubleshooting]]).

## Repos in use

| Repo | How it's added | Used for | Stays on the image? |
| ---- | -------------- | -------- | ------------------- |
| Terra (`terra`) | repo file added by the dnf modules (removed by `cleanup: true`) | terra-gamescope/-libs, zed, umu-launcher/-wrapper, 8bitdo-udev-rules, bpftune-gaming | No |
| Terra extras (`terra-extras`) | `/etc/yum.repos.d/terra-extras.repo`, shipped by the `terra-release-extras` **package** | terra-gamescope lives here | **Yes** — enabled, `priority=150` |
| COPR `ublue-os/packages` | `repos.copr` + `cleanup: true` | `uupd`, `ublue-os-selinux-workarounds` | No |
| COPR `bieszczaders/kernel-cachyos-addons` | same | `scx-scheds`, `scx-tools` | No |
| COPR `lionheartp/Hyprland` | same | `hyprland-git`, portal, etc. | No |
| COPR `sneexy/zen-browser` | same | `zen-browser` | No |
| Brave / VS Code repo files | `repos.files` + keys | `brave-browser`, `code` | No |
| Flathub | `default-flatpaks` module | user Flatpaks | Yes (standard) |

## The priority model

- Fedora/updates: default priority (50).
- `terra-extras`: **priority=150** (higher number = *lower* precedence), set
  by Terra upstream. Any dependency both Terra-extras and Fedora provide is
  won by **Fedora** — by design. Terra-extras deliberately contains packages
  that conflict with Fedora (its own zlib, patched WINE, ...), which is why it
  ships a lower precedence rather than relying on repo ordering.
- The terra *main* repo has no priority override; bazzfin never leaves it
  enabled on the shipped image.

## `cleanup: true` semantics

`repos.cleanup: true` removes only the repos **the module added** (repo files
and COPRs). A repo file that arrives **inside a package** — like
`terra-extras.repo` from `terra-release-extras` — persists. Decide
deliberately which third-party repos stay enabled on the shipped image (here:
terra-extras stays, so terra packages keep updating on the deployed machine,
at priority 150 so Fedora always wins conflicts).

## The repo-scoping pitfall (read before adding packages)

BlueBuild executes every repo-scoped package entry

```yaml
- type: dnf
  install:
    packages:
      - repo: terra-extras     # <- the trap
        packages: [terra-gamescope]
```

as

```bash
dnf5 -y --setopt=install_weak_deps=False install --repoid terra-extras terra-gamescope
```

In dnf5, `--repoid` confines the **whole transaction — dependency resolution
included — to that single repo**. Fedora is invisible while it runs. A package
whose dependencies (SDL2, X11, glib, ...) live in Fedora becomes
unresolvable; the solver then falls through to any i686 multilib builds the
third-party repo ships, which fail even harder (`nothing provides
libSDL2-2.0.so.0 ... i686 from terra-extras`). This bit the build repeatedly
terra-gamescope was the first victim).

### Rules

1. **Only use `repo:`-scoped entries** for repo bootstrap/release packages
   (`terra-release-extras`, ...) or true leaf packages whose entire dependency
   closure lives in that repo (`code`, `brave-browser`).
2. **Everything else goes in the plain `packages:` list** with the repo
   enabled via `repos.files:`/`repos.copr:` — the solver then sees all
   repos and picks dependencies from Fedora.
3. **Bootstrap repos in an earlier dnf module.** BlueBuild installs all plain
   string packages in one transaction first, then each `repo:` object in its
   own transaction, in list order. A package installed in one transaction
   cannot make a repo visible to another transaction in the *same* module —
   that's why `terra-release-extras` is installed in the main module and the
   terra *packages* install in a separate module.
4. **Guard conflicting sub-repos with `exclude:`.** The terra module pins
   `exclude: [zlib]` (the same fix zirconium ships) so the solver can never
   pull terra's zlib over Fedora's. Extend the list if terra-mesa/multimedia
   are ever enabled — Terra's own docs warn those conflict with RPM Fusion
   and Fedora.
5. **Recognize the failure signature:** every solver line saying `from
   <third-party-repo>` and/or `nothing provides <lib>.so needed by
   <pkg>.i686 from <repo>` means repo-confined resolution — fix the scoping,
   not the package list.

## Package-source gotchas found the hard way

- `bpftune-gaming` lives in the **terra** repo — not in any ublue COPR
  (verified against the COPR repodata). Bazzite relies on the same fact via
  its `*terra*.priority=1` setup.
- COPRs must have a chroot for the image's Fedora release; a missing one
  fails with `No match for argument`. Verify a COPR's contents at
  `https://download.copr.fedorainfracloud.org/results/<owner>/<repo>/fedora-<N>-x86_64/`.
