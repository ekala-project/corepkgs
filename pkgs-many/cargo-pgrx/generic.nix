{
  version,
  hash,
  cargoHash,
  mkVariantPassthru,
  ...
}@variantArgs:

{
  fetchCrate,
  lib,
  openssl,
  pkg-config,
  rustPlatform,
}:

(rustPlatform.buildRustPackage {
  pname = "cargo-pgrx";

  inherit version;

  src = fetchCrate {
    inherit version hash;
    pname = "cargo-pgrx";
  };

  inherit cargoHash;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ];

  preCheck = ''
    export PGRX_HOME=$(mktemp -d)
  '';

  checkFlags = [
    # requires pgrx to be properly initialized with cargo pgrx init
    "--skip=command::schema::tests::test_parse_managed_postmasters"
  ];

  meta = {
    description = "Build Postgres Extensions with Rust";
    homepage = "https://github.com/pgcentralfoundation/pgrx";
    changelog = "https://github.com/pgcentralfoundation/pgrx/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "cargo-pgrx";
  };
}).overrideAttrs
  (oldAttrs: {
    passthru =
      (oldAttrs.passthru or { })
      // mkVariantPassthru variantArgs
      // {
        inherit variantArgs;
      };
  })
