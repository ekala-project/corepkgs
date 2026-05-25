# Import fetchNpmDeps from nixpkgs
#
# core-pkgs doesn't have the full Rust/Cargo infrastructure to build
# prefetch-npm-deps from source, so we import the implementation from nixpkgs.
#
# This provides:
# - prefetch-npm-deps: CLI tool for computing npm deps hash
# - fetchNpmDeps: Function for creating npm deps FOD

{
  lib,
  stdenvNoCC,
  cacert,
}:

let
  # Import nixpkgs fetchNpmDeps implementation
  nixpkgs = import <nixpkgs> { };

  # Use nixpkgs prefetch-npm-deps binary
  prefetch-npm-deps-binary = nixpkgs.prefetch-npm-deps;

  # Adapted fetchNpmDeps for core-pkgs
  fetchNpmDeps =
    {
      name ? "npm-deps",
      hash ? "",
      forceGitDeps ? false,
      forceEmptyCache ? false,
      nativeBuildInputs ? [ ],
      ...
    }@args:
    let
      hash_ =
        if hash != "" then
          {
            outputHash = hash;
          }
        else
          {
            outputHash = "";
            outputHashAlgo = "sha256";
          };

      forceGitDeps_ = lib.optionalAttrs forceGitDeps { FORCE_GIT_DEPS = true; };
      forceEmptyCache_ = lib.optionalAttrs forceEmptyCache { FORCE_EMPTY_CACHE = true; };
    in
    stdenvNoCC.mkDerivation (
      args
      // {
        inherit name;

        nativeBuildInputs = nativeBuildInputs ++ [ prefetch-npm-deps-binary ];

        buildPhase = ''
          runHook preBuild

          if [[ ! -e package-lock.json ]]; then
            echo
            echo "ERROR: The package-lock.json file does not exist!"
            echo
            echo "package-lock.json is required to make sure that npmDepsHash doesn't change"
            echo "when packages are updated on npm."
            echo
            echo "Hint: You can copy a vendored package-lock.json file via postPatch."
            echo

            exit 1
          fi

          prefetch-npm-deps package-lock.json $out

          runHook postBuild
        '';

        dontInstall = true;

        # NIX_NPM_TOKENS environment variable should be a JSON mapping in the shape of:
        # `{ "registry.example.com": "example-registry-bearer-token", ... }`
        impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [ "NIX_NPM_TOKENS" ];

        SSL_CERT_FILE =
          if
            (
              hash_.outputHash == ""
              || hash_.outputHash == lib.fakeSha256
              || hash_.outputHash == lib.fakeSha512
              || hash_.outputHash == lib.fakeHash
            )
          then
            "${cacert}/etc/ssl/certs/ca-bundle.crt"
          else
            "/no-cert-file.crt";

        outputHashMode = "recursive";
      }
      // hash_
      // forceGitDeps_
      // forceEmptyCache_
    );
in
{
  inherit prefetch-npm-deps-binary fetchNpmDeps;

  # Alias for compatibility
  prefetch-npm-deps = prefetch-npm-deps-binary;
}
