{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  apr,
  aprutil,
  zlib,
  sqlite,
  openssl,
  lz4,
  utf8proc,
  autoconf,
  libtool,
  expat,
  serf,
  gettext,
  python3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "subversion";
  version = "1.14.5";

  src = fetchurl {
    url = "mirror://apache/subversion/subversion-${finalAttrs.version}.tar.bz2";
    sha256 = "sha256-54op53Zri3s1RJfQj3GlVkGrxTZ1zhh1WEeBquNWRKE=";
  };

  # Can't do separate $lib and $bin, as libs reference bins
  outputs = [
    "out"
    "dev"
    "man"
  ];

  nativeBuildInputs = [
    autoconf
    libtool
    gettext
    python3
  ];

  buildInputs = [
    zlib
    apr
    aprutil
    sqlite
    openssl
    lz4
    utf8proc
    serf
    expat
  ];

  strictDeps = true;

  patches = [
    ./apr-1.patch

    # swig-4.4 support:
    #   https://lists.apache.org/thread/7rtyfcmg737bnmnrwf6bjmlxx4wpq2og
    (fetchpatch {
      name = "swig-4.4.patch";
      url = "https://github.com/apache/subversion/commit/bf72420e86059a894fa3aacbbd6e3bee9286e46e.patch";
      hash = "sha256-0X9y/0qDDctKo1vu86pKu3k79zIqhOhQU9rvyG4v6jg=";
    })
  ];

  # remove vendored swig-3 files as these will shadow the swig provided
  # ones and result in compile errors
  postPatch = ''
    rm subversion/bindings/swig/proxy/{perlrun.swg,pyrun.swg,python.swg,rubydef.swg,rubyhead.swg,rubytracking.swg,runtime.swg,swigrun.swg} || true
  '';

  env = {
    # We are hitting the following issue even with APR 1.6.x
    # -> https://issues.apache.org/jira/browse/SVN-4813
    # "-P" CPPFLAG is needed to build Python bindings and subversionClient
    CPPFLAGS = toString [ "-P" ];
  };

  preConfigure = ''
    ./autogen.sh
  '';

  configureFlags = [
    "--without-berkeley-db"
    "--without-apxs"
    "--without-swig"
    "--without-sasl"
    "--with-serf=${serf}"
    "--with-zlib=${zlib.dev}"
    "--with-sqlite=${sqlite.dev}"
    "--with-apr=${apr.dev}"
    "--with-apr-util=${aprutil.dev}"
  ];

  postInstall = ''
    mkdir -p $out/share/bash-completion/completions
    cp tools/client-side/bash_completion $out/share/bash-completion/completions/subversion

    for f in $out/lib/*.la; do
      substituteInPlace $f \
        --replace "${expat.dev}/lib" "${expat.out}/lib" \
        --replace "${zlib.dev}/lib" "${zlib.out}/lib" \
        --replace "${sqlite.dev}/lib" "${sqlite.out}/lib" \
        --replace "${openssl.dev}/lib" "${lib.getLib openssl}/lib"
    done
  '';

  enableParallelBuilding = true;
  # Missing install dependencies:
  # libtool:   error: error: relink 'libsvn_ra_serf-1.la' with the above command before installing it
  # make: *** [build-outputs.mk:1316: install-serf-lib] Error 1
  enableParallelInstalling = false;

  doCheck = false;

  meta = {
    description = "Version control system intended to be a compelling replacement for CVS in the open source community";
    license = lib.licenses.asl20;
    homepage = "https://subversion.apache.org/";
    mainProgram = "svn";
    maintainers = [ ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
