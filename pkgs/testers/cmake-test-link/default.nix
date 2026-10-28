# Static arguments
{
  lib,
  runCommandCC,
  cmake,
  writeText,
}:

# Tester arguments
{
  package,
  # cmake module names for find_package() (e.g. [ "ZLIB" ])
  moduleNames,
  # cmake target names for target_link_libraries() (e.g. [ "ZLIB::ZLIB" ])
  targets,
  # Optional attrset { cmakeLists = ./CMakeLists.txt; source = ./test.c; }
  # to override the auto-generated files.
  example ? null,
  nativeBuildInputs ? [ ],
  buildInputs ? [ ],
  cmakeFlags ? [ ],
  testName ? "test-link-cmake-${package.pname or package.name}",
}:

let
  autoGenSource = writeText "testlink.c" ''
    int main(void) { return 0; }
  '';

  autoGenCMakeLists = writeText "CMakeLists.txt" ''
    cmake_minimum_required(VERSION 3.14)
    project(TestLink C)

    ${lib.concatMapStringsSep "\n" (m: "find_package(${m} REQUIRED)") moduleNames}

    add_executable(testlink testlink.c)
    target_link_libraries(testlink PRIVATE ${lib.concatStringsSep " " targets})
  '';
in

runCommandCC testName
  {
    inherit cmakeFlags;
    nativeBuildInputs = [
      cmake
      cmake.configurePhaseHook
    ]
    ++ nativeBuildInputs;
    buildInputs = [ package ] ++ buildInputs;
    meta = {
      description = "Test that ${package.name} cmake modules compile and link: ${lib.concatStringsSep ", " moduleNames}";
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

    ${
      if example != null then
        ''
          cp ${example.cmakeLists} CMakeLists.txt
          cp ${example.source} testlink.c
        ''
      else
        ''
          cp ${autoGenCMakeLists} CMakeLists.txt
          cp ${autoGenSource} testlink.c
        ''
    }

    echo "Testing cmake compile+link for modules: ${lib.concatStringsSep ", " moduleNames}"
    echo "  Targets: ${lib.concatStringsSep ", " targets}"

    echoCmd 'cmake flags' "''${cmakeFlags[@]}"
    cmake . "''${cmakeFlags[@]}"
    echo "  ✅ cmake configure successful"

    make testlink
    echo "  ✅ build successful -- compile+link verified"

    touch "$out"
  ''
