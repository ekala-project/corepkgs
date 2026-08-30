{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  cmake,
  cython,
  ninja,
  scikit-build-core,
  numpy,
  rapidfuzz-cpp,
  taskflow,
}:

buildPythonPackage rec {
  pname = "rapidfuzz";
  version = "3.14.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "maxbachmann";
    repo = "RapidFuzz";
    tag = "v${version}";
    hash = "sha256-wF7eeSD6GQfN0EOwDvrgjMqN5u2wxXFlktQS7nIKgkU=";
  };

  build-system = [
    cmake
    cython
    ninja
    scikit-build-core
  ];

  buildInputs = [
    rapidfuzz-cpp
    taskflow
  ];

  # Taskflow 4.1's TaskflowConfigVersion.cmake uses SameMinorVersion
  # compatibility, so find_package(Taskflow 4.0.0) fails against 4.1.x.
  # Insert a version-matched find_package call so CMake finds the system copy.
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail \
        'find_package(Taskflow 4.0.0 QUIET)' \
        'find_package(Taskflow ${taskflow.version} QUIET)'
  '';

  env.RAPIDFUZZ_BUILD_EXTENSION = 1;

  preBuild = lib.optionalString (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isx86_64) ''
    export CMAKE_ARGS="-DCMAKE_CXX_COMPILER_AR=$AR -DCMAKE_CXX_COMPILER_RANLIB=$RANLIB"
  '';

  optional-dependencies = {
    all = [ numpy ];
  };

  pythonImportsCheck = [ "rapidfuzz" ];

  meta = {
    description = "Rapid fuzzy string matching";
    homepage = "https://github.com/maxbachmann/RapidFuzz";
    changelog = "https://github.com/maxbachmann/RapidFuzz/blob/${src.tag}/CHANGELOG.rst";
    license = lib.licenses.mit;

  };
}
