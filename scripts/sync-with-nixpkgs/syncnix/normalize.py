"""Normalisation of incoming nixpkgs content.

Only the nixpkgs side is ever rewritten. corepkgs content is passed through
byte-for-byte, which is what lets a generated patch both hide upstream noise and
still apply cleanly: the diff's "old" side is the real file on disk.
"""

import re

from . import config

_BINDING = re.compile(
    r"^(?P<indent>\s*)(?:meta\.)?(?P<name>" + "|".join(config.DROPPED_META_BINDINGS) + r")\s*="
)


def rewrite_paths(text: str) -> str:
    """Express nixpkgs-relative file references in corepkgs terms."""
    for pattern, replacement in config.PATH_REWRITES:
        text = re.sub(pattern, replacement, text)
    return text


def rename_vocabulary(text: str) -> str:
    """Rename attributes that corepkgs spells differently from nixpkgs."""
    for pattern, replacement in config.VOCABULARY:
        text = re.sub(pattern, replacement, text)
    return text


_TOKEN = re.compile(r"\bwith\b|[\[\]{}();]")


def _statement_end(lines: list[str], start: int) -> int:
    """Index one past the binding beginning at `start`.

    Bracket depth is tracked so a multi-line list is consumed in full. A `with`
    clause introduces a `;` of its own -- `maintainers = with lib.maintainers; [
    ... ];` -- so each pending `with` swallows one top-level semicolon before
    the next is treated as the end of the binding.

    Strings and comments are not parsed. A `meta` binding hiding a bracket or
    semicolon inside a string literal is not worth a Nix parser for, and the
    worst outcome is a leftover line in one patch.
    """
    depth = 0
    pending_with = 0
    for index in range(start, len(lines)):
        for token in _TOKEN.findall(lines[index]):
            if token == "with":
                pending_with += 1
            elif token in "[{(":
                depth += 1
            elif token in "]})":
                depth -= 1
            elif token == ";" and depth <= 0:
                if pending_with:
                    pending_with -= 1
                else:
                    return index + 1
    return len(lines)


def drop_meta_bindings(text: str) -> str:
    """Remove `maintainers`/`teams`/`nonTeamMaintainers` bindings.

    corepkgs carries none of them, so importing them would add noise to every
    package patch and produce content this repo's `check-meta` rejects outright.
    """
    lines = text.split("\n")
    kept: list[str] = []
    index = 0
    while index < len(lines):
        if _BINDING.match(lines[index]):
            index = _statement_end(lines, index)
            continue
        kept.append(lines[index])
        index += 1
    return "\n".join(kept)


def upstream(text: str) -> str:
    """Full normalisation applied to nixpkgs content before diffing."""
    return drop_meta_bindings(rename_vocabulary(rewrite_paths(text)))
