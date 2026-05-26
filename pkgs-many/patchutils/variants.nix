{
  v0_3_3 = {
    version = "0.3.3";
    src-hash = "0g5df00cj4nczrmr4k791l7la0sq2wnf8rn981fsrz1f3d2yix4i";
    patches = [ ./drop-comments.patch ]; # we would get into a cycle when using fetchpatch on this one
  };

  v0_3_4 = {
    version = "0.3.4";
    src-hash = "0xp8mcfyi5nmb5a2zi5ibmyshxkb1zv1dgmnyn413m7ahgdx8mfg";
  };

  v0_4_2 = {
    version = "0.4.2";
    src-hash = "sha256-iHWwll/jPeYriQ9s15O+f6/kGk5VLtv2QfH+1eu/Re0=";
    withPython = true; # for gitdiff
    patches = [ ./Make-grepdiff1-test-case-pcre-aware.patch ];
  };
}
