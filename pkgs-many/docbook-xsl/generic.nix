{
  version,
  src-hash,
  suffix,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  replaceVars,
  fetchurl,
  fetchpatch,
  findXMLCatalogs,
  writeScriptBin,
  ruby,
  bash,
  withManOptDedupPatch ? false,
}:

let
  legacySuffix = lib.optionalString (suffix != "-nons") "-ns";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "docbook-xsl" + (if suffix == "-nons" then "-nons" else "-ns");
  inherit version;

  src = fetchurl {
    url = "https://github.com/docbook/xslt10-stylesheets/releases/download/release%2F${finalAttrs.version}/docbook-xsl${suffix}-${finalAttrs.version}.tar.bz2";
    hash = src-hash;
  };

  patches = [
    # Prevent a potential stack overflow
    # https://github.com/docbook/xslt10-stylesheets/pull/37
    (fetchpatch {
      url = "https://src.fedoraproject.org/rpms/docbook-style-xsl/raw/e3ae7a97ed1d185594dd35954e1a02196afb205a/f/docbook-style-xsl-non-recursive-string-subst.patch";
      sha256 = "0lrjjg5kpwwmbhkxzz6i5zmimb6lsvrrdhzc2qgjmb3r6jnsmii3";
      stripLen = "1";
    })

    # Fix reproducibility by respecting generate.consistent.ids in indexes
    # https://github.com/docbook/xslt10-stylesheets/pull/88
    # https://sourceforge.net/p/docbook/bugs/1385/
    (fetchpatch {
      url = "https://github.com/docbook/xslt10-stylesheets/commit/07631601e6602bc49b8eac3aab9d2b35968d3e7a.patch";
      sha256 = "0igfhcr6hzcydqsnjsd181h5yl3drjnrwdmxcybr236m8255vkq3";
      stripLen = "1";
    })

    # Add legacy sourceforge.net URIs to the catalog
    (replaceVars ./catalog-legacy-uris.patch {
      inherit legacySuffix suffix;
      version = finalAttrs.version;
    })
  ]
  ++ lib.optionals withManOptDedupPatch [
    # Fixes https://github.com/NixOS/nixpkgs/issues/166304
    # https://github.com/docbook/xslt10-stylesheets/pull/241
    ./fix-man-options-duplication.patch
  ];

  propagatedBuildInputs = [ findXMLCatalogs ];

  dontBuild = true;

  installPhase = ''
    dst=$out/share/xml/${finalAttrs.pname}
    mkdir -p $dst
    rm -rf RELEASE* README* INSTALL TODO NEWS* BUGS install.sh tools Makefile tests extensions webhelp
    mv * $dst/

    # Backwards compatibility. Will remove eventually.
    mkdir -p $out/xml/xsl
    ln -s $dst $out/xml/xsl/docbook

    # More backwards compatibility
    ln -s $dst $out/share/xml/docbook-xsl${legacySuffix}
  '';

  doCheck = false;

  passthru.tests.unit = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };
  passthru.dbtoepub = writeScriptBin "dbtoepub" ''
    #!${bash}/bin/bash
    exec -a dbtoepub ${ruby}/bin/ruby ${finalAttrs.finalPackage}/share/xml/${finalAttrs.pname}/epub/bin/dbtoepub "$@"
  '';

  meta = {
    homepage = "https://github.com/docbook/wiki/wiki/DocBookXslStylesheets";
    description = "XSL stylesheets for transforming DocBook documents into HTML and various other formats";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
