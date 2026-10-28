# Static arguments
{
  lib,
  buildPackages,
  runCommand,
  writeText,
}:

# Tester arguments
{
  package,
  modules ? package.meta.pkgConfigModules or [ ],
  # Optional path to a C source file. When null, auto-generates a trivial main().
  example ? null,
  # Extra flags appended to the link command (e.g. [ "-lm" ]).
  extraFlags ? [ ],
  testName ? "test-link-pkg-config-${package.pname or package.name}",
}:

let
  autoGenSource = writeText "testlink.c" ''
    int main(void) { return 0; }
  '';
  sourceFile = if example != null then example else autoGenSource;
in

runCommand testName
  {
    nativeBuildInputs = [
      buildPackages.stdenv.cc
      buildPackages.pkg-config
    ];
    buildInputs = [ package ];
    inherit modules extraFlags;
    src = sourceFile;
    meta = {
      description = "Test that ${package.name} pkg-config modules compile and link: ${lib.concatStringsSep ", " modules}";
    }
    // builtins.intersectAttrs {
      available = throw "unused";
      broken = throw "unused";
      insecure = throw "unused";
      license = throw "unused";
      platforms = throw "unused";
      unfree = throw "unused";
      unsupported = throw "unused";
    } package.meta;
  }
  ''
    set -euo pipefail

    if (( ''${#modules[@]} == 0 )); then
      echo "ERROR: No pkg-config modules specified. Set modules or meta.pkgConfigModules."
      exit 1
    fi

    echo "Testing compile+link for pkg-config modules: ''${modules[*]}"

    # Verify modules exist first
    for module in "''${modules[@]}"; do
      if ! pkg-config --exists "$module"; then
        echo "❌ ERROR: pkg-config module $module not found"
        echo ""
        echo "Available modules:"
        pkg-config --list-all
        exit 1
      fi
      echo "  Module $module found ($(pkg-config --modversion "$module"))"
    done

    # Get flags
    cflags=$(pkg-config --cflags "''${modules[@]}")
    libs=$(pkg-config --libs "''${modules[@]}")
    echo "  CFLAGS: $cflags"
    echo "  LIBS:   $libs"

    # Compile
    echo "Compiling..."
    $CC $cflags -c "$src" -o test.o
    echo "  ✅ Compilation successful"

    # Link
    echo "Linking..."
    $CC test.o $libs ''${extraFlags[@]:+"''${extraFlags[@]}"} -o test-binary
    echo "  ✅ Linking successful"

    echo ""
    echo "✅ All compile+link tests passed for ${package.name}"
    touch "$out"
  ''
