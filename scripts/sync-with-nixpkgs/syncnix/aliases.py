"""The rewrite vocabulary, read from the package set's own alias files.

corepkgs already records how it spells upstream names, in `aliases/nixpkgs.nix`
and `python/aliases.nix`. Reading those at run time means the sync tool cannot
drift from the aliases the package set actually defines -- a hand-copied list
would.

Not every alias is a useful rewrite. Most of `aliases.nix` mirrors nixpkgs' own
aliases, so both trees already write the same name and rewriting would invent a
diff rather than remove one. Those are named in `config.ALIAS_EXCLUSIONS`.
"""

import re
from pathlib import Path

from . import config

# `  name = target;` at the two-space indent `aliases.nix` uses for entries.
# The formatter may wrap long entries across multiple lines, so we match
# the opening `  name =` line and then join continuation lines.
_ALIAS = re.compile(r"^ {2}([A-Za-z_][A-Za-z0-9_-]*)\s*=\s*([^;]*;)\s*$")
_ALIAS_START = re.compile(r"^ {2}([A-Za-z_][A-Za-z0-9_-]*)\s*=\s*(.*)$")

# Removals and conditionals are not renames.
_NOT_A_RENAME = ("throw", "if", "lib.warn", "builtins", "abort")

# `renamed "old" "new.path" value` — extract the last (value) token.
_RENAMED = re.compile(r'^renamed\s+"[^"]+"\s+"[^"]+"\s+(.+)$')

_START = "keep-sorted start"
_END = "keep-sorted end"


def parse(text: str) -> dict[str, str]:
    """Extract `name -> target` pairs from an alias file's keep-sorted block.

    Only the block is read. Everything above it is the `mapAliases` scaffolding,
    which is not a list of aliases and must not be mistaken for one.
    """
    try:
        block = text[text.index(_START) : text.index(_END)]
    except ValueError:
        return {}

    found: dict[str, str] = {}
    lines = block.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        match = _ALIAS.match(line)
        if match is not None:
            # Single-line entry.
            name, raw = match.group(1), match.group(2).strip()
        else:
            # Try multi-line: `  name =\n    continuation...;`
            start = _ALIAS_START.match(line)
            if start is None:
                i += 1
                continue
            name, raw = start.group(1), start.group(2)
            # Collect continuation lines until we see a semicolon.
            while ";" not in raw and i + 1 < len(lines):
                i += 1
                raw += " " + lines[i].strip()
            if ";" not in raw:
                i += 1
                continue
        target = raw.rstrip(";").strip()
        if target.startswith(_NOT_A_RENAME):
            i += 1
            continue
        # Unwrap `renamed "old" "new" value` to just `value`.
        m = _RENAMED.match(target)
        if m:
            target = m.group(1)
        found[name] = target
        i += 1
    return found


def load(corepkgs_root: Path) -> list[tuple[re.Pattern[str], str]]:
    """Build the rewrite vocabulary for a corepkgs checkout.

    Returns compiled `(pattern, replacement)` pairs: the alias files' entries
    minus the exclusions, plus the renames no alias can express.
    """
    vocabulary: list[tuple[re.Pattern[str], str]] = []

    for relative in config.ALIAS_FILES:
        path = corepkgs_root / relative
        if not path.is_file():
            continue
        for name, target in parse(path.read_text(encoding="utf-8")).items():
            if name in config.ALIAS_EXCLUSIONS:
                continue
            vocabulary.append((re.compile(rf"\b{re.escape(name)}\b"), target))

    for pattern, replacement in config.EXTRA_VOCABULARY:
        vocabulary.append((re.compile(pattern), replacement))

    return vocabulary
