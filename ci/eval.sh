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
if ! result="$(nix-instantiate --eval --strict --json ci/eval.nix 2>"$stderr")"; then
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

# `{"evaluated":N,"placeholders":M}` -- two integers looked up by name, so no
# JSON parser is needed and key order does not matter.
field() { sed -E "s/.*\"$1\":([0-9]+).*/\1/" <<<"$result"; }
count="$(field evaluated)"
placeholders="$(field placeholders)"

echo "All $count packages evaluate (top-level attributes plus pkgs-many variants)."
echo "Skipped $placeholders null attributes (unported dependency placeholders)."
