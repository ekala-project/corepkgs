# shellcheck shell=bash

# Setup hook for the `installAgentSkills` package
# Example usage in a derivation:
#
#   { ..., installAgentSkills, ... }:
#   stdenv.mkDerivation {
#     ...
#     nativeBuildInputs = [ installAgentSkills ];
#     ...
#   }
#
# This hook also provides an `installSkill` function that can be used to install
# skills manually into their respective folder.
#
# Reference on skills standard here:
#   https://github.com/agentskills/agentskills
#
#   An agent "skill" is structured:
#     - SKILL.md - required: metadata + instructions
#     - scripts/ - optional: executable code
#     - references/ - optional: documentation
#     - assets/ - optional: templates
#     - ... - optional additional files/directories
#

preInstallHooks+=(installSkills)

installSkill() {
  if (($# != 1 && $# != 2)); then
    nixErrorLog "expected 1 or 2 arguments!"
    nixErrorLog "usage: installSkill skillDir [skillBase]"
    nixErrorLog "where skillDir is the skill directory and skillBase is the skill parent directory"
    nixErrorLog "unless set otherwise, skillBase=\$pname"
    return 1
  fi

  local skillName
  skillName=$(basename -- "$1")
  local base="${2:-${pname-}}"

  if [ -z "$base" ]; then
    nixErrorLog "error: no skillBase given and \$pname is unset"
    return 1
  fi

  if [ ! -d "$1" ]; then
    nixErrorLog "expected ${skillName} to be a directory"
    return 1
  fi

  if [ ! -f "$1/SKILL.md" ]; then
    nixErrorLog "error: ${skillName} doesn't contain a SKILL.md file"
    return 1
  fi

  if [ ! -s "$1/SKILL.md" ]; then
    nixErrorLog "error: ${skillName}/SKILL.md is empty"
    return 1
  fi

  local destdir="$out/share/skills/${base}"
  local target="$destdir/$skillName"
  if [ -e "$target" ]; then
    nixErrorLog "error: $target already exists"
    return 1
  fi

  nixInfoLog "installing skill $1"
  mkdir -p "$destdir"
  cp -RLT -- "$1" "$target"
}

installSkills() {
  if [ -n "${dontInstallAgentSkills-}" ]; then return; fi

  (
    shopt -s globstar nullglob
    for skill in **/SKILL.md; do
      installSkill "$(dirname -- "$skill")"
    done
  )
}
