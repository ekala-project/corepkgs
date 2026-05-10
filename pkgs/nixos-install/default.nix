{
  lib,
  replaceVarsWith,
  runtimeShell,
  installShellFiles,
  jq,
  nixos-enter,
  util-linuxMinimal,
}:

replaceVarsWith {
  name = "nixos-install";
  src = ./nixos-install.sh;

  replacements = {
    inherit runtimeShell;

    path = lib.makeBinPath [
      jq
      nixos-enter
      util-linuxMinimal
    ];
  };

  dir = "bin";
  isExecutable = true;

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installManPage ${./nixos-install.8}
  '';

  meta = {
    description = "Install bootloader and NixOS";
    license = lib.licenses.mit;
    mainProgram = "nixos-install";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
