# shellcheck shell=bash

mixCompileHook() {
  echo "Executing mixCompileHook"

  local flagsArray=()
  concatTo flagsArray mixCompileFlags

  mix compile --no-deps-check "${flagsArray[@]}"

  echo "Finished mixCompileHook"
}

if [ -z "${dontMixCompile-}" ] && [ -z "${buildPhase-}" ]; then
  buildPhase=mixCompileHook
fi
