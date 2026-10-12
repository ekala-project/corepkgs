# shellcheck shell=bash

rebar3CompileHook() {
  echo "Executing rebar3CompileHook"

  HOME=. rebar3 bare compile --paths "."

  echo "Finished rebar3CompileHook"
}

if [ -z "${dontRebar3Compile-}" ] && [ -z "${buildPhase-}" ]; then
  buildPhase=rebar3CompileHook
fi
