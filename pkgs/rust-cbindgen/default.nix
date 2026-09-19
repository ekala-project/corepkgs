{
  lib,
  fetchFromGitHub,
  rustPlatform,
  cmake,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rust-cbindgen";
  version = "0.29.4";

  src = fetchFromGitHub {
    owner = "mozilla";
    repo = "cbindgen";
    rev = "v${finalAttrs.version}";
    hash = "sha256-leeHOwpzXuzg2cTjXehBnCsS+dvU4eIIFtWKeCee20U=";
  };

  cargoHash = "sha256-f6YoDoiVoh0BVPYHFO1FsdI4OCsF+LY72QaD57StdIQ=";

  # Tests require nightly rustc (-Zunpretty=expanded) and cython
  dontCargoCheck = true;

  meta = {
    description = "Tool for generating C bindings to Rust code";
    homepage = "https://github.com/mozilla/cbindgen";
    license = lib.licenses.mpl20;
    mainProgram = "cbindgen";
  };
})
