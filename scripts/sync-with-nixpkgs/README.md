# sync-with-nixpkgs

Reports how corepkgs diverges from a nixpkgs checkout, one patch per package.

```
./sync.py --nixpkgs ../nixpkgs generate
./sync.py --nixpkgs ../nixpkgs accept pkgs/curl.patch
```

Both output directories are gitignored; they are a local review aid, never repo
content.

| path              | contents                                          |
| ----------------- | ------------------------------------------------- |
| `patches/`        | every current divergence, rewritten on each run    |
| `.sync-accepted/` | divergence you have accepted, written by `accept`  |

## Reading the output

`generate` classifies each patch against the accepted baseline:

- **new divergence** — nothing recorded for it yet
- **changed vs accepted** — upstream moved, or corepkgs did; re-review it
- **resolved, baseline is stale** — the divergence is gone; `accept` it to drop
  the entry
- **accepted divergence** — matches the baseline, so it is only counted

Most divergence in this repo is deliberate and permanent. Accepting it is what
makes a genuine upstream change visible instead of being buried. `--strict`
exits non-zero when unaccepted drift exists, for use in a check.

Every corepkgs file is accounted for: it pairs with a nixpkgs file, is
ignored, or is declared in `LOCAL_ONLY` as having no upstream counterpart.
`LOCAL_ONLY` differs from the ignore lists — those say "do not compare", it says
"there is nothing to compare against". Keeping it explicit is what lets the
reports mean something.

Reports land in `patches/_reports/` when they are non-empty, and each one is a
question for a person:

- `unmapped-paths.txt` — no `PATH_MAPPINGS` entry covers it
- `missing-in-nixpkgs.txt` — mapped, but upstream no longer has it; either the
  mapping went stale or upstream removed the file
- `stale-local-only.txt` — declared corepkgs-only, but nixpkgs has it now; drop
  the declaration
- `opaque-files.txt` — patch files and symlinks that differ, compared without
  being diffed

All four are empty in a healthy tree.

## How a patch is built

Only the **nixpkgs side** is ever transformed — path references rewritten to
corepkgs form, attributes renamed to corepkgs spellings, and `meta.maintainers`
/ `meta.teams` / `meta.nonTeamMaintainers` dropped, since this repo carries none
of them and its `check-meta` rejects them.

corepkgs content is passed through byte-for-byte. That is the whole design: the
diff's "old" side is the file as it exists on disk, so hunk offsets are correct
and every patch applies from the repo root with `git apply -p1`. Nothing
post-processes diff output, so there is no hunk-header arithmetic to get wrong.

A consequence worth knowing: lines corepkgs adds and upstream lacks — a
`cmake.configurePhaseHook`, say — show up as deletions. That is accurate, and
the baseline is what silences them once you have accepted them. There is no
filter list for "corepkgs-specific" lines, because there does not need to be.

`.patch` and `.diff` files are never diffed. A diff of two patches is neither
readable nor appliable, so a differing one is replaced by a note in the patch
header naming both paths, and listed in `opaque-files.txt`.

## Layout

    sync.py              entry point
    syncnix/config.py    path mappings, rewrites, ignore lists -- data only
    syncnix/paths.py     corepkgs -> nixpkgs path resolution (pure)
    syncnix/normalize.py upstream content transformations (pure)
    syncnix/diffing.py   patch construction (pure)
    syncnix/baseline.py  the accepted-divergence store
    syncnix/survey.py    tree walking; the only module that does file I/O
    syncnix/cli.py       commands and reporting

Run `./run-tests.py` for the test suite.
