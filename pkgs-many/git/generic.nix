{
  version,
  src-url,
  src-hash,
  isMinimal ? false,
  withSsh ? false,
  guiSupport ? false,
  # null means "use platform default" (resolved below)
  packageAtLeast,
  packageOlder,
  mkVariantPassthru,
  ...
}@variantArgs:

{
  fetchurl,
  lib,
  stdenv,
  buildPackages,
  curl,
  openssl,
  zlib,
  zlib-ng,
  expat,
  perlPackages,
  python3,
  gettext,
  gnugrep,
  gnused,
  gawk,
  coreutils,
  openssh,
  pcre2,
  bash,
  asciidoc,
  texinfo,
  xmlto,
  docbook2x,
  docbook-xsl-nons,
  docbook_xml_dtd_45,
  libxslt,
  tcl,
  tk,
  makeWrapper,
  libiconv,
  libiconvReal,
  subversionClient,
  nixosTests,
  pkg-config,
  glib,
  libsecret,
  gzip,
  sysctl,
  deterministic-host-uname,
  doInstallCheck ? !stdenv.hostPlatform.isDarwin,
  tests,
}@pkgArgs:

let
  # Resolve platform-dependent defaults (null = auto-detect from platform)
  isCross = !(lib.systems.equals stdenv.buildPlatform stdenv.hostPlatform);

  perlSupport = !(isMinimal || isCross);
  osxkeychainSupport = !isMinimal && stdenv.hostPlatform.isDarwin;
  sendEmailSupport = perlSupport;
  svnSupport = !isMinimal && !isCross;
  withManual = !isMinimal;
  withLibsecret = !isMinimal && !stdenv.hostPlatform.isDarwin;
  effectiveCurl = if isMinimal then curl.minimal else curl;
  withZlibNg = !isMinimal;
  withpcre2 = !isMinimal;
  pythonSupport = !isMinimal;
in

assert osxkeychainSupport -> stdenv.hostPlatform.isDarwin;
assert sendEmailSupport -> perlSupport;
assert svnSupport -> perlSupport;

let
  svn = subversionClient.override { perlBindings = perlSupport; };
  gitwebPerlLibs = with perlPackages; [
    CGI
    HTMLParser
    CGIFast
    FCGI
    FCGIProcManager
    HTMLTagCloud
  ];

  perlLibs = [
    perlPackages.LWP
    perlPackages.URI
    perlPackages.TermReadKey
  ];

  smtpPerlLibs = [
    perlPackages.libnet
    perlPackages.NetSMTPSSL
    perlPackages.IOSocketSSL
    perlPackages.NetSSLeay
    perlPackages.AuthenSASL
    perlPackages.DigestHMAC
  ];

in

