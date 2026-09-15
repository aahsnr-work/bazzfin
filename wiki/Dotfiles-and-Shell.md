# Dotfiles and Shell

## chezmoi

The `chezmoi` module registers `https://github.com/aahsnr-work/bazzfin` (the
`dotfiles/` directory of this repo) with `file-conflict-policy: replace`, and
installs the `chezmoi-init` / `chezmoi-update` systemd user services so the
dotfiles keep themselves current on the deployed machine.

The comment block in the recipe also sketches an alternative that isn't
enabled: pre-seeding `/etc/skel` at build time
(`HOME=/etc/skel chezmoi init --apply --force --no-tty ...`) so brand-new users
get the dotfiles instantly at first login. See TODO.md for the open question
around combining `/etc/skel` seeding with selective chezmoi application.

## zsh as the login shell

`set-default-shell.service` (system unit, enabled) runs
`/usr/libexec/hyprland-image/set-default-shell` **before any login is
permitted** (ordered before `systemd-user-sessions`). Why it is built the way
it is:

- `chsh` is unreliable on atomic images (some bases strip it, and it wants an
  interactive PAM password prompt), so the script uses `usermod` directly —
  the approach the Universal Blue community recommends.
- It ensures **zsh** for root and every real local (human) user. Root is
  normally disabled and used via `sudo -i` — it still gets zsh so `sudo -i`
  lands in the same environment.
- **Digest-gated**: it records the booted deployment digest and only re-scans
  when `ujust rebase`/`ujust update` lands a *new* deployment — ordinary
  reboots do nothing.
- **Fails safe**: if the deployment can't be determined (missing
  bootc/rpm-ostree/jq), it re-scans rather than skipping forever.
- Because it finishes before `systemd-user-sessions`, the shell is correct
  before the first login of that boot — effectively "fixed exactly once per
  rebase", without any login-time privilege plumbing.

## Homebrew

- The `brew` module installs Homebrew itself plus update/upgrade timers
  (update every 6h with a 10m post-boot wait; upgrade every 8h with a 30m
  wait).
- `brew-packages-setup.service` (user unit, enabled) runs
  `/usr/libexec/hyprland-image/brew-package-setup`, which installs every
  package listed in `/etc/hyprland-image/brew-packages`.
- Same idempotent, digest-gated design as `set-default-shell`: it only
  installs what's missing, and the scan is skipped unless the deployment
  changed. The state marker lives in the user's XDG state dir (the unit runs
  unprivileged).
- Add packages by editing `/etc/hyprland-image/brew-packages` **in the repo**
  (`files/system/etc/hyprland-image/brew-packages`) — it's an `/etc` file
  baked into the image, so it changes on the machine only after a rebase.

## Doom Emacs (opt-in)

`ujust doom-setup` (group `doom`): one-time bootstrap — clones
`aahsnr-configs/doom` to `~/.config/doom`, writes a literate init line, clones
doomemacs/core to `~/.config/emacs`, runs `doom install` + `doom sync`.
Aborts safely if `~/.config/doom` already exists.

## Nix + Home Manager (opt-in)

The image bakes in **system nix** (`nix` + `nix-daemon` packages, `nix.mount`,
`nix-daemon` enabled, config in `etc/nix/nix.conf`, PATH wiring via
`etc/profile.d/00-nix-resolve-home-env.sh`, state via
`usr/lib/tmpfiles.d/nix.conf`).

`ujust home-manager-setup` (group `nix`): one-time standalone Home Manager
bootstrap via `nix run home-manager/master -- init --switch`. Aborts if
`~/.config/home-manager` already exists (use `home-manager switch` to update).
