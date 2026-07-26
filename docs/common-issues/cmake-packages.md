# CMake Package Build Issues

## Install path issues

Major version bumps may change default CMake install directories. Outputs end up in unexpected locations, or files are installed to `$out/usr/lib` instead of `$out/lib`.

### Symptom

```
CMake Error at cmake_install.cmake:
  file INSTALL cannot find "/build/source/..."
```

Or the package builds but outputs are empty or misplaced.

### Fix

Add explicit install directory flags:

```nix
cmakeFlags = [
  "-DCMAKE_INSTALL_INCLUDEDIR=include"
  "-DCMAKE_INSTALL_LIBDIR=lib"
];
```

For packages that already have `cmakeFlags`, append to the existing list:

```nix
cmakeFlags = [
  "-H.."  # existing flag
  "-DCMAKE_INSTALL_INCLUDEDIR=include"
  "-DCMAKE_INSTALL_LIBDIR=lib"
];
```

## Testing flags

Some packages need testing explicitly enabled to build test infrastructure that other packages depend on:

```nix
cmakeFlags = [
  "-DBUILD_TESTING=ON"
];
```

## Feature flags changed between versions

Major version bumps may rename or remove CMake options. Check the upstream `CMakeLists.txt` for the current option names. Common renames:

- `BUILD_SHARED_LIBS` stays stable
- `ENABLE_*` vs `WITH_*` vs `*_SUPPORT` varies by project
- `CMAKE_INSTALL_*DIR` variables follow GNUInstallDirs conventions
