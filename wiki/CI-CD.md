# CI/CD

## The workflow (`.github/workflows/build.yml`)

- **Triggers:** push to `main` (documentation-only changes ignored via
  `paths-ignore: **.md, docs/**`), pull requests, manual `workflow_dispatch`,
  and a daily cron at 06:00 UTC (shortly after the uBlue base images build).
- **Concurrency:** one build at a time per ref; in-progress runs are cancelled.
- **Build:** `blue-build/github-action@v1.12` with `maximize_build_space: true`
  (the build matrix lists `recipe.yml`; add entries for more images).
- **Signing:** the image is cosign-signed with the private key from the
  `SIGNING_SECRET` repository secret, then pushed to GHCR with
  `packages: write` + `id-token: write` permissions (declared inline — no
  extra setup beyond the secret).

## Signing setup (one time)

1. `COSIGN_PASSWORD="" cosign generate-key-pair` — generates `cosign.key` +
   `cosign.pub`. **The key must be unencrypted** (that's what
   `COSIGN_PASSWORD=""` guarantees): the private key is used inside Actions.
2. Commit `cosign.pub`; never commit `cosign.key` (it's gitignored).
3. `gh secret set SIGNING_SECRET < cosign.key` (or paste the key's full
   contents via **Settings → Secrets and variables → Actions**).
4. Verify with `gh secret list`, then push — the first build signs and
   publishes automatically.

Reusing an existing unencrypted key pair is fine; just make sure the
committed `cosign.pub` matches the private key in the secret, or signature
verification on rebase fails.

If the first run failed on signing: the secret was missing or the key was
encrypted — fix, then **Re-run jobs** (or `gh run rerun`).

## Publishing details

- Tags: `ghcr.io/aahsnr-work/bazzfin:latest` and `:44` (recipe's
  `image-version`).
- GHCR packages start **private**; flip to Public if you want anonymous pulls.
- Machines verify with: `cosign verify --key cosign.pub <image-ref>`.

## Renovate (`.github/renovate.json5`)

- Keeps GitHub Actions up to date (`config:recommended` +
  `github-actions`), scheduled before 6am UTC, max 2 PRs/hour, `renovate`
  label.
- A **custom regex manager** bumps the `ghcr.io/ublue-os/akmods:ogc-<N>` pin
  in `recipes/recipe.yml` once the akmods floating tag moves to a newer
  Fedora release. Treat it as a nice-to-have: after any base-image Fedora
  bump, double-check the pin by hand.
