{
  lib,
  stdenvNoCC,
  installAgentSkills,
}:

stdenvNoCC.mkDerivation {
  # explicit pname is required for the hook to work but
  # name is manually set to keep drvPath consistent across
  # tests for installAgentSkills
  pname = "test";
  name = "install-agent-skills--dont-install-skills";

  strictDeps = true;
  __structuredAttrs = true;

  src = null;
  dontUnpack = true;

  nativeBuildInputs = [ installAgentSkills ];

  dontInstallAgentSkills = true;

  # build phase happens before the hook is called to install the skills
  buildPhase = ''

    mkdir -p test-skill/
    touch test-skill/SKILL.md

  '';

  # if the skill file is created then the test should fail
  installCheckPhase = ''

    if test -f $out/share/skills/$pname/test-skill/SKILL.md; then
      exit 1
    fi

    touch $out

  '';
  doInstallCheck = true;

  meta.platforms = lib.platforms.all;
}
