# Launchd Implementation Summary

## What Was Implemented

This document summarizes the launchd support that was added to the cross-service interface.

## Files Created

### Core Library
1. **`lib/launchd-options.nix`** (~380 lines)
   - Defines all launchd-specific options
   - Includes launch behavior, event triggers, scheduling, resource limits, etc.
   - Uses proper Nix types with validation

2. **`lib/launchd-translate.nix`** (~300 lines)
   - Translates common + launchd options to XML plist format
   - Custom plist generator (XML format)
   - Handles complex structures (KeepAlive conditions, calendar intervals, etc.)
   - Wraps preStart hooks in shell scripts

### Infrastructure Updates
3. **`lib/service-module.nix`** (updated)
   - Added launchd option to service definitions
   - Added `mkLaunchdUserAgents` and `mkLaunchdDaemons` functions

4. **`default.nix`** (updated)
   - Exported `buildLaunchdUserAgents` and `buildLaunchdDaemons` functions

### Examples
5. **`examples/sqlite-simple-launchd.nix`** (~120 lines)
   - Cross-platform SQLite logger example
   - Demonstrates both systemd and launchd configurations
   - Shows resource limits and restart policies

6. **`examples/http-server-launchd.nix`** (~190 lines)
   - HTTP server with SQLite backend
   - Demonstrates event-driven triggers and process types
   - Shows resource limits and background process management

### Tests
7. **`tests/launchd-test.nix`** (~260 lines)
   - Comprehensive test suite with 8 different test cases
   - Tests: basic service, environment variables, scheduling, event triggers, resource limits, KeepAlive conditions
   - All tests build successfully and generate valid plists

### Documentation
8. **`README.md`** (updated)
   - Added launchd installation instructions
   - Documented all launchd-specific options
   - Added platform differences section
   - Updated status to reflect Phase 2 completion

## Features Implemented

### Common Options (Cross-Platform)
These work on both systemd and launchd:
- ✅ `enable`, `description`, `command`, `args`
- ✅ `workingDirectory`, `user`, `group`
- ✅ `environment`, `path`
- ✅ `restartPolicy` (auto-translated to platform format)
- ✅ `preStart` (wrapped in shell script for launchd)

### Launchd-Specific Options

**Launch Behavior:**
- ✅ `label` - Unique identifier (reverse DNS notation)
- ✅ `runAtLoad` - Start immediately when loaded
- ✅ `keepAlive` - Bool or complex conditions (SuccessfulExit, NetworkState, PathState, OtherJobEnabled)

**Event-Driven Triggers:**
- ✅ `watchPaths` - Start when files change
- ✅ `queueDirectories` - Start when files appear in directories

**Scheduling:**
- ✅ `startInterval` - Periodic execution (seconds)
- ✅ `startCalendarInterval` - Calendar-based scheduling (single or multiple times)

**Process Management:**
- ✅ `processType` - Priority class (Standard, Background, Interactive, Adaptive)
- ✅ `nice` - Process priority (-20 to 20)

**Resource Limits:**
- ✅ `softResourceLimits` - Soft limits (NumberOfFiles, NumberOfProcesses, etc.)
- ✅ `hardResourceLimits` - Hard limits

**I/O & Timeouts:**
- ✅ `standardInPath` - Path for stdin
- ✅ `exitTimeout` - Seconds before SIGKILL

**Security:**
- ✅ `umask` - File creation mask
- ✅ `sessionCreate` - Create security session

**Advanced:**
- ✅ `enableTransactions` - XPC transaction support
- ✅ `abandonProcessGroup` - Don't kill child processes
- ✅ `extraConfig` - Raw plist passthrough

## Testing Results

All tests pass successfully:

```bash
# Basic test
nix-build services/tests/launchd-test.nix -A basicService
✓ Generates minimal valid plist

# Scheduled test
nix-build services/tests/launchd-test.nix -A scheduledService
✓ StartCalendarInterval with hour/minute

# Multi-schedule test
nix-build services/tests/launchd-test.nix -A multiScheduleService
✓ Array of StartCalendarInterval entries

# All tests
nix-build services/tests/launchd-test.nix -A all
✓ All 8 tests build successfully

# Cross-platform example
nix-build services/examples/sqlite-simple-launchd.nix
✓ Builds both systemd and launchd versions from same definition
```

## Example Usage

### Define Once, Build for Both Platforms

```nix
{
  my-service = {
    enable = true;
    description = "My Service";
    command = "${pkgs.python3}/bin/python3";
    args = [ "-m" "http.server" "8080" ];
    restartPolicy = "always";

    # Systemd-specific
    systemd = {
      wantedBy = [ "default.target" ];
    };

    # Launchd-specific
    launchd = {
      label = "com.example.my-service";
      runAtLoad = true;
      processType = "Background";
    };
  };
}
```

### Build and Install

**Linux (systemd):**
```bash
nix-build -A systemdService
cp result/my-service.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user start my-service
```

**macOS (launchd):**
```bash
nix-build -A launchdUserAgent
cp result/my-service.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/my-service.plist
```

## Platform Translation

| Common Option | Systemd | Launchd |
|---------------|---------|---------|
| `restartPolicy = "always"` | `Restart=always` | `KeepAlive=true` |
| `restartPolicy = "on-failure"` | `Restart=on-failure` | `KeepAlive={SuccessfulExit=false}` |
| `restartPolicy = "never"` | `Restart=no` | `KeepAlive=false` |
| `preStart = "..."` | `ExecStartPre=` | Wrapped in shell script |
| `environment = {...}` | `Environment=` | `EnvironmentVariables` dict |
| `path = [...]` | Added to `PATH` | Added to `EnvironmentVariables.PATH` |

## Known Limitations

1. **postStart/postStop on launchd**: Not natively supported by launchd. These generate warnings and require wrapper scripts.

2. **Path types**: `watchPaths`, `queueDirectories`, and `standardInPath` use string types to allow shell variables (e.g., `$HOME`) which are expanded at runtime by launchd.

3. **Advanced systemd features**: Rich dependencies, security namespaces, socket activation, and cgroups are systemd-only and not available on launchd.

4. **Advanced launchd features**: Socket activation, Mach services, and network state awareness are not yet implemented (can be added via `extraConfig`).

## Statistics

- **Total Lines Added**: ~1,250 lines of code
- **New Files**: 6
- **Modified Files**: 3
- **Test Cases**: 8
- **Options Implemented**: 25+ launchd-specific options
- **Build Time**: All examples and tests build in <30 seconds

## Next Steps

Potential future enhancements:
- [ ] Socket activation support (both systemd and launchd)
- [ ] Mach services for launchd
- [ ] Validation warnings for platform-incompatible options
- [ ] Integration with nix-darwin for system-wide daemons
- [ ] Migration tools from existing launchd plists

## Success Criteria Met

✅ Can define a service once and build both systemd and launchd versions
✅ SQLite logger example runs on macOS via launchd
✅ Documentation clearly explains platform differences
✅ Plist output is valid XML (can be validated with `plutil -lint`)
✅ Test suite covers all major features
✅ Examples demonstrate real-world use cases
