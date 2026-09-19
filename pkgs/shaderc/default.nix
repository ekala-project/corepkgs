{
  lib,
  stdenv,
  fetchFromGitHub,
  replaceVars,
  versionCheckHook,
  cmake,
  python3,
  glslang,
  spirv-tools,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "shaderc";
  version = "2026.1";

  outputs = [
    "out"
    "lib"
    "bin"
    "dev"
    "static"
  ];

  src = fetchFromGitHub {
    owner = "google";
    repo = "shaderc";
    rev = "v${finalAttrs.version}";
    hash = "sha256-OiBv18zxeE/gqY4zOMXTsCdkAEWo9BIehdu/adw0+cE=";
  };

  patches = [
    (replaceVars ./unvendor-glslang.patch {
      shaderc-version = finalAttrs.version;
      spirv-tools-version = spirv-tools.version;
      glslang-version = glslang.version;
    })
    ./fix-pc-file-generation.patch
  ];

  postPatch = ''
    patchShebangs --build utils/
  '';

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    python3
  ];

  propagatedBuildInputs = [
    glslang
  ];

  cmakeEntries = {
    SHADERC_SKIP_TESTS = true;
  };

  postInstall = ''
    moveToOutput "lib/*.a" $static
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru.tests.pkg-config = testers.hasPkgConfigModules {
    package = finalAttrs.finalPackage;
    versionCheck = false;
  };

  meta = {
    description = "Collection of tools, libraries and tests for shader compilation";
    homepage = "https://github.com/google/shaderc";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
    mainProgram = "glslc";
    pkgConfigModules = [
      "shaderc_combined"
      "shaderc"
      "shaderc_static"
    ];
  };
})
