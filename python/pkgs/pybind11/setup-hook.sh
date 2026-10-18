# Tell the pybind11 CMake module where to find host platform Python. This is
# required when cross-compiling.
pybind11CMakeFlags () {
  # Only set cmake entries when cmake is available
  if declare -F setCMakeEntry > /dev/null; then
    setCMakeEntryBool PYBIND11_PYTHONLIBS_OVERWRITE OFF
    setCMakeEntry PYTHON_EXECUTABLE '@pythonInterpreter@'
    setCMakeEntry PYTHON_INCLUDE_DIR '@pythonIncludeDir@'
    setCMakeEntry PYTHON_SITE_PACKAGES '@pythonSitePackages@'
  fi
}

preConfigureHooks+=(pybind11CMakeFlags)
