{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  glib,
  glibc,
  libseccomp,
  systemdMinimal,
  versionCheckHook,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "conmon";
  version = "2.2.1";

  src = fetchFromGitHub {
    owner = "containers";
    repo = "conmon";
    tag = "v${finalAttrs.version}";
    hash = "sha256-NIbH/fiz/m2W7aGt2On7E6zkWFa5IKzrPROuCAYwNFk=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    glib
    libseccomp
    systemdMinimal
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isMusl) [
    glibc
    glibc.static
  ];

  # manpage requires building the vendored go-md2man
  makeFlags = [
    "bin/conmon"
    "GIT_COMMIT=${finalAttrs.src.rev}"
  ];

  installPhase = ''
    runHook preInstall
    install -D bin/conmon -t $out/bin
    runHook postInstall
  '';

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "conmon --version";
    };
  };

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  meta = {
    changelog = "https://github.com/containers/conmon/releases/tag/${finalAttrs.src.tag}";
    homepage = "https://github.com/containers/conmon";
    description = "OCI container runtime monitor";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    mainProgram = "conmon";
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "conmon_project" finalAttrs.version;
  };
})
