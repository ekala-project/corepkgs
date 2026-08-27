# Top-level attributes that deliberately refuse to evaluate because a package
# they need has not been ported to core-pkgs yet, or because they are only
# meaningful in a context this evaluation does not provide. `ci/eval.nix` skips
# these.
#
# Removing an entry here is the last step of porting a package. Only add one
# when the failure is a deliberate `throw` naming what is missing -- never to
# silence a genuine evaluation failure.
[
  # needs llvm/multi.nix ported
  "clangMultiStdenv"

  # only meaningful when building a cross compiler without a target libc
  "gccCrossLibcStdenv"

  # only meaningful when the target binaries cannot be executed natively
  "mesonEmulatorHook"

  # need prefetchNpmDeps, which has to be built from source
  "mongosh"
  "pnpmFixupStateDb"
  "wrangler"
]
