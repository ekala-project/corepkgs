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
  version = "16.6.0";

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "glslang";
    tag = finalAttrs.version;
    hash = "sha256-Dg51nelPWj19Ug1Eo2NFerDoSxEB0mo8VWsRWkNgcn8=";
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

  cmakeEntries = {
    BUILD_SHARED_LIBS = !stdenv.hostPlatform.isStatic;
    BUILD_EXTERNAL = false;
    ALLOW_EXTERNAL_SPIRV_TOOLS = true;
    # Skip tests to avoid gtest dependency
    BUILD_TESTING = false;
  };

  postInstall = ''
    ln -s $bin/bin/glslang $bin/bin/glslangValidator
  '';

  meta = {
    description = "Khronos reference front-end for GLSL and ESSL";
    homepage = "https://github.com/KhronosGroup/glslang";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
})
