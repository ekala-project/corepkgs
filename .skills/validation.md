# Package Validation

All package changes must pass three validation steps:

## 1. Evaluation Check

Verify Nix expression evaluates correctly:

```bash
nix-instantiate -A <package-name>
```

**Expected:** `/nix/store/abc123...-package-1.0.0.drv`

**For non-derivations:**
```bash
nix-instantiate --eval -A <attribute>
```

## 2. Build Check

Verify package builds successfully:

```bash
nix-build -A <package-name>
```

**Expected:** `result` symlink to `/nix/store/xyz789...-package-1.0.0`

**Inspect results:**
```bash
ls -la result/
./result/bin/example --version
ldd result/lib/libexample.so
```

## 3. Format Check

Ensure code follows formatting standards:

```bash
nix fmt <path-to-file>
```

**Format all modified files:**
```bash
git diff --name-only '*.nix' | xargs -I {} nix fmt {}
```

## Checking Dependencies

**Verify dependencies exist before porting:**

```bash
# Single dependency
nix-instantiate -A zlib

# Multiple dependencies
for dep in acl lzo cmocka zlib zstd; do
  echo -n "$dep: "
  nix-instantiate -A $dep >/dev/null 2>&1 && echo "✓" || echo "✗"
done
```

**DO NOT** search `top-level.nix` with grep. Packages in `pkgs/` and `pkgs-many/` are auto-registered.

## Common Errors

### Evaluation Errors

**Missing dependency:**
```
error: attribute 'somelib' missing
```
Port the dependency or add TODO comment.

**Syntax error:**
```
error: syntax error, unexpected ')'
```
Fix the syntax in the Nix expression.

### Build Errors

**Missing build tool:**
```
error: Program 'pkg-config' not found
```
Add to `nativeBuildInputs`.

**Missing library:**
```
/nix/store/.../bin/ld: cannot find -lz
```
Add to `buildInputs`.

**Test failures:**
Tests are disabled by default. Investigate or keep disabled.

## Complete Validation Workflow

```bash
# Validate a package
PACKAGE="example"

# 1. Evaluate
nix-instantiate -A $PACKAGE

# 2. Build
nix-build -A $PACKAGE

# 3. Test result
./result/bin/$PACKAGE --version

# 4. Format
nix fmt pkgs/$PACKAGE/default.nix
```

## Validation Checklist

- [ ] `nix-instantiate -A <package>` succeeds
- [ ] `nix-build -A <package>` succeeds
- [ ] Built binary/library works
- [ ] All dependencies verified with `nix-instantiate`
- [ ] `nix fmt` run on all edited files
- [ ] `meta.maintainers = [ ]`
- [ ] TODO comments for missing dependencies

## Advanced Validation

**Check closure size:**
```bash
nix-store -q --tree $(nix-build -A example --no-out-link)
```

**Check runtime dependencies:**
```bash
nix-store -q --references $(nix-build -A example --no-out-link)
```

**Rebuild from scratch:**
```bash
nix-build -A example --rebuild
```

**Reproducibility check:**
```bash
nix-build -A example --check
```
