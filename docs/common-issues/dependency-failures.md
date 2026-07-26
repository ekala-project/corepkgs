# Dependency Failures

## Transitive dependency failure

### Symptom

```
error: Build failed due to failed dependency

these N derivations will be built:
  /nix/store/...-some-other-package.drv
```

The package you're updating builds fine on its own, but one of its dependencies (or a dependency's dependency) fails to build.

### Diagnosis

The key indicator is that the error message references a **different package** than the one being updated. The failing derivation path will show the actual broken package.

### Fix

This is **not fixable** by editing the updated package's Nix file. You must:

1. Identify which dependency is actually broken from the `.drv` path in the error
2. Fix that dependency first
3. Retry the original update

### Common causes

- A shared dependency (e.g., a Python build tool) was recently updated and broke
- The new version of the package added a dependency that doesn't build in core-pkgs
- A circular dependency was introduced

### What NOT to do

- Don't add `--impure` flags or skip sandbox checks
- Don't remove the dependency from `buildInputs` — it's needed
- Don't try to patch the dependent package from within the current package's derivation
