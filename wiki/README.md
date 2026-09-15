# wiki/ — the GitHub wiki source

This directory is the **source of truth** for the project's GitHub wiki
(https://github.com/aahsnr-work/bazzfin/wiki).

GitHub hosts the wiki in a separate git repository
(`bazzfin.wiki.git`), and its filenames are special:

- `Home.md` — the landing page
- `_Sidebar.md` — navigation shown on every page
- `_Footer.md` — footer shown on every page
- Everything else — one page per file; `[[Page-Name]]` links between them

Because the wiki repo can only be created after its first page exists in the
UI, the pages are kept here in the main repository (reviewable in PRs) and
published with one command:

```bash
just wiki-push
```

which clones `bazzfin.wiki.git`, copies `wiki/*.md` over it, commits, and
pushes. First time only: if the wiki repo doesn't exist yet, create it once by
opening the wiki tab in the browser and creating a page (or the push target
will 404).

When editing pages: keep them grounded in `recipes/recipe.yml` and
`files/` — they document the actual build, not aspirational state.
