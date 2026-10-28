{
  lib,
  buildRubyGem,
  ruby,
  writeScript,
  testers,
  bundler,
  versionCheckHook,
  nix-update-script,
}:

let
  gemName = "bundler";
  version = "2.7.2";
in
buildRubyGem {
  inherit ruby;
  name = "${gemName}-${version}";
  inherit gemName version;
  source.sha256 = "sha256-Heyvni4ay5G2WGopJcjz9tojNKgnMaYv8t7RuDwoOHE=";
  dontPatchShebangs = true;

  postFixup = ''
    substituteInPlace $out/bin/bundle --replace-fail "activate_bin_path" "bin_path"
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  versionCheckProgram = "${placeholder "out"}/bin/bundler";
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Manage your Ruby application's gem dependencies";
    homepage = "https://bundler.io";
    changelog = "https://github.com/rubygems/rubygems/blob/bundler-v${version}/bundler/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "bundler";
  };
}
