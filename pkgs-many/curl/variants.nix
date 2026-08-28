{
  minimal = {
    # This is the curl that bootstraps `fetchurl`, so every dependency it keeps
    # has to be built before anything can be downloaded. zlib and http2 earn
    # their place: every source fetch in the tree goes through this curl, and
    # `NIX_CURL_FLAGS=--compressed` needs zlib. scp has to be turned off by
    # hand -- it defaults to `zlibSupport`, and nothing is ever fetched over ssh.
    zlibSupport = true;
    opensslSupport = true;
    http2Support = true;
    # Explicitly disable extra features
    scpSupport = false;
    idnSupport = false;
    pslSupport = false;
    zstdSupport = false;
    http3Support = false;
    c-aresSupport = false;
    brotliSupport = false;
    gssSupport = false;
  };

  v8_17 = {
    version = "8.17.0";
    hash = "sha256-lV9ucprWs1ZiYOj+9oYg52ujwxrPChhSRBahhaz3eZI=";
    idnSupport = true;
    pslSupport = true;
    zstdSupport = true;
    http3Support = true;
    c-aresSupport = true;
    brotliSupport = true;
  };

  v8_21 = {
    version = "8.21.0";
    hash = "sha256-qhtmpw6s6D3GJFCHRWRsCK5WHeUSq0A63/uTrIf8cuY=";
    idnSupport = true;
    pslSupport = true;
    zstdSupport = true;
    http3Support = true;
    c-aresSupport = true;
    brotliSupport = true;
  };

  full = { };

  gnutls = {
    gnutlsSupport = true;
    opensslSupport = false;
  };
}
