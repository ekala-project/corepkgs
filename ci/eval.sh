#!/usr/bin/env bash
# Fails if any package in the repository fails to evaluate.
#
# See ci/eval.nix for what counts as a failure.

set -euo pipefail

cd "$(dirname "$0")/.."

stderr="$(mktemp)"
trap 'rm -f "$stderr"' EXIT

# Real failures are `abort`s, missing attributes and type errors, none of which
# `tryEval` can catch -- so they surface here as a non-zero exit with Nix's own
# message, which names the offending expression and its source location.
if ! result="$(nix-instantiate --eval --strict --json ci/eval.nix --option allow-import-from-derivation false 2>"$stderr")"; then
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

# `{"evaluated":N}` -- extract the integer without needing a JSON parser.
count="$(sed -E 's/.*"evaluated":([0-9]+).*/\1/' <<<"$result")"

echo "All $count packages evaluate (top-level attributes plus pkgs-many variants)."
