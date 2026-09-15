# Bazzfin Portal

A GTK3 configuration tool in the spirit of [Bazzite's Portal](https://docs.bazzite.gg/Installing_and_Managing_Software/Bazzite_Portal/)
(which is [yafti-gtk](https://github.com/ublue-os/yafti-gtk) driven by a
`yafti.yml`). bazzfin's version is a small PyGObject app generated from a
**declarative YAML config**, so adding new actions/toggles needs **no code**.

- App: `files/system/usr/bin/bazzfin-portal`
- Config: `files/system/usr/share/bazzfin-portal/portal.yml` → installed at
  `/usr/share/bazzfin-portal/portal.yml`
- Launcher: `bazzfin-portal` (desktop entry `bazzfin-portal.desktop`)

## What's in it (default cards)

| Category | Cards |
| -------- | ----- |
| Welcome | Open the wiki, open `recipes/recipe.yml` |
| Software | **Bazaar** (the Flathub app store — installed from the `ublue-os/packages` COPR), install ProtonUp-Qt / Bottles / Discord (Flathub) |
| Manage bazzfin | `ujust update`, automatic-updates toggle (uupd), deployment status, `ujust rebase`, `ujust rollback`, `ujust fix-reset-steam`, Cockpit toggle |
| Tweaks | sched-ext (`toggle-scx`), bpftune (`toggle-bpftune`), Doom Emacs setup, Home Manager setup |

## How it works

1. `portal.yml` declares `categories` → `items` → `options`:

   ```yaml
   - id: auto-updates            # unique item id
     title: Automatic updates
     description: Enable or disable the uupd timer.
     status_script: systemctl is-enabled --quiet uupd.timer
     options:
       - id: enable
         label: Enable
         script: ujust toggle-updates enable
   ```

2. Each item renders as a **card**: title, description, an optional **status
   chip** (from the read-only `status_script` — exit 0 = *installed/active*;
   refreshed on page switch and via the refresh buttons), and one **button per
   option**.
3. Action `script`s run **detached in a kitty window** (`kitty -e bash -lc ...
   `, with `foot`/`wezterm`/`alacritty`/`xterm` fallbacks) so output and any
   sudo prompt stay visible. Set `terminal: false` on an item for
   fire-and-forget GUI commands (`xdg-open ...`, `bazaar`).
4. Status scripts run **off the UI thread** (subprocess + `GLib.idle_add`),
   20 s timeout, so a hung check can't freeze the window.

### Config schema

| Field | Required | Meaning |
| ----- | -------- | ------- |
| `categories[].id` / `.title` | yes | Page identity in the sidebar |
| `items[].id` / `.title` / `.description` | yes | Card identity/body |
| `items[].status_script` | no | Read-only probe; exit 0 = active/installed |
| `items[].terminal` | no | Default `true`; set `false` for GUI fire-and-forget commands |
| `items[].options[].id` / `.label` / `.script` | yes | Button definitions |

## Why these choices

- **GTK3** — the base image ships both `gtk3` and `gtk4`; GTK3 + PyGObject is
  the lowest-dependency path and the base has `python3-gobject` +
  `python3-pyyaml` already. (Note: the app pins *both* `Gtk 3.0` and
  `Gdk 3.0` — with gtk4 also installed, an unpinned Gdk import would resolve
  to 4.0 and crash at import.)
- **No polkit agent** — this desktop-free Hyprland image ships no polkit
  authentication agent, so GUI privilege prompts aren't available; running
  actions in a visible terminal is the honest approach (Bazzite's portal runs
  ujust scripts the same way).
- **Bazaar via RPM (COPR)** rather than Flathub: the `ublue-os/packages` COPR
  is already enabled for `uupd`, ships a f44 build (verified), and a system
  RPM integrates with the desktop entry database directly. The Flathub build
  (`io.github.kolunmi.Bazaar`) auto-updates via uupd if you prefer — swap the
  install line in the recipe.

## Adding a card

Append an item to a category (or a whole category) in
`files/system/usr/share/bazzfin-portal/portal.yml`, following the schema
above — the next build ships it; no Python changes. Keep scripts idempotent
(`ujust ...-setup` recipes already are).
