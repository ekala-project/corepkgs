# rust-analyzer — Language server for Rust (wrapped with RUST_SRC_PATH)
{
  rustPlatform,
  runCommand,
  makeWrapper,
  rust-analyzer-unwrapped,
}:

runCommand "rust-analyzer-${rust-analyzer-unwrapped.version}"
  {
    pname = "rust-analyzer";
    inherit (rust-analyzer-unwrapped) version src meta;
    nativeBuildInputs = [ makeWrapper ];
  }
  ''
    mkdir -p $out/bin
    makeWrapper ${rust-analyzer-unwrapped}/bin/rust-analyzer $out/bin/rust-analyzer \
      --set-default RUST_SRC_PATH "${rustPlatform.rustLibSrc}"
  ''
