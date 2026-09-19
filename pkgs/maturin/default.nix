{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  libiconv,
  testers,
  nix-update-script,
  maturin,
  python3,
}:

rustPlatform.buildRustPackage rec {
  pname = "maturin";
  version = "1.15.0";

  src = fetchFromGitHub {
    owner = "PyO3";
    repo = "maturin";
    rev = "v${version}";
    hash = "sha256-elK82eg/m33GYNWeZUSfKxFVJS6fMRatHl66NgvxcxE=";
  };

  cargoHash = "sha256-WRVXmhwhbOf2Isjvyqw3d4scA5Vs8Vkyy1m7WC3xb0s=";

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    libiconv
  ];

  cargoTestFlags = [ "--lib" ];

  checkFlags = [
    # these tests require pyo3 crate not included in vendored deps
    "--skip=build_options::tests::"
    # these tests require files not included in the source
    "--skip=metadata::tests::test_implicit_readme"
    "--skip=metadata::tests::test_merge_metadata_from_pyproject_toml"
    "--skip=metadata::tests::test_pep639"
  ];

  passthru = {
    tests = {
      version = testers.testVersion { package = maturin; };
      pyo3 = python3.pkgs.callPackage ./pyo3-test {
        format = "pyproject";
        buildAndTestSubdir = "examples/word-count";
        preConfigure = "";

        nativeBuildInputs = with rustPlatform; [
          cargoSetupHook
          maturinBuildHook
        ];
      };
    };

    updateScript = nix-update-script { };
  };

  meta = {
    description = "Build and publish Rust crates Python packages";
    longDescription = ''
      Build and publish Rust crates with PyO3, rust-cpython, and
      cffi bindings as well as Rust binaries as Python packages.

      This project is meant as a zero-configuration replacement for
      setuptools-rust and Milksnake. It supports building wheels for
      Python and can upload them to PyPI.
    '';
    homepage = "https://github.com/PyO3/maturin";
    changelog = "https://github.com/PyO3/maturin/blob/v${version}/Changelog.md";
    license = with lib.licenses; [
      asl20 # or
      mit
    ];
    mainProgram = "maturin";
  };
}
