"""Normalisation of incoming nixpkgs content.

Only the nixpkgs side is ever rewritten. corepkgs content is passed through
byte-for-byte, which is what lets a generated patch both hide upstream noise and
still apply cleanly: the diff's "old" side is the real file on disk.
"""

import re
from functools import lru_cache
from typing import Optional

from . import config

Vocabulary = list[tuple[re.Pattern[str], str]]
"""Compiled `(pattern, replacement)` rewrites applied to nixpkgs content."""

_BINDING = re.compile(
    r"^(?P<indent>\s*)(?:meta\.)?(?P<name>" + "|".join(config.DROPPED_META_BINDINGS) + r")\s*="
)


def rewrite_paths(text: str) -> str:
    """Express nixpkgs-relative file references in corepkgs terms."""
    for pattern, replacement in config.PATH_REWRITES:
        text = re.sub(pattern, replacement, text)
    return text


_WORD_PATTERN = re.compile(r"^\\b(.+)\\b$")
_METACHARACTERS = frozenset(".^$*+?{}[]|()")


@lru_cache(maxsize=None)
def _required_text(pattern: re.Pattern[str]) -> Optional[str]:
    """The plain substring `pattern` cannot possibly match without.

    Every entry in the vocabulary is a `\\bname\\b` word match, so the name
    itself has to be present for the pattern to fire. Returning it lets the
    caller skip a substitution with a cheap substring test instead of running
    the regex engine over the whole file.

    None means "no shortcut available" -- a real regex, which must always run.
    """
    match = _WORD_PATTERN.match(pattern.pattern)
    if match is None:
        return None
    literal = re.sub(r"\\(.)", r"\1", match.group(1))
    return None if any(character in _METACHARACTERS for character in literal) else literal


def rename_vocabulary(text: str, vocabulary: Vocabulary) -> str:
    """Rename attributes that corepkgs spells differently from nixpkgs.

    The vocabulary is passed in rather than imported so this stays pure and can
    be tested without an alias file on disk. See `syncnix.aliases` for how it is
    built.

    Most files mention almost none of the vocabulary, so each substitution is
    guarded by a substring test first. The test reads `text` as it stands at
    that point in the loop, not the original, so a name introduced by an earlier
    replacement is still seen -- `ubootRaspberryPi` becomes
    `uboot.ubootRaspberryPi`, and the chaining behaviour is unchanged.
    """
    for pattern, replacement in vocabulary:
        required = _required_text(pattern)
        if required is not None and required not in text:
            continue
        text = pattern.sub(replacement, text)
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

    Plenty of files mention none of the three, and for those a few substring
    scans are cheaper than splitting the file into lines and walking it.
    """
    if not any(name in text for name in config.DROPPED_META_BINDINGS):
        return text
    return _drop_bindings(text, _BINDING)


def _drop_bindings(text: str, binding: re.Pattern[str]) -> str:
    """Remove every binding whose opening line `binding` matches, body included."""
    lines = text.split("\n")
    kept: list[str] = []
    index = 0
    while index < len(lines):
        if binding.match(lines[index]):
            index = _statement_end(lines, index)
            continue
        kept.append(lines[index])
        index += 1
    return "\n".join(kept)


_NOISE_BINDING = re.compile(
    r"^(?P<indent>\s*)(?:meta\.)?(?P<name>"
    + "|".join(re.escape(name) for name in config.NOISE_BINDINGS)
    + r")\s*="
)


def _blank_trivial(line: str) -> str:
    """Empty out a value the tool treats as trivial, keeping the binding."""
    for pattern in config.TRIVIAL_PATTERNS:
        if pattern.match(line):
            return re.sub(r'"[^"]*"', '""', line, count=1)
    return line


def significant(text: str) -> str:
    """The part of a file a reviewer actually needs to see.

    Noise bindings are removed whole, noise lines dropped, and trivial values
    emptied, so that two files differing only in those ways reduce to the same
    text. Applied to *both* sides, unlike `upstream` -- which is why it may only
    ever decide whether a patch is worth reporting, never help build one. A
    patch is still generated from the verbatim corepkgs file, so it applies.

    `NOISE_SUBSTITUTIONS` run first, so that `rec` and `finalAttrs` forms have
    already collapsed into one before anything else is matched against them.

    Emptying a value rather than deleting the line is deliberate: a bumped
    `hash` then reduces to the same text on both sides, while a `hash` upstream
    added and corepkgs lacks leaves a line with no counterpart, and still shows.
    """
    for pattern, replacement in config.NOISE_SUBSTITUTIONS:
        text = pattern.sub(replacement, text)
    stripped = _drop_bindings(text, _NOISE_BINDING)
    return "\n".join(
        _blank_trivial(line)
        for line in stripped.split("\n")
        if not any(pattern.match(line) for pattern in config.NOISE_LINE_PATTERNS)
    )


def upstream(text: str, vocabulary: Vocabulary) -> str:
    """Full normalisation applied to nixpkgs content before diffing."""
    return drop_meta_bindings(rename_vocabulary(rewrite_paths(text), vocabulary))
