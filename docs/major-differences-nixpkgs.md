# Major differences from Nixpkgs

Although there is desire to keep as aligned with Nixpkgs as possible, Ekapkgs
isn't obligated to retain poor UX paradigms either. In that vein, the following
changes differ significantly from whath one would expct with Nixpkgs.

## Evaluation behavior

- `~/.config/nix` is no longer respected for `config` or `overlays`
- `config.gitConfig` and `config.gitConfigFile` were removed
  - Globally altering git behavior should be done at the machine level

## Package paradigms

- setupHooks for build managers are now explicit and opt-in.
  - E.g. `meson.configurePhaseHook` now needs to be specified.
