{
  stdenv,
  lib,
  rustPlatform,
  rustc,
}:

rustPlatform.buildRustPackage {
  pname = "clippy";
  inherit (rustc) version src;

  separateDebugInfo = true;

  # the rust source tarball already has all the dependencies vendored, no need to fetch them again
  cargoVendorDir = "vendor";
  buildAndTestSubdir = "src/tools/clippy";

  # changes hash of vendor directory otherwise
  dontUpdateAutotoolsGnuConfigScripts = true;

  buildInputs = [ rustc.llvm ];

  # fixes: error: the option `Z` is only accepted on the nightly compiler
  env.RUSTC_BOOTSTRAP = 1;

  # passthru.tests = {
  #   build = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };
  # };
  # Tests disabled: build fails with "error: failed to run custom build command for rustc_llvm"
  # Clippy uses rustc_driver and std private libraries with @rpath install names on macOS

  preFixup = lib.optionalString stdenv.hostPlatform.isDarwin ''
    install_name_tool -add_rpath "${rustc.unwrapped}/lib" "$out/bin/clippy-driver"
    install_name_tool -add_rpath "${rustc.unwrapped}/lib" "$out/bin/cargo-clippy"
  '';

  meta = {
    homepage = "https://rust-lang.github.io/rust-clippy/";
    description = "Bunch of lints to catch common mistakes and improve your Rust code";
    mainProgram = "cargo-clippy";
    license = with lib.licenses; [
      mit
      asl20
    ];
    platforms = lib.platforms.unix;
  };
}
