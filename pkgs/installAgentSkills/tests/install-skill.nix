{
  lib,
  installAgentSkills,
  runCommandLocal,
}:

runCommandLocal "install-agent-skills--install-skill"
  {
    strictDeps = true;
    __structuredAttrs = true;

    nativeBuildInputs = [ installAgentSkills ];
    meta.platforms = lib.platforms.all;
  }
  ''
    export pname=test-installSkill

    mkdir -p skill-xyz
    echo "This is a test agent skill!" > skill-xyz/SKILL.md

    installSkill ./skill-xyz

    cmp skill-xyz/SKILL.md $out/share/skills/$pname/skill-xyz/SKILL.md
  ''
