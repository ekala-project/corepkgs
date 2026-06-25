{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rust-cbindgen";
  version = "0.29.2";

  src = fetchFromGitHub {
    owner = "mozilla";
    repo = "cbindgen";
    rev = "v${finalAttrs.version}";
    hash = "sha256-P2A+XSLrcuYsI48gnZSNNs5qX+EatiuEJSEJbMvMSxg=";
  };

  cargoHash = "sha256-DbmlpjiOraLWPh5RgJqCIGIYzE1h82MH2S6gpLH+CIQ=";

  # Tests require cython and rust nightly features
  doCheck = false;

  meta = {
    description = "Tool for generating C bindings to Rust code";
    homepage = "https://github.com/mozilla/cbindgen";
    license = lib.licenses.mpl20;
    maintainers = [ ];
    mainProgram = "cbindgen";
  };
})
