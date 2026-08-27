{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  elfutils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "json-c";
  version = "0.19-20260627";

  src = fetchFromGitHub {
    owner = "json-c";
    repo = "json-c";
    rev = "json-c-${finalAttrs.version}";
    hash = "sha256-ZfwVOU6PJKHSj7XVZh5BUb3VJ+lHXZVMPdHh5fgrock=";
  };

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_APPS" false)
  ];

  passthru.tests = {
    inherit elfutils;
  };

  meta = {
    description = "JSON implementation in C";
    longDescription = ''
      JSON-C implements a reference counting object model that allows you to
      easily construct JSON objects in C, output them as JSON formatted strings
      and parse JSON formatted strings back into the C representation of JSON
      objects.
    '';
    homepage = "https://github.com/json-c/json-c/wiki";
    changelog = "https://github.com/json-c/json-c/blob/${finalAttrs.src.rev}/ChangeLog";
    platforms = lib.platforms.unix;
    license = lib.licenses.mit;
    identifiers.cpeParts = {
      vendor = "json-c_project";
      product = "json-c";
    };
  };
})
