{
  lib,
  buildFHSEnvBubblewrap,
  coreutils,
  file,
  findutils,
  gawk,
  runCommand,
  squashfsTools,
  stdenv,
}:

let
  extractType1 =
    {
      name ? "appimage-type1",
      src,
    }:
    runCommand "${name}-extracted"
      {
        nativeBuildInputs = [
          coreutils
          file
          findutils
          gawk
        ];
        inherit src;
      }
      ''
        # Type 1 AppImages are ISO 9660 with an ELF header
        # Find the offset of the embedded filesystem
        offset=$(${lib.getExe' coreutils "od"} -A d -t x1 -j 8 -N 4 "$src" | \
          head -1 | awk '{for(i=2;i<=NF;i++) printf "%s", $i; print ""}' | \
          awk '{print strtonum("0x" $0)}')

        if [ -z "$offset" ] || [ "$offset" -eq 0 ]; then
          # Fallback: try unsquashfs on the whole file
          offset=0
        fi

        mkdir -p $out
        tail -c +$((offset + 1)) "$src" > /tmp/payload.squashfs
        ${lib.getExe' squashfsTools "unsquashfs"} -d $out /tmp/payload.squashfs
      '';

  extractType2 =
    {
      name ? "appimage-type2",
      src,
    }:
    runCommand "${name}-extracted"
      {
        nativeBuildInputs = [ squashfsTools ];
        inherit src;
      }
      ''
        # Type 2 AppImages have a runtime + squashfs appended
        # The runtime knows its own size, so we find where squashfs starts
        offset=$(grep -aobm1 'hsqs' "$src" | head -1 | cut -d: -f1)
        if [ -z "$offset" ]; then
          echo "Could not find squashfs magic in AppImage" >&2
          exit 1
        fi
        mkdir -p $out
        ${lib.getExe' squashfsTools "unsquashfs"} -d $out -o "$offset" "$src"
      '';

  wrapType1 =
    {
      name ? "appimage-wrapped",
      src,
      extraPkgs ? _: [ ],
      extraBwrapArgs ? [ ],
      ...
    }@args:
    wrapAppImage (
      {
        inherit name;
        appimage = extractType1 {
          inherit name src;
        };
        inherit extraPkgs extraBwrapArgs;
      }
      // removeAttrs args [
        "name"
        "src"
        "extraPkgs"
        "extraBwrapArgs"
      ]
    );

  wrapType2 =
    {
      name ? "appimage-wrapped",
      src,
      extraPkgs ? _: [ ],
      extraBwrapArgs ? [ ],
      ...
    }@args:
    wrapAppImage (
      {
        inherit name;
        appimage = extractType2 {
          inherit name src;
        };
        inherit extraPkgs extraBwrapArgs;
      }
      // removeAttrs args [
        "name"
        "src"
        "extraPkgs"
        "extraBwrapArgs"
      ]
    );

  wrapAppImage =
    {
      name ? "appimage-wrapped",
      appimage,
      extraPkgs ? _: [ ],
      extraBwrapArgs ? [ ],
      meta ? { },
      ...
    }@args:
    buildFHSEnvBubblewrap (
      {
        inherit name;
        targetPkgs = pkgs: [ appimage ] ++ extraPkgs pkgs;
        runScript = "${appimage}/AppRun";
        extraBwrapArgs = [ "--chdir ${appimage}" ] ++ extraBwrapArgs;
        inherit meta;
      }
      // removeAttrs args [
        "name"
        "appimage"
        "extraPkgs"
        "extraBwrapArgs"
        "meta"
      ]
    );
in
{
  inherit
    extractType1
    extractType2
    wrapType1
    wrapType2
    wrapAppImage
    ;
}
