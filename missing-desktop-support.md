# Blocking Issues for Desktop/Graphical Stack Support

Issues discovered while porting a NixOS `configuration.nix` to evaluate under EkaOS/ekapkgs.

---

## 1. xorg.xorgserver fails to evaluate — missing `xorg.xtrans`, `xorg.libxcvt`, `xorg.pixman`

**Severity**: Blocks all X11 usage

`pkgs/xorg/overrides.nix` references `xorg.xtrans`, `xorg.libxcvt`, and `xorg.pixman` inside the `xorgserver` override (lines 407-408, 420, 622), but none of these are exposed as attributes of the xorg package set.

These packages exist at the top level (`pkgs.xtrans`, `pkgs.libxcvt`, `pkgs.pixman`) but the xorg scope doesn't include them.

**Error**:
```
error: attribute 'xtrans' missing
at .../pkgs/xorg/overrides.nix:407:11
Did you mean xtrap?
```

**Fix**: Either:
- Add `xtrans`, `libxcvt`, and `pixman` to the xorg scope (pass them into the xorg set and re-export them), or
- Change `overrides.nix` to reference them from the outer scope rather than `xorg.*`

**Files**:
- `pkgs/xorg/overrides.nix` (lines 407, 408, 420, 622)
- `pkgs/xorg/default.nix` (xorg set construction)

---

## 2. PostgreSQL service port contract missing required fields

**Severity**: Blocks enabling `services.postgresql`

The PostgreSQL service module at `ekaos/modules/services/databases/postgresql.nix` defines its port contract without the `hostname`, `path`, `tls`, and `healthCheck` fields:

```nix
ports.postgresql = {
  port = cfg.settings.port;
  protocol = "tcp";
  transport = "tcp";
  internal = cfg.settings.listenAddresses == "localhost";
  openFirewall = cfg.settings.listenAddresses != "localhost";
};
```

The port-contracts aggregation module at `ekaos/modules/networking/port-contracts.nix` (lines 25-35) destructures all of `port`, `protocol`, `transport`, `hostname`, `path`, `internal`, `openFirewall`, `tls`, `healthCheck` from every port contract. When PostgreSQL is enabled, this fails with:

```
error: attribute 'hostname' missing
at .../ekaos/modules/networking/port-contracts.nix:29:11
```

The OpenSSH module avoids this because it declares `ports` using the proper submodule type from `services/lib/types.nix` (`portContract`), which provides defaults for all fields. PostgreSQL sets ports as raw attrsets without the submodule.

**Fix**: Either:
- Use the `portContract` submodule type for PostgreSQL's `ports` option (like OpenSSH does), or
- Add the missing fields with defaults: `hostname = null; path = "/"; tls = { enable = false; forceRedirect = true; acme = false; }; healthCheck = { path = null; interval = 30; };`

**Recommendation**: Audit all service modules that define port contracts — any module that sets `ports.<name>` as a raw attrset (without the `portContract` submodule type) will hit this same error. The affected pattern is:

```nix
# Broken — missing fields
ports.myport = { port = 1234; protocol = "tcp"; ... };

# Fixed — use submodule type for ports option
ports = mkOption {
  type = types.attrsOf (
    types.submodule (import ../../../../services/lib/types.nix { inherit lib; }).portContract
  );
};
```

**Files**:
- `ekaos/modules/services/databases/postgresql.nix`
- `ekaos/modules/networking/port-contracts.nix`
- Potentially: `ekaos/modules/services/databases/redis.nix`, `ekaos/modules/services/security/vault.nix`, and any other service with ports

---

## 3. `boot.kernelPackages` has no default value

**Severity**: Blocks evaluation of any system configuration

The `boot.kernelPackages` option in `ekaos/modules/boot/kernel.nix` is declared without a default:

```nix
boot.kernelPackages = mkOption {
  type = types.unspecified;
  defaultText = "pkgs.linux.pkgs (linux 6.12)";
  # no `default = ...;`
};
```

The `defaultText` is documentation only — it doesn't set an actual default. Every configuration must explicitly set `boot.kernelPackages = pkgs.linux.pkgs;` or evaluation fails:

```
error: The option `boot.kernelPackages' was accessed but has no value defined.
```

**Fix**: Add `default = pkgs.linux.pkgs;` to the option declaration.

**File**: `ekaos/modules/boot/kernel.nix`

---

## 4. No mechanism for `allowUnfree` packages

**Severity**: Blocks Plex and other unfree packages

NixOS provides `nixpkgs.config.allowUnfree = true`. EkaOS has no equivalent mechanism. Any configuration that includes unfree packages (Plex, NVIDIA drivers, etc.) fails at evaluation time with the standard unfree error.

**Fix**: Add a config mechanism or pass `allowUnfree` through the package set construction. This could be:
- An `ekaos.config.allowUnfree` option, or
- A parameter to the `ekaosSystem` function, or
- A module that sets `pkgs.config.allowUnfree`

---

## Summary

| Issue | Blocks | Severity | Complexity |
|-------|--------|----------|------------|
| xorg scope missing xtrans/libxcvt/pixman | X server, LightDM, all X11 apps | Critical | Low (scope plumbing) |
| PostgreSQL port contract fields | `services.postgresql` | High | Low (add fields or use submodule) |
| `boot.kernelPackages` no default | All configs | High | Trivial (add default) |
| No `allowUnfree` mechanism | Plex, NVIDIA, proprietary packages | Medium | Medium (config plumbing) |
