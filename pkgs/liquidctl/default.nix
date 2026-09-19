{
  lib,
  python3,
  fetchFromGitHub,
  installShellFiles,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "liquidctl";
  version = "1.16.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "liquidctl";
    repo = "liquidctl";
    tag = "v${finalAttrs.version}";
    hash = "sha256-NN/LPcRwj1c9xIIBmNCSLkb+8LHPIqH/YuLPm3kxqEQ=";
  };

  nativeBuildInputs = [ installShellFiles ];

  build-system = with python3.pkgs; [
    setuptools
    setuptools-scm
  ];

  dependencies = with python3.pkgs; [
    # TODO(corepkgs): missing python packages — add these as they become available
    # docopt
    # hidapi
    # pyusb
    # smbus-cffi
    # i2c-tools
    # colorlog
    # crcmod
    pillow
  ];

  # Disable runtime dependency check — most runtime deps (docopt, hidapi, pyusb,
  # smbus-cffi, i2c-tools, colorlog, crcmod) are not yet available in core-pkgs
  dontCheckRuntimeDeps = true;

  outputs = [
    "out"
    "man"
  ];

  postInstall = ''
    installManPage liquidctl.8
    installShellCompletion extra/completions/liquidctl.bash

    mkdir -p $out/lib/udev/rules.d
    cp extra/linux/71-liquidctl.rules $out/lib/udev/rules.d/.
  '';

  postBuild = ''
    # needed for pythonImportsCheck
    export XDG_RUNTIME_DIR=$TMPDIR
  '';

  # requires pyusb which is not yet available
  pythonImportsCheck = [ ];

  meta = {
    description = "Cross-platform CLI and Python drivers for AIO liquid coolers and other devices";
    homepage = "https://github.com/liquidctl/liquidctl";
    changelog = "https://github.com/liquidctl/liquidctl/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.gpl3Plus;
    mainProgram = "liquidctl";
    platforms = lib.platforms.linux;
  };
})
