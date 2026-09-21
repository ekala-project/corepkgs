{
  lib,
  fetchCrate,
  rustPlatform,
  clang,
  rustfmt,
  runUnitTests,
}:
let
  # bindgen hardcodes rustfmt outputs that use nightly features
  rustfmt-nightly = rustfmt.override { asNightly = true; };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rust-bindgen-unwrapped";
  version = "0.73.2";

  src = fetchCrate {
    pname = "bindgen-cli";
    inherit (finalAttrs) version;
    hash = "sha256-9RAgvrLO0Z2pu89ANmsolZjpNuRkm1jwxtXsNzpGi6w=";
  };

  cargoHash = "sha256-BRHAzgSbBYSJKThws/RcbCqwnNBbdzC7O8hHcdlguPo=";

  preConfigure = ''
    export LIBCLANG_PATH="${lib.getLib clang.cc}/lib"
  '';

  # Disable the "runtime" feature, so libclang is linked.
  buildNoDefaultFeatures = true;
  buildFeatures = [ "logging" ];
  checkNoDefaultFeatures = finalAttrs.buildNoDefaultFeatures;
  checkFeatures = finalAttrs.buildFeatures;

  nativeCheckInputs = [ clang ];

  RUSTFMT = "${rustfmt-nightly}/bin/rustfmt";

  preCheck = ''
    # for the ci folder, notably
    patchShebangs .
  '';

  passthru = {
    inherit clang;
    tests.unittests = runUnitTests finalAttrs.finalPackage;
  };

  meta = {
    description = "Automatically generates Rust FFI bindings to C (and some C++) libraries";
    longDescription = ''
      Bindgen takes a c or c++ header file and turns them into
      rust ffi declarations.
    '';
    homepage = "https://github.com/rust-lang/rust-bindgen";
    license = with lib.licenses; [ bsd3 ];
    mainProgram = "bindgen";
    platforms = lib.platforms.unix;
  };
})
