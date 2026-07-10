{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  python3,
  spirv-headers,
  spirv-tools,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "glslang";
  version = "16.3.0";

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "glslang";
    tag = finalAttrs.version;
    hash = "sha256-wclcJ0NfqFXSUHGVsxjn2I8XxWbrkzOB4WXqsN1XtmE=";
  };

  outputs = [
    "bin"
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    python3
  ];

  propagatedBuildInputs = [
    spirv-tools
    spirv-headers
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
    (lib.cmakeBool "BUILD_EXTERNAL" false)
    (lib.cmakeBool "ALLOW_EXTERNAL_SPIRV_TOOLS" true)
    # Skip tests to avoid gtest dependency
    (lib.cmakeBool "BUILD_TESTING" false)
  ];

  postInstall = ''
    ln -s $bin/bin/glslang $bin/bin/glslangValidator
  '';

  meta = {
    description = "Khronos reference front-end for GLSL and ESSL";
    homepage = "https://github.com/KhronosGroup/glslang";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
})
