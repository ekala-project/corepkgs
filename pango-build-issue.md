# Pango 1.57.1 Build Failure: stray '\' in pango-font.h

## Error

```
../pango/pango-font.h:134:20: error: stray '\' in program
  134 |   PANGO_WEIGHT_SEMILIGHT = 350,
```

`PANGO_WEIGHT_SEMILIGHT` appears to contain an invisible backslash character,
causing the C compiler to reject it.

## Impact

Blocks: graphviz, libnl, libpcap, htop, libvirt, iptables

## Notes

- No patches or substitutions are applied to pango source files
- Source hash matches official GNOME tarball
- Likely a character encoding issue in the source or an interaction with
  the meson build system / GCC preprocessor
- May be related to locale settings during build
