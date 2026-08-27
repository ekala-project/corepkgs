#!/usr/bin/env bash
# Fails if any top-level attribute of the package set fails to evaluate.
#
# See ci/eval.nix for what counts as a failure and ci/unavailable.nix for the
# attributes that are deliberately skipped.

set -euo pipefail

cd "$(dirname "$0")/.."

stderr="$(mktemp)"
trap 'rm -f "$stderr"' EXIT

# A missing `callPackage` argument aborts evaluation rather than throwing, so
# nix-instantiate exits non-zero here and the job fails with Nix's own error
# message, which names the missing argument.
if ! failures="$(nix-instantiate --eval --strict --json ci/eval.nix 2>"$stderr")"; then
  cat "$stderr" >&2
  exit 1
fi

# Nix's evaluation warnings (deprecated syntax, unclear path literals, ...) are
# errors here: they are cheap to fix and easy to accumulate unnoticed otherwise.
if grep -q '^warning:' "$stderr"; then
  cat "$stderr" >&2
  echo
  echo "Evaluation emitted the warnings above; fix them or the job stays red."
  exit 1
fi

if [ "$failures" = "[]" ]; then
  echo "All top-level attributes evaluate."
  exit 0
fi

echo "The following attributes failed to evaluate:"
echo
printf '%s\n' "$failures" | tr -d '[]"' | tr ',' '\n' | sed 's/^/  /'
echo
echo "Run 'nix-instantiate -A <attr>' to see the error."
echo "If the package is deliberately not available yet, add it to ci/unavailable.nix."
exit 1
