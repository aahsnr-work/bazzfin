# Instructions: setting the GitHub description and topics for halcyon

This file explains how to set the two pieces of metadata that appear on
the repository's main page: the **description** (the one-line "About"
text) and the **topics** (the blue keyword pills shown under "About").

The descriptions themselves live in `DESCRIPTIONS.txt`.

---

## 1. The description (the "About" one-liner)

The About field is **plain text only** -- GitHub does not render Markdown
there, so asterisks, backticks and headings would show up literally.
Just paste one of the four descriptions from `DESCRIPTIONS.txt` as-is.

Steps:

1. Open the repository page on github.com.
2. In the top-right corner of the page, to the right of "About", click
   the **gear icon** (Edit repository details).
3. Paste the chosen description into the **Description** field.
4. Optionally fill in **Website** and **Topics** (see below).
5. Click **Save changes**.

CLI alternative (GitHub CLI), using description #1:

    gh repo edit --description "An atomic Linux image that boots into Hyprland with NVIDIA drivers, a gaming kernel, and nothing left to configure. Rebuilt daily -- calm, by definition."

---

## 2. Topics (the keyword pills)

Topics are how GitHub classifies the repository for search and browsing
(github.com/topics/<name> pages list every repo tagged with a topic).

### Official rules (from GitHub's docs)

When creating a topic:

- Use lowercase letters, numbers, and hyphens.
- Use 50 characters or less.
- Add no more than 20 topics.

Topic names are always public, even if the repository is private.

### How to add them (web UI)

1. Open the repository page on github.com.
2. In the top-right corner of the page, to the right of "About", click
   the **gear icon**.
3. Under **Topics**, start typing a topic -- a dropdown of matching
   existing topics appears. Click a match to use it, or keep typing and
   press Enter to create a new topic.
4. Repeat for each topic below, then click **Save changes**.

### How to add them (CLI / API)

Topics are replaced as a whole set, not appended:

    gh api --method PUT /repos/aahsnr-work/halcyon/topics \
      -f 'names[]=atomic' -f 'names[]=bluebuild' \
      -f 'names[]=bluebuild-image' -f 'names[]=custom-image' \
      -f 'names[]=image-based' -f 'names[]=immutable' \
      -f 'names[]=linux' -f 'names[]=linux-custom-image' \
      -f 'names[]=oci' -f 'names[]=oci-image' \
      -f 'names[]=operating-system' -f 'names[]=fedora-atomic' \
      -f 'names[]=universal-blue' -f 'names[]=hyprland' \
      -f 'names[]=wayland' -f 'names[]=nvidia' \
      -f 'names[]=gaming' -f 'names[]=linux-gaming' \
      -f 'names[]=dotfiles' -f 'names[]=bootc'

(Adjust `aahsnr-work/halcyon` if the repository is renamed.)

---

## 3. Recommended topic set for halcyon (exactly 20)

Kept from the screenshot's discovery staples, then extended with the
project's actual identity:

| # | Topic | Why |
|---|-------|-----|
| 1 | `atomic` | rpm-ostree/bootc atomic model -- core keyword |
| 2 | `bluebuild` | the build system this repo uses |
| 3 | `bluebuild-image` | ecosystem tag for BlueBuild-built images |
| 4 | `custom-image` | discovery staple for custom OS images |
| 5 | `image-based` | discovery staple |
| 6 | `immutable` | the defining delivery property |
| 7 | `linux` | broadest reach |
| 8 | `linux-custom-image` | ecosystem tag for personal images |
| 9 | `oci` | OCI standard |
| 10 | `oci-image` | ecosystem tag |
| 11 | `operating-system` | discovery staple |
| 12 | `fedora-atomic` | what the base actually is (base-main on Fedora) |
| 13 | `universal-blue` | the ublue ecosystem -- biggest adjacent community |
| 14 | `hyprland` | the compositor -- the most-searched identity term |
| 15 | `wayland` | protocol family Hyprland belongs to |
| 16 | `nvidia` | open NVIDIA drivers shipped in-image |
| 17 | `gaming` | the ogc kernel, Steam, MangoHud, scx |
| 18 | `linux-gaming` | popular existing topic for gaming on Linux |
| 19 | `dotfiles` | chezmoi-managed dotfiles are part of the image |
| 20 | `bootc` | the bootc/Containerfile build path BlueBuild generates |

Deliberately left out: `bazzite`, `bluefin`, `aurora` (those classify
the upstreams, not this image), and `fedora` (too broad at 20/20; add it
only by dropping a weaker tag such as `image-based`).
