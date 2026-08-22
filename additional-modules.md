# Additional EkaOS Modules Needed in Corepkgs

This document lists modules and option extensions that belong in corepkgs (not ekapkgs) because they are fundamental system-level concerns, not application-specific.

---

## Tier 1 — Boot Critical

### 1.1 ZFS Support (`boot/zfs.nix`)
**Status**: Missing entirely
**What's needed**:
- New module: `ekaos/modules/boot/zfs.nix`
- Options:
  - `boot.supportedFilesystems` — top-level option (currently only `boot.initrd.supportedFilesystems` exists)
  - `boot.zfs.extraPools` — list of ZFS pools to import at boot (Stage 2)
  - `boot.zfs.forceImportAll` — force import all pools
  - `boot.zfs.devNodes` — device node path for pool import
  - `services.zfs.trim.enable` — periodic ZFS trim timer
  - `services.zfs.autoScrub.enable` — periodic scrub timer
- Initrd integration: add `"zfs"` as a recognized filesystem in `boot/initrd.nix` (currently only ext4/btrfs/xfs/vfat are handled)
- Requires `zfs` userspace package in corepkgs base set
- Register in `module-list.nix`

### 1.2 `networking.hostId`
**Status**: Missing
**Where**: `networking.nix`
**What's needed**: Add option `networking.hostId` (type `types.str`). Write to `/etc/hostid` via activation script. Required by ZFS for pool import safety.

### 1.3 `boot.extraModulePackages`
**Status**: Missing
**Where**: `boot/kernel.nix`
**What's needed**: Add `boot.extraModulePackages` (type `types.listOf types.package`, default `[]`). Merge into kernel module search path.

### 1.4 `boot.loader.systemd-boot.memtest86.enable`
**Status**: Missing
**Where**: `boot/systemd-boot.nix`
**What's needed**: Option to add memtest86+ entry to systemd-boot. Requires memtest86plus package.
**Priority**: Low — nice to have, not boot-critical.

---

## Tier 2 — Core System

### 2.1 OpenSSH Multi-Port Support
**Status**: Partial — `services.openssh.settings.ports` is `types.port` (single int)
**Where**: `services/networking/sshd.nix`
**What's needed**: Change `settings.ports` to `types.either types.port (types.listOf types.port)` or `types.listOf types.port`. Update `sshdConfig` generation to emit multiple `Port` lines. Update port contract to register all ports.

### 2.2 `services.openssh.authorizedKeysFiles`
**Status**: Missing
**Where**: `services/networking/sshd.nix`
**What's needed**: Add `settings.authorizedKeysFiles` option (type `types.listOf types.str`). Render as `AuthorizedKeysFile` directives in sshd_config.

### 2.3 `security.pam.loginLimits`
**Status**: Missing — `/etc/security/limits.conf` is hardcoded in `security/pam.nix`
**Where**: `security/pam.nix`
**What's needed**: Add `security.pam.loginLimits` option (type `types.listOf (types.submodule { domain, type, item, value })`). Generate `/etc/security/limits.conf` from the option instead of hardcoding.

### 2.4 `services.journald.extraConfig` / `maxRetentionSec` type
**Status**: Partial — `maxRetentionSec` is `types.int` (seconds only)
**Where**: `services/journald.nix`
**What's needed**:
- Change `maxRetentionSec` type to `types.nullOr types.str` to accept systemd time spans like `"3week"` (journald.conf natively supports this syntax)
- Verify `extraConfig` passthrough works (it does — `settings.extraConfig` exists as `types.lines`)

### 2.5 Nix Daemon Option Extensions
**Status**: Partial
**Where**: `config/nix-daemon.nix`
**What's needed**:
- `nix.package` — option (type `types.package`, default `pkgs.nix`) so modules can reference `config.nix.package`
- `nix.extraOptions` — option (type `types.lines`) for raw nix.conf lines appended after generated settings
- `nix.nixPath` — option (type `types.listOf types.str`) rendered as `nix-path` in nix.conf
- `nix.nrBuildUsers` — option (type `types.int`) controlling number of `nixbld` build users created
- `nix.gc.dates` — extend `nix.gc.schedule` to accept systemd calendar specs (not just "daily"/"weekly")

### 2.6 `hardware.cpu.amd.updateMicrocode` (and Intel equivalent)
**Status**: Missing
**Where**: New module `hardware/cpu.nix`
**What's needed**: Options `hardware.cpu.amd.updateMicrocode` and `hardware.cpu.intel.updateMicrocode` (type `bool`). When enabled, add microcode package to initrd or as early-load cpio archive prepended to initramfs.

