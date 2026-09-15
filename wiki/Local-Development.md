# Local Development

## Setup

Install the [BlueBuild CLI](https://blue-build.org/how-to/local/) (e.g.
`cargo install --locked blue-build`), `just`, `shellcheck`, and
podman/buildah.

## Daily commands (Justfile)

```bash
just validate   # check recipes/recipe.yml against the BlueBuild schema
just generate   # print/save the generated Containerfile (never edit it by hand)
just build      # build the image locally (podman/buildah)
just switch     # build, then rebase THIS machine onto the local build
just lint       # shellcheck files/scripts/*.sh
just wiki-push  # publish wiki/ to the GitHub wiki (see below)
```

For quick iteration on just files:
`just --justfile files/justfiles/<file>.just --list`.

## Editing the recipe

- All changes go in `recipes/recipe.yml` (schema-validated; the
  `# yaml-language-server` header gives editor completions).
- Keep the comment blocks: every non-obvious module carries the *why* (see
  [[Recipe-Modules]] for the pattern).
- Run `just validate` before pushing; CI validates and builds on PRs too.

## Adding a package (checklist)

1. **Which repo has it?** Check
   `https://download.copr.fedorainfracloud.org/results/<owner>/<repo>/fedora-<N>-x86_64/`
   for COPRs, or the Terra index for terra packages. Verify the package name
   against the repo's **primary metadata**, not its web page.
2. **Add it to the right module** (see [[Recipe-Modules]]): Fedora packages →
   main module; terra packages → terra module (unscoped); COPR packages → a
   module that enables that COPR.
3. **Never repo-scope** a package whose dependencies may live in Fedora —
   rules in [[Third-Party-Repos]]. Repo-scope only bootstrap/leaf packages.
4. If the package's repo ships packages that conflict with Fedora, extend the
   module's `exclude:` list (see the zlib guard).
5. `just validate` + push; watch the CI dnf transaction output for
   `No match for argument` (missing in the enabled repos) or the repo-scoped
   failure signature.

## Conventions

- Build-time scripts in `files/scripts/` must pass `just lint` (shellcheck).
- Runtime helpers live in `files/system/usr/libexec/hyprland-image/` and
  follow the idempotent, deployment-digest-gated pattern (`set-default-shell`,
  `brew-package-setup`) — copy that pattern for anything that must run again
  after a rebase.
- Config files go under `files/system/...` mirroring their absolute path.
- Anything non-obvious gets a comment in `recipe.yml` explaining *why*, and —
  if it's user-facing — a page here in the wiki.

## Publishing the wiki

The wiki source of truth is `wiki/` in this repo. To publish to the GitHub
wiki:

```bash
just wiki-push
```

(Requires `gh` authenticated or push access to
`git@github.com:aahsnr-work/bazzfin.wiki.git`. The target clones the wiki
repo, copies `wiki/*.md` over it, commits and pushes. The wiki is created on
first publish; alternatively initialize it once via the GitHub UI → wiki →
create first page.)

## Testing a build locally

```bash
just build        # ~30-60 min first time; layer caching helps after
just switch       # build + rebase this machine (careful: your machine)
```

CI runs the same recipe on every push/PR — prefer opening a PR to test
rather than switching your daily driver onto an unverified build.
