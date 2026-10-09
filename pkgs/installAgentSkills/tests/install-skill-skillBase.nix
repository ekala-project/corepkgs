{
  lib,
  installAgentSkills,
  runCommandLocal,
}:

runCommandLocal "install-agent-skills--install-skill-skillBase"
  {
    strictDeps = true;
    __structuredAttrs = true;

    nativeBuildInputs = [ installAgentSkills ];
    meta.platforms = lib.platforms.all;
  }
  ''
    export pname=test-skillBase
    export base=random-base

    mkdir -p skill-xyz
    echo "This is a test agent skill!" > skill-xyz/SKILL.md

    installSkill ./skill-xyz $base

    cmp skill-xyz/SKILL.md $out/share/skills/$base/skill-xyz/SKILL.md
  ''
