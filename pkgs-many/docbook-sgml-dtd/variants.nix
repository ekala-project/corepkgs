{
  v3_1 = rec {
    version = "3.1";
    src-url = "http://www.oasis-open.org/docbook/sgml/${version}/docbk31.zip";
    src-hash = "sha256:0f25ch7bywwhdxb1qa0hl28mgq1blqdap3rxzamm585rf4kis9i0";
    isoents-url = "http://www.oasis-open.org/cover/ISOEnts.zip";
    isoents-hash = "sha256:1clrkaqnvc1ja4lj8blr0rdlphngkcda3snm7b9jzvcn76d3br6w";
  };

  v4_1 = rec {
    version = "4.1";
    src-url = "http://www.oasis-open.org/docbook/sgml/${version}/docbk41.zip";
    src-hash = "sha256:04b3gp4zkh9c5g9kvnywdkdfkcqx3kjc04j4mpkr4xk7lgqgrany";
    isoents-url = "https://web.archive.org/web/20250220122223/http://xml.coverpages.org/ISOEnts.zip";
    isoents-hash = "sha256:1clrkaqnvc1ja4lj8blr0rdlphngkcda3snm7b9jzvcn76d3br6w";
  };
}