### 2.7 NetworkManager
**Status**: Missing entirely
**Where**: New module `services/networking/networkmanager.nix`
**What's needed**:
- Service module with options: `networking.networkmanager.enable`, `networking.networkmanager.unmanaged`, `networking.networkmanager.wifi.*`, etc.
- NetworkManager package (may need to be in corepkgs or ekapkgs depending on scope)
- Integration with firewall and DNS (resolved/dhcpcd)
- Service contract: command, args, systemd after/wantedBy
- D-Bus integration (NM uses D-Bus extensively)

### 2.8 `environment.etc` source attribute
**Status**: Needs verification
**Where**: `system/etc.nix`
**What's needed**: Verify that `environment.etc.<name>.source` is supported (config uses `environment.etc."nix/inputs/nixpkgs".source = pkgs.path`). If only `.text` is supported, add `.source` support.

### 2.9 User Shell as Package
**Status**: `users.users.<name>.shell` is `types.str`
**Where**: `config/users-groups.nix`
**What's needed**: Either:
- Change to `types.either types.str types.package` and resolve packages to `"${pkg}/bin/${name}"`, or
- Change to `types.either types.str types.path` and document that users should pass paths
- The NixOS convention is to accept packages (e.g., `pkgs.zsh`)

---

## Tier 3 — Infrastructure Services

### 3.1 Nginx Service Module
**Status**: Missing (corepkgs has `services.reverseProxy` but not full nginx)
**Where**: New module `services/networking/nginx.nix`
**What's needed**: Full nginx service module:
- `services.nginx.enable`
- `services.nginx.package`
- `services.nginx.virtualHosts.<name>` with locations, proxyPass, root, index
- `services.nginx.recommendedGzipSettings`, `recommendedOptimisation`, `recommendedProxySettings`, `recommendedTlsSettings`
- `services.nginx.commonHttpConfig`
- ACME integration: `virtualHosts.<name>.enableACME`, `forceSSL`, `serverAliases`
- Port contracts for HTTP/HTTPS
- **This is a large module** — consider whether it belongs in corepkgs or ekapkgs. Given nginx is fundamental infrastructure, corepkgs is appropriate.

### 3.2 Prometheus Service Module
**Status**: Only scrape-target helpers exist (`monitoring/prometheus-scrape.nix`)
**Where**: New module `services/monitoring/prometheus.nix`
**What's needed**:
- `services.prometheus.enable`
- `services.prometheus.exporters.node.enable` — runs node exporter as a service
- Prometheus server is less fundamental — could be ekapkgs
- Node exporter should be corepkgs (basic system monitoring)

### 3.3 Earlyoom as Service
**Status**: ekapkgs has `programs.earlyoom` (package only, no service)
**Where**: Could be corepkgs (`services/earlyoom.nix`) since OOM prevention is system-level
**What's needed**: Service contract with `command`, `args` built from `freeMemThreshold`/`freeSwapThreshold`, `restartPolicy = "always"`.

### 3.4 Service Stubs for Disabled-but-Referenced Services
**Status**: Missing
**What's needed**: Option declarations (stubs) for services that are `enable = false` but whose options are referenced elsewhere:
- `services.hydra` — at minimum: `enable`, `port`, `hydraURL`, `notificationSender`, `buildMachinesFiles`, `useSubstitutes`, `package`
- `services.grafana` — at minimum: `enable`, `settings.server.http_addr`, `settings.server.http_port`, `settings."auth.anonymous".enabled`
- `services.nix-serve` — at minimum: `enable`, `secretKeyFile`
- These can be minimal stubs. Whether they go in corepkgs or ekapkgs depends on whether they're considered infrastructure (likely ekapkgs).

### 3.5 `queued-build-hook`
**Status**: Missing entirely
**Where**: Could be corepkgs (build infrastructure) or ekapkgs
**What's needed**: Package + module providing `queued-build-hook.enable`, `postBuildScriptContent`, `credentials`. Wires as nix post-build-hook with async queue daemon.

---

## Summary: What Should Be Upstream in Corepkgs

**Definitely corepkgs** (fundamental system concerns):
- 1.1 ZFS boot support
- 1.2 `networking.hostId`
- 1.3 `boot.extraModulePackages`
- 2.1 OpenSSH multi-port
- 2.2 OpenSSH authorizedKeysFiles
- 2.3 PAM loginLimits
- 2.4 journald maxRetentionSec type fix
- 2.5 Nix daemon option extensions
- 2.6 CPU microcode module
- 2.9 User shell as package type
- 3.3 Earlyoom service

**Probably corepkgs** (infrastructure that most servers need):
- 2.7 NetworkManager
- 3.1 Nginx service module

**Could be either** (depends on project scope philosophy):
- 2.8 `environment.etc.source` (if missing)
- 3.2 Prometheus
- 3.4 Service stubs
- 3.5 queued-build-hook
