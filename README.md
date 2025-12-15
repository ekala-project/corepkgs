# Core-pkgs (WIP)

This repository is meant to be the provider of most common
development concerns for a nixpkgs fork. There should
be a high degree of scrutiny and quality put into the nix
expressions in this repository, as it will impact the most
use cases.

## Major differences from Nixpkgs

See [Major differences document](./docs/major-differences-nixpkgs.md).

## Package criteria

At a very high level, corepkgs is intended to include:
- Stdenv
- Compilers, interpreters, and toolchains
  - Common language ecosystem tools (e.g. popular linters, package managers) are included as well
- Logic around using overlays and most package scopes
- Ecosystems necessary system creation (e.g. systemd)
- And their dependencies

The goal is to allow for corepkgs to be a viable platform for people wanting
to do development and software deployments without the breadth of user tools
and other nicities. This reduced scope should allow for updates to be applied
more frequently and cause less rebuild churn than something the size of nixpkgs.

## Guiding design principles

These are a set of guiding principles when making packaging or process decisions.
Generally, this will cause divergence from Nixpkgs.

- Explict over implict
- Intuitive over pedantic
- Good defaults over assumed configuration
- Automation over manual
- Fun over drudgery

## Structure

```
build-support # Fetchers, shell hooks, and nix utilities
os-specific   # For packages which are platform-specific
pkgs/         # Subdirectories are automatically imported to pkgs
python/       # Python related packaging
  pkgs/       # Directory for python package set, automatically imported
perl/         # Perl related packaging (interpreter) and packages
top-level.nix # Overlay for specifying overrides at `pkgs` scope
default.nix   # Entry point for people to import
```

## Binary cache

*WARNING*: This is a personal server, and should be considered untrusted

```
substituters = https://ekala-corepkgs.cachix.org
trusted-public-keys = ekala-corepkgs.cachix.org-1:DcZV+vegWoEzacbSdXFXU4S7728C0eS9RfGpKeyHd6w=
```
