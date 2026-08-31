"""The accepted-divergence baseline.

Most divergence from nixpkgs is deliberate and permanent. Recording it means a
run reports only what actually moved, so a real upstream change is not buried
under hundreds of differences somebody already decided about.

The baseline is stored as the patch text itself rather than a hash, so `git
diff`-style inspection of what changed is possible without regenerating it.
"""

from enum import Enum
from pathlib import Path
from typing import Optional


class Status(Enum):
    """How a generated patch relates to the accepted baseline."""

    NEW = "new"
    """Divergence with nothing recorded for it."""

    CHANGED = "changed"
    """Divergence that no longer matches what was accepted."""

    UNCHANGED = "unchanged"
    """Divergence identical to what was accepted."""

    RESOLVED = "resolved"
    """Accepted divergence that no longer exists; the baseline entry is stale."""


def _entry(accepted_dir: Path, target: str) -> Path:
    return accepted_dir / target


def load(accepted_dir: Path, target: str) -> Optional[str]:
    """Return the accepted patch text for `target`, or None if never accepted."""
    entry = _entry(accepted_dir, target)
    if not entry.is_file():
        return None
    return entry.read_text(encoding="utf-8")


def classify(current: Optional[str], accepted: Optional[str]) -> Optional[Status]:
    """Compare a freshly generated patch against its baseline.

    Returns None when a target has neither current divergence nor a baseline,
    which is the common case and needs no reporting.
    """
    if current is None and accepted is None:
        return None
    if current is None:
        return Status.RESOLVED
    if accepted is None:
        return Status.NEW
    return Status.UNCHANGED if current == accepted else Status.CHANGED


def accept(accepted_dir: Path, target: str, patch: str) -> None:
    """Record `patch` as the accepted divergence for `target`."""
    entry = _entry(accepted_dir, target)
    entry.parent.mkdir(parents=True, exist_ok=True)
    entry.write_text(patch, encoding="utf-8")


def forget(accepted_dir: Path, target: str) -> bool:
    """Drop a stale baseline entry. Returns True if one was removed."""
    entry = _entry(accepted_dir, target)
    if not entry.is_file():
        return False
    entry.unlink()
    return True


def recorded(accepted_dir: Path) -> list[str]:
    """Every target with a baseline entry, as PATCHES_DIR-relative paths."""
    if not accepted_dir.is_dir():
        return []
    return sorted(
        str(path.relative_to(accepted_dir))
        for path in accepted_dir.rglob("*.patch")
        if path.is_file()
    )