stdenv.mkDerivation (finalAttrs: {
  pname =
    "git"
    + lib.optionalString svnSupport "-with-svn"
    + lib.optionalString isMinimal "-minimal";
  inherit version;

  src = fetchurl {
    url = src-url;
    hash = src-hash;
  };

  outputs = [ "out" ] ++ lib.optional withManual "doc";
  separateDebugInfo = true;
  __structuredAttrs = true;

  enableParallelBuilding = true;
  enableParallelInstalling = true;

  patches = [
    ./docbook2texi.patch
    ./git-sh-i18n.patch
    ./git-send-email-honor-PATH.patch
  ]
  ++ lib.optionals withSsh [
    ./ssh-path.patch
  ];

  postPatch = ''
    substituteInPlace git-sh-i18n.sh \
        --subst-var-by gettext ${gettext}
    substituteInPlace contrib/credential/libsecret/Makefile \
        --replace-fail 'pkg-config' "$PKG_CONFIG"
  ''
  + lib.optionalString doInstallCheck ''
    patchShebangs t/*.sh
  ''
  + lib.optionalString withSsh ''
    for x in connect.c git-gui/lib/remote_add.tcl ; do
      substituteInPlace "$x" \
        --subst-var-by ssh "${openssh}/bin/ssh"
    done
  '';

  nativeBuildInputs = [
    deterministic-host-uname
    gettext
    perlPackages.perl
    makeWrapper
    pkg-config
  ]
  ++ lib.optionals withManual [
    asciidoc
    texinfo
    xmlto
    docbook2x
    docbook-xsl-nons
    docbook_xml_dtd_45
    libxslt
  ];
  buildInputs = [
    effectiveCurl
    openssl
    (if withZlibNg then zlib-ng else zlib)
    expat
    (if stdenv.hostPlatform.isFreeBSD then libiconvReal else libiconv)
    bash
  ]
  ++ lib.optionals perlSupport [ perlPackages.perl ]
  ++ lib.optionals guiSupport [
    tcl
    tk
  ]
  ++ lib.optionals withpcre2 [ pcre2 ]
  ++ lib.optionals withLibsecret [
    glib
    libsecret
  ];

  env.NIX_LDFLAGS =
    lib.optionalString (stdenv.cc.isGNU && stdenv.hostPlatform.libc == "glibc") "-lgcc_s"
    + lib.optionalString (stdenv.hostPlatform.isFreeBSD) "-lthr";

  configureFlags = [
    "ac_cv_prog_CURL_CONFIG=${lib.getDev effectiveCurl}/bin/curl-config"
  ]
  ++ lib.optionals (stdenv.buildPlatform != stdenv.hostPlatform) [
    "ac_cv_fread_reads_directories=yes"
    "ac_cv_snprintf_returns_bogus=no"
    "ac_cv_iconv_omits_bom=no"
  ];

  preBuild = ''
    makeFlagsArray+=( perllibdir=$out/$(perl -MConfig -wle 'print substr $Config{installsitelib}, 1 + length $Config{siteprefixexp}') )
  '';

  makeFlags = [
    "prefix=\${out}"
  ]
  ++ lib.optional withZlibNg "ZLIB_NG=1"
  ++ lib.optional (stdenv.buildPlatform == stdenv.hostPlatform) "SHELL_PATH=${stdenv.shell}"
  ++ (if perlSupport then [ "PERL_PATH=${perlPackages.perl}/bin/perl" ] else [ "NO_PERL=1" ])
  ++ (if pythonSupport then [ "PYTHON_PATH=${python3}/bin/python" ] else [ "NO_PYTHON=1" ])
  ++ lib.optionals stdenv.hostPlatform.isSunOS [
    "INSTALL=install"
    "NO_INET_NTOP="
    "NO_INET_PTON="
  ]
  ++ (if stdenv.hostPlatform.isDarwin then [ "NO_APPLE_COMMON_CRYPTO=1" ] else [ "sysconfdir=/etc" ])
  ++ lib.optionals stdenv.hostPlatform.isMusl [
    "NO_SYS_POLL_H=1"
    "NO_GETTEXT=YesPlease"
  ]
  ++ lib.optional withpcre2 "USE_LIBPCRE2=1"
  ++ lib.optional stdenv.hostPlatform.isDarwin "TKFRAMEWORK=/nonexistent";

  disallowedReferences = lib.optionals (stdenv.buildPlatform != stdenv.hostPlatform) [
    stdenv.shellPackage
  ];

  postBuild = ''
    local flagsArray=(
        ''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}}
        SHELL="$SHELL"
    )
    concatTo flagsArray makeFlags makeFlagsArray buildFlags buildFlagsArray
    echoCmd 'build flags' "''${flagsArray[@]}"
  ''
  + lib.optionalString withManual ''
    make -C Documentation PERL_PATH=${lib.getExe buildPackages.perlPackages.perl} "''${flagsArray[@]}"
  ''
  + ''
    make -C contrib/subtree "''${flagsArray[@]}" all ${lib.optionalString withManual "doc"}
  ''
  + lib.optionalString perlSupport ''
    make -C contrib/diff-highlight "''${flagsArray[@]}"
  ''
  + lib.optionalString osxkeychainSupport ''
    make -C contrib/credential/osxkeychain "''${flagsArray[@]}"
  ''
  + lib.optionalString withLibsecret ''
    make -C contrib/credential/libsecret "''${flagsArray[@]}"
  ''
  + ''
    unset flagsArray
  '';

  installFlags = [ "NO_INSTALL_HARDLINKS=1" ];

  preInstall =
    lib.optionalString osxkeychainSupport ''
      mkdir -p $out/libexec/git-core
      ln -s $out/share/git/contrib/credential/osxkeychain/git-credential-osxkeychain $out/libexec/git-core/

      mkdir -p $out/bin
      ln -s $out/libexec/git-core/git-credential-osxkeychain $out/bin/

      rm -f $PWD/contrib/credential/osxkeychain/git-credential-osxkeychain.o
    ''
    + lib.optionalString withLibsecret ''
      mkdir -p $out/libexec/git-core
      ln -s $out/share/git/contrib/credential/libsecret/git-credential-libsecret $out/libexec/git-core/

      mkdir -p $out/bin
      ln -s $out/libexec/git-core/git-credential-libsecret $out/bin/

      rm -f $PWD/contrib/credential/libsecret/git-credential-libsecret.o
    '';

  postInstall = ''
    local flagsArray=(
        ''${enableParallelInstalling:+-j''${NIX_BUILD_CORES}}
        SHELL="$SHELL"
    )
    concatTo flagsArray makeFlags makeFlagsArray installFlags installFlagsArray
    echoCmd 'install flags' "''${flagsArray[@]}"

    make -C contrib/subtree "''${flagsArray[@]}" install ${lib.optionalString withManual "install-doc"}
    rm -rf contrib/subtree

    mkdir -p $out/share/git
    cp -a contrib $out/share/git/
    mkdir -p $out/share/bash-completion/completions
    ln -s $out/share/git/contrib/completion/git-prompt.sh $out/share/bash-completion/completions/

    substituteInPlace $out/libexec/git-core/git-sh-setup \
        --replace ' grep' ' ${gnugrep}/bin/grep' \
        --replace ' egrep' ' ${gnugrep}/bin/egrep'

    SCRIPT="$(cat <<'EOS'
      BEGIN{
        @a=(
          '${gnugrep}/bin/grep', '${gnused}/bin/sed', '${gawk}/bin/awk',
          '${coreutils}/bin/cut', '${coreutils}/bin/basename', '${coreutils}/bin/dirname',
          '${coreutils}/bin/wc', '${coreutils}/bin/tr'
          ${lib.optionalString perlSupport ", '${perlPackages.perl}/bin/perl'"}
        );
      }
      foreach $c (@a) {
        $n=(split("/", $c))[-1];
        s|(?<=[^#][^/.-])\b''${n}(?=\s)|''${c}|g
      }
    EOS
    )"
    perl -0777 -i -pe "$SCRIPT" \
      $out/libexec/git-core/git-{sh-setup,filter-branch,merge-octopus,mergetool,quiltimport,request-pull,submodule,subtree,web--browse}


    ln -s $out/libexec/git-core/git-http-backend $out/bin/git-http-backend
    ln -s $out/share/git/contrib/git-jump/git-jump $out/bin/git-jump
  ''
  + lib.optionalString perlSupport ''
    makeWrapper "$out/share/git/contrib/credential/netrc/git-credential-netrc.perl" $out/libexec/git-core/git-credential-netrc \
                --set PERL5LIB   "$out/${perlPackages.perl.libPrefix}:${perlPackages.makePerlPath perlLibs}"
    ln -s $out/libexec/git-core/git-credential-netrc $out/bin/

    wrapProgram $out/libexec/git-core/git-cvsimport \
                --set GITPERLLIB "$out/${perlPackages.perl.libPrefix}:${perlPackages.makePerlPath perlLibs}"
    wrapProgram $out/libexec/git-core/git-archimport \
                --set GITPERLLIB "$out/${perlPackages.perl.libPrefix}:${perlPackages.makePerlPath perlLibs}"
    wrapProgram $out/libexec/git-core/git-instaweb \
                --set GITPERLLIB "$out/${perlPackages.perl.libPrefix}:${perlPackages.makePerlPath perlLibs}"
    wrapProgram $out/libexec/git-core/git-cvsexportcommit \
                --set GITPERLLIB "$out/${perlPackages.perl.libPrefix}:${perlPackages.makePerlPath perlLibs}"

    sed -i -e "s|'compressor' => \['gzip'|'compressor' => ['${gzip}/bin/gzip'|" \
        $out/share/gitweb/gitweb.cgi
    for p in ${lib.concatStringsSep " " gitwebPerlLibs}; do
        sed -i -e "/use CGI /i use lib \"$p/${perlPackages.perl.libPrefix}\";" \
            "$out/share/gitweb/gitweb.cgi"
    done
  ''

  + (
    if svnSupport then
      ''
        wrapProgram $out/libexec/git-core/git-svn \
          --set GITPERLLIB "$out/${perlPackages.perl.libPrefix}:${
            perlPackages.makePerlPath (perlLibs ++ [ svn.out ])
          }" \
          --prefix PATH : "${svn.out}/bin"
      ''
    else
      ''
        rm $out/libexec/git-core/git-svn
      ''
  )

  + (
    if sendEmailSupport then
      ''
        wrapProgram $out/libexec/git-core/git-send-email \
                     --set GITPERLLIB "$out/${perlPackages.perl.libPrefix}:${perlPackages.makePerlPath smtpPerlLibs}"
      ''
    else
      ''
        rm $out/libexec/git-core/git-send-email
      ''
  )

  + lib.optionalString withManual ''
    make "''${flagsArray[@]}" install install-html \
      -C Documentation
  ''

  + (
    if guiSupport then
      ''
        for prog in bin/gitk libexec/git-core/{git-gui,git-citool,git-gui--askpass}; do
          sed -i -e "s|exec 'wish'|exec '${tk}/bin/wish'|g" \
                 -e "s|exec wish|exec '${tk}/bin/wish'|g" \
                 "$out/$prog"
        done
        ln -s $out/share/git/contrib/completion/git-completion.bash $out/share/bash-completion/completions/gitk
      ''
    else
      ''
        for prog in bin/gitk libexec/git-core/git-gui; do
          rm "$out/$prog"
        done
      ''
  )
  + lib.optionalString osxkeychainSupport ''
    mkdir -p $out/etc
    cat > $out/etc/gitconfig << EOF
    [credential]
      helper = osxkeychain
    EOF
  ''
  + ''
    unset flagsArray
  '';

  doCheck = false;
  doInstallCheck = false;

  installCheckTarget = "test";

  installCheckFlags = [
    "DEFAULT_TEST_TARGET=prove"
    "PERL_PATH=${buildPackages.perl}/bin/perl"
  ];

  nativeInstallCheckInputs = lib.optional (
    stdenv.hostPlatform.isDarwin || stdenv.hostPlatform.isFreeBSD
  ) sysctl;

  preInstallCheck = ''
    if ((NIX_BUILD_CORES > 32)); then
      NIX_BUILD_CORES=32
    fi

    installCheckFlagsArray+=(
      GIT_PROVE_OPTS="--jobs $NIX_BUILD_CORES --failures --state=failed,save"
      GIT_TEST_INSTALLED=$out/bin
      ${lib.optionalString (!svnSupport) "NO_SVN_TESTS=y"}
    )

    function disable_test {
      local test=$1 pattern=$2
      if [ $# -eq 1 ]; then
        mv t/{,skip-}$test.sh || true
      else
        sed -i t/$test.sh \
          -e "/^\s*test_expect_.*$pattern/,/^\s*' *\$/{s/^/: #/}"
      fi
    }

    substituteInPlace t/test-lib.sh \
      --replace "test_set_prereq POSIXPERM" ""
    disable_test t0001-init 'shared overrides system'
    disable_test t0001-init 'init honors global core.sharedRepository'
    disable_test t1301-shared-repo
    disable_test t9902-completion
  ''
  + lib.optionalString (!sendEmailSupport) ''
    disable_test t9001-send-email
  ''
  + ''
    disable_test t0027-auto-crlf
    disable_test t1451-fsck-buffer
    disable_test t5319-multi-pack-index
    disable_test t6421-merge-partial-clone
    disable_test t7504-commit-msg-hook
    disable_test t5515-fetch-merge-logic
    disable_test t4104-apply-boundary
    disable_test t7002-mv-sparse-checkout
    disable_test t4122-apply-symlink-inside
    disable_test t7513-interpret-trailers
    disable_test t2200-add-update

    disable_test t0021-conversion
    disable_test t3910-mac-os-precompose
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    disable_test t7816-grep-binary-pattern
    disable_test t6300-for-each-ref
    disable_test t5003-archive-zip
  ''
  + lib.optionalString (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64) ''
    disable_test t7527-builtin-fsmonitor
  ''
  +
    lib.optionalString (stdenv.hostPlatform.isStatic && stdenv.hostPlatform.system == "x86_64-linux")
      ''
        disable_test t2082-parallel-checkout-attributes
      ''
  + lib.optionalString stdenv.hostPlatform.isMusl ''
    disable_test t3900-i18n-commit
    disable_test t0028-working-tree-encoding
  '';

  stripDebugList = [
    "lib"
    "libexec"
    "bin"
    "share/git/contrib/credential"
  ];

  passthru = mkVariantPassthru variantArgs // {
    shellPath = "/bin/git-shell";
    tests = {
      withInstallCheck = finalAttrs.finalPackage.overrideAttrs (_: {
        doInstallCheck = true;
      });
      buildbot-integration = nixosTests.buildbot;
    }
    // tests.fetchgit;
  };

  meta = {
    homepage = "https://git-scm.com/";
    description = "Distributed version control system";
    license = lib.licenses.gpl2;
    changelog = "https://github.com/git/git/blob/v${version}/Documentation/RelNotes/${version}.txt";
    longDescription = ''
      Git, a popular distributed version control system designed to
      handle very large projects with speed and efficiency.
    '';
    platforms = lib.platforms.all;
    mainProgram = "git";
  };
})
