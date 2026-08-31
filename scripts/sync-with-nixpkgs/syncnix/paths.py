"""Path classification and corepkgs -> nixpkgs path resolution.

Every function here is pure: it maps strings to strings and never touches the
filesystem. Whether a resolved path actually exists is the caller's question,
which keeps the mapping rules testable without a nixpkgs checkout.
"""

from pathlib import PurePosixPath
from typing import Optional

from . import config


def _under(path: str, prefix: str) -> bool:
    """True if `path` is `prefix` itself or lies beneath it."""
    return path == prefix or path.startswith(prefix + "/")


def is_ignored(path: str) -> bool:
    """True if `path` is excluded from comparison by IGNORE_DIRS/IGNORE_FILES."""
    if path in config.IGNORE_FILES:
        return True
    return any(_under(path, ignored) for ignored in config.IGNORE_DIRS)


def is_opaque(path: str) -> bool:
    """True if `path` names a file whose contents must not be diffed."""
    return path.endswith(config.OPAQUE_SUFFIXES)


def _longest_mapping(path: str) -> Optional[tuple[str, str]]:
    """Return the (corepkgs_prefix, nixpkgs_prefix) pair that best covers `path`."""
    best: Optional[tuple[str, str]] = None
    for corepkgs_prefix, nixpkgs_prefix in config.PATH_MAPPINGS.items():
        if _under(path, corepkgs_prefix):
            if best is None or len(corepkgs_prefix) > len(best[0]):
                best = (corepkgs_prefix, nixpkgs_prefix)
    return best


def resolve(path: str) -> Optional[str]:
    """Map a corepkgs-relative path to its nixpkgs-relative counterpart.

    Returns None when no mapping covers the path, which the caller reports as an
    unmapped file rather than treating as an error.
    """
    mapping = _longest_mapping(path)
    if mapping is None:
        return None

    corepkgs_prefix, nixpkgs_prefix = mapping
    remainder = "" if path == corepkgs_prefix else path[len(corepkgs_prefix) + 1 :]

    if nixpkgs_prefix == config.BY_NAME_PREFIX and remainder:
        return _resolve_by_name(nixpkgs_prefix, remainder)

    resolved = f"{nixpkgs_prefix}/{remainder}" if remainder else nixpkgs_prefix
    return _entry_point(resolved)


def _entry_point(path: str) -> str:
    """Apply the by-name entry-point name to an already-resolved path.

    A mapping may point straight at a by-name directory -- corepkgs' `pkgs/m4`
    is upstream's `pkgs/by-name/gn/gnum4` -- in which case the shard is already
    spelled out but the `default.nix` -> `package.nix` rename still applies.
    """
    if path.startswith(config.BY_NAME_PREFIX + "/") and path.endswith("/default.nix"):
        return path.removesuffix("default.nix") + "package.nix"
    return path


def _resolve_by_name(prefix: str, remainder: str) -> Optional[str]:
    """Expand `<pkg>/<rest>` into the nixpkgs by-name layout.

    by-name shards packages under the first two letters of their name and calls
    the entry point `package.nix` instead of `default.nix`.
    """
    parts = PurePosixPath(remainder).parts
    package = parts[0]
    if len(package) < 2:
        return None

    rest = list(parts[1:]) or ["default.nix"]
    if rest[-1] == "default.nix":
        rest[-1] = "package.nix"

    return "/".join([prefix, package[:2].lower(), package, *rest])


def group_of(path: str) -> Optional[tuple[str, str]]:
    """Return the (grouped_dir, subdirectory) `path` belongs to, if any."""
    for grouped in config.GROUPED_DIRS:
        if path.startswith(grouped + "/"):
            parts = PurePosixPath(path[len(grouped) + 1 :]).parts
            if parts:
                return (grouped, parts[0])
    return None


def patch_target(path: str) -> str:
    """The patch a file's divergence is reported in, relative to PATCHES_DIR.

    Files under a grouped directory share one patch per subdirectory; everything
    else gets a patch mirroring its own path.
    """
    group = group_of(path)
    if group is not None:
        grouped, subdirectory = group
        return f"{grouped}/{subdirectory}.patch"
    return f"{path}.patch"
