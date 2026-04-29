{
  icu78 = {
    version = "78.3";
    src-hash = "sha256-Oi56R2BLpwLzRYeDCOb+/sphLuiVz0pfIi55Vfq/4MA=";
  };
  icu77 = {
    version = "77.1";
    src-hash = "sha256-WI5DH3cyfDkDH/u4hDwOO8EiwhE3RIX6h9xfP6/yQGE=";
  };
  icu76 = {
    version = "76.1";
    src-hash = "sha256-36y0a/5HR0EEcs4+EUS/KKEC/uqk44dbrJtMbPMPTz4=";
  };
  icu75 = {
    version = "75.1";
    src-hash = "sha256-y5aN8+TS6H6LEcSaXQHHh70TuVRSgPxmQvgmUnYYyu8=";
  };
  icu74 = {
    version = "74.2";
    src-hash = "sha256-aNsIIhKpbW9T411g9H04uWLp+dIHp0z6x4Apro/14Iw=";
  };
  icu73 = {
    version = "73.2";
    src-hash = "sha256-gYqAcS7TyqzZtlIwXgGvx/oWfm8ulJltpEuQwqtgTOE=";
  };
  icu72 = {
    version = "72.1";
    src-hash = "sha256-otLTghcJKn7VZjXjRGf5L5drNw4gGCrTJe3qZoGnHWg=";
  };
  icu71 = {
    version = "71.1";
    src-hash = "sha256-Z6fm5R9h+vEwa2k1Mz4TssSKvY2m0vRs5q3KJLHiHr8=";
  };
  icu70 = {
    version = "70.1";
    src-hash = "sha256-jSBUKMF78Tu1NTAGae0oszihV7HAGuZtMdDT4tR8P9U=";
  };
  icu69 = {
    version = "69.1";
    src-hash = "sha256-TLp7es0dPELES7DBS+ZjcJjH+vKzMM6Ha8XzuRXQl0U=";
  };
  icu67 = {
    version = "67.1";
    src-hash = "sha256-lKgM1vJRpTvSqZf28bWsZlP+eR36tm4esCJ3QPuG1dw=";
  };
  icu66 = {
    version = "66.1";
    src-hash = "sha256-UqPyIJq5VVnBzwoU8kM4AB84lhW/AOJYXvPbxD7PCi4=";
  };
  icu64 = {
    version = "64.2";
    src-hash = "sha256-Yn1dhHjm2W/IyQ/tSFEjkHmlYaaoueSLCJLyToLTHWw=";
  };
  icu63 = {
    version = "63.1";
    src-hash = "sha256-BcSQtpRU/OWGC36OKCEjFnSvChHX7y/r6poyUSmYy50=";
    patches = [
      {
        # https://bugzilla.mozilla.org/show_bug.cgi?id=1499398
        url = "https://github.com/unicode-org/icu/commit/8baff8f03e07d8e02304d0c888d0bb21ad2eeb01.patch";
        sha256 = "1awfa98ljcf95a85cssahw6bvdnpbq5brf1kgspy14w4mlmhd0jb";
      }
    ];
    patchFlags = [ "-p3" ];
  };
  icu60 = {
    version = "60.2";
    src-hash = "sha256-8HPqjzW5JtcLsz5ld1CKpkKosxaoA/Eb4grzhIEdtBg=";
  };
}
