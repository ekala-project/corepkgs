{
  lib,
  stdenv,
  fetchurl,
  perl,
  bind,
  xfsprogs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "userspace-rcu";
  version = "0.14.1";

  src = fetchurl {
    url = "https://lttng.org/files/urcu/userspace-rcu-${finalAttrs.version}.tar.bz2";
    hash = "sha256-IxrLE9xuwCPoNqDwZm9qq0fcYh7LHSzZ2cIvkiZ4q8A=";
  };

  nativeBuildInputs = [
    perl # for tests
  ];

  outputs = [
    "out"
    "dev"
  ];

  configureFlags = [
    "--disable-static"
  ];

  enableParallelBuilding = true;

  doCheck = false; # Skip tests for faster builds

  passthru.tests = {
    inherit bind xfsprogs;
  };

  meta = {
    homepage = "https://liburcu.org/";
    description = "Userspace RCU (read-copy-update) library";
    longDescription = ''
      The userspace-rcu library provides a set of APIs for implementing
      Read-Copy Update (RCU) synchronization. RCU is a synchronization
      mechanism that allows readers to access data structures without locks,
      while writers perform updates in a way that doesn't interfere with
      concurrent readers.

      This library is used by various high-performance applications that need
      efficient concurrent data structure access, including xfsprogs and BIND.
    '';
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
})
