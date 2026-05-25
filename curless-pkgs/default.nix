# These packages are dependencies of curl, so that
# curl can not be used in their dpeendency tree.
# This include things such as fetchpatch which uses
# curl indirectly.
{
  lib,
  stdenv,
  buildPackages,
}:

lib.makeScope buildPackages.newScope (
  self: with self; {

    # This is what we are propagating in practice
    fetchurl = stdenv.fetchurlBoot;

    zlib = buildPackages.zlib.override {
      inherit fetchurl;
    };
    xz = buildPackages.xz.override {
      inherit fetchurl;
    };
    perl = buildPackages.perl.override {
      inherit zlib fetchurl;
    };

    pkg-config = buildPackages.pkg-config.override (old: {
      pkg-config = old.pkg-config.override {
        inherit fetchurl;
      };
    });

    coreutils = buildPackages.coreutils.override {
      inherit fetchurl perl xz;
      gmpSupport = false;
      aclSupport = false;
      attrSupport = false;
    };

    openssl = buildPackages.openssl.override {
      inherit fetchurl perl;
      buildPackages = { inherit coreutils perl; };
    };

    libssh2 = buildPackages.libssh2.override {
      inherit fetchurl zlib openssl;
    };
    byacc = buildPackages.byacc.override {
      inherit fetchurl;
    };
    keyutils = buildPackages.keyutils.override {
      inherit fetchurl;
    };
    libkrb5 = buildPackages.krb5.override {
      inherit
        fethcurl
        pkg-conig
        perl
        openssl
        byacc
        ;
      withLibedit = false;
    };

    nghttp2 = buildPackages.nghttp2.override {
      inherit fetchurl pkg-config;
      enableApp = false; # curl just needs libnghttp2
      enableTests = false; # avoids bringing `cunit` and `tzdata` into scope
    };

    curl = buildPackages.curl.minimal.override {
      inherit
        fetchurl
        zlib
        pkg-config
        perl
        openssl
        libssh2
        libkrb5
        nghttp2
        ;
    };
  }
)
