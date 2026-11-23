{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  dtc,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libyaml";
  version = "0.2.6";

  src = fetchFromGitHub {
    owner = "yaml";
    repo = "libyaml";
    tag = finalAttrs.version;
    sha256 = "sha256-XhjyTxPoGiPcUdE1xATaLExSGx0/hzqhA7XxPqEIBi4=";
  };

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [ autoreconfHook ];

  passthru.tests = {
    inherit dtc;
  };

  meta = {
    homepage = "https://pyyaml.org/";
    description = "YAML 1.1 parser and emitter written in C";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "pyyaml" finalAttrs.version;
  };
})
