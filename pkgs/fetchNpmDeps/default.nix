# fetchNpmDeps: Function for creating npm deps FOD (Fixed-Output Derivation)
#
# This creates a derivation that fetches npm dependencies from a package-lock.json
# file and stores them in a fixed-output derivation for reproducibility.

{
  lib,
  stdenvNoCC,
  cacert,
  prefetchNpmDeps,
}:

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

    nativeBuildInputs = nativeBuildInputs ++ [ prefetchNpmDeps ];

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
)
