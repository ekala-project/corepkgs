"""Command line interface.

Two commands:

  generate  compare the trees, write patches, report drift against the baseline
  accept    record current divergence as intentional, silencing it until it moves
"""

import argparse
import shutil
import sys
from pathlib import Path

from . import baseline, config, survey


def _roots(args: argparse.Namespace) -> tuple[Path, Path]:
    """Resolve and validate both checkout roots before anything is written."""
    corepkgs_root = args.corepkgs.resolve()
    nixpkgs_root = args.nixpkgs.resolve()
    for label, root in (("corepkgs", corepkgs_root), ("nixpkgs", nixpkgs_root)):
        if not root.is_dir():
            sys.exit(f"error: {label} directory not found: {root}")
    return corepkgs_root, nixpkgs_root


def _write_reports(reports_dir: Path, result: survey.Survey) -> None:
    """Write the lists that need following up, one file per category."""
    reports = {
        "missing-in-nixpkgs.txt": (
            "Files present in corepkgs with no counterpart in nixpkgs.",
            result.missing,
        ),
        "unmapped-paths.txt": (
            "Files no PATH_MAPPINGS entry covers; add a mapping or an ignore.",
            result.unmapped,
        ),
        "opaque-files.txt": (
            "Patch files that differ from upstream; compare them by hand.",
            result.opaque_differs,
        ),
    }
    for name, (description, entries) in reports.items():
        if not entries:
            continue
        reports_dir.mkdir(parents=True, exist_ok=True)
        body = f"# {description}\n" + "\n".join(entries) + "\n"
        (reports_dir / name).write_text(body, encoding="utf-8")


def _classify(result: survey.Survey, accepted_dir: Path) -> dict[baseline.Status, list[str]]:
    """Bucket every target by how it relates to the accepted baseline."""
    buckets: dict[baseline.Status, list[str]] = {status: [] for status in baseline.Status}
    targets = set(result.patches) | set(baseline.recorded(accepted_dir))
    for target in sorted(targets):
        status = baseline.classify(
            result.patches.get(target), baseline.load(accepted_dir, target)
        )
        if status is not None:
            buckets[status].append(target)
    return buckets


def _report(buckets: dict[baseline.Status, list[str]], result: survey.Survey) -> None:
    """Print the drift summary, listing only what needs a human."""
    print(f"  identical to upstream : {result.identical}")
    print(f"  accepted divergence   : {len(buckets[baseline.Status.UNCHANGED])}")

    for status, label in (
        (baseline.Status.NEW, "new divergence"),
        (baseline.Status.CHANGED, "changed vs accepted"),
        (baseline.Status.RESOLVED, "resolved, baseline is stale"),
    ):
        entries = buckets[status]
        print(f"  {label:<21} : {len(entries)}")
        for target in entries:
            print(f"      {target}")

    if result.unmapped or result.missing or result.opaque_differs:
        print(
            f"  unmapped {len(result.unmapped)}, "
            f"missing upstream {len(result.missing)}, "
            f"patch files differing {len(result.opaque_differs)}"
        )


def generate(args: argparse.Namespace) -> int:
    corepkgs_root, nixpkgs_root = _roots(args)
    patches_dir = corepkgs_root / config.PATCHES_DIR
    accepted_dir = corepkgs_root / config.ACCEPTED_DIR

    result = survey.run(corepkgs_root, nixpkgs_root)
    buckets = _classify(result, accepted_dir)

    if args.dry_run:
        print(f"would refresh {patches_dir} with {len(result.patches)} patches")
    else:
        if patches_dir.exists():
            shutil.rmtree(patches_dir)
        for target, patch in result.patches.items():
            destination = patches_dir / target
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(patch, encoding="utf-8")
        _write_reports(patches_dir / config.REPORTS_DIR, result)

    _report(buckets, result)

    drifted = buckets[baseline.Status.NEW] + buckets[baseline.Status.CHANGED]
    return 1 if (drifted and args.strict) else 0


def accept(args: argparse.Namespace) -> int:
    corepkgs_root, nixpkgs_root = _roots(args)
    accepted_dir = corepkgs_root / config.ACCEPTED_DIR

    result = survey.run(corepkgs_root, nixpkgs_root)
    selected = args.targets or sorted(result.patches)

    accepted = 0
    forgotten = 0
    for target in selected:
        patch = result.patches.get(target)
        if patch is None:
            if baseline.forget(accepted_dir, target):
                forgotten += 1
                print(f"  forgot   {target}")
            else:
                print(f"  unknown  {target}", file=sys.stderr)
            continue
        if baseline.load(accepted_dir, target) == patch:
            continue
        baseline.accept(accepted_dir, target, patch)
        accepted += 1
        print(f"  accepted {target}")

    print(f"accepted {accepted}, forgot {forgotten}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="sync-with-nixpkgs",
        description="Report how corepkgs diverges from nixpkgs.",
    )
    parser.add_argument(
        "--corepkgs", type=Path, default=Path("."), help="corepkgs root (default: .)"
    )
    parser.add_argument(
        "--nixpkgs", type=Path, default=Path("../nixpkgs"), help="nixpkgs root (default: ../nixpkgs)"
    )

    commands = parser.add_subparsers(dest="command")

    generate_parser = commands.add_parser("generate", help="write patches and report drift")
    generate_parser.add_argument(
        "--dry-run", action="store_true", help="report without writing patches"
    )
    generate_parser.add_argument(
        "--strict", action="store_true", help="exit non-zero when unaccepted drift exists"
    )
    generate_parser.set_defaults(handler=generate)

    accept_parser = commands.add_parser("accept", help="record divergence as intentional")
    accept_parser.add_argument(
        "targets", nargs="*", help="patch targets to accept (default: all current divergence)"
    )
    accept_parser.set_defaults(handler=accept)

    parser.set_defaults(handler=generate, dry_run=False, strict=False)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    return args.handler(args)
