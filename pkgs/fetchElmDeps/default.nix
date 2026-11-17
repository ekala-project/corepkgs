# Produces a shell snippet (typically used as configurePhase) that lays out
# an $ELM_HOME so `elm make` runs offline.
#
# Elm resolves packages from $ELM_HOME/<elm version>/packages and only goes
# online when one is missing or the registry snapshot is absent.
# `elmPackages` maps "author/project" to { version, sha256 }, where sha256 is
# the hash of the *unpacked* GitHub tarball (`nix-prefetch-url --unpack`).
{
  lib,
  fetchzip,
}:

{
  elmPackages,
  registryDat,
  elmVersion,
}:

let
  packagesDir = "$ELM_HOME/${elmVersion}/packages";
  installPackage =
    name:
    { version, sha256 }:
    let
      src = fetchzip {
        url = "https://github.com/${name}/archive/${version}.tar.gz";
        inherit sha256;
      };
    in
    ''
      mkdir -p "${packagesDir}/${name}"
      cp -R ${src} "${packagesDir}/${name}/${version}"
    '';
in
''
  export ELM_HOME="$TMPDIR/elm-home"
  ${lib.concatStrings (lib.mapAttrsToList installPackage elmPackages)}
  cp ${registryDat} "${packagesDir}/registry.dat"
  # elm writes compiled artifacts next to each package.
  chmod -R u+w "$ELM_HOME"
''
