final: prev:
let
  pkgs = final.pkgs;
in
with pkgs;
{
  # keep-sorted start
  autoconf269 = autoconf.v2_69;
  autoconf271 = autoconf.v2_71;
  automake116x = automake.v1_16;
  automake118x = automake.v1_18;
  go_1_24 = go.v1_24;
  go_1_25 = go.v1_25;
  perl538 = perl.v5_38;
  perl540 = perl.v5_40;
  tcl-8_5 = tcl.v8_5;
  tcl-8_6 = tcl.v8_6;
  tcl-9_0 = tcl.v9_0;
  # keep-sorted end
}
