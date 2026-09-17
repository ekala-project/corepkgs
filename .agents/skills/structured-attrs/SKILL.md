---
name: structured-attrs
description: Migrate bash code from __structuredAttrs = false to __structuredAttrs = true. Use when porting shell hooks, builders, or setup scripts that assume derivation attributes are flat environment variables or space-separated strings.
---

# Migrating Bash to Structured Attrs

`__structuredAttrs = true` is the default in corepkgs. When enabled, Nix writes
derivation attributes to a JSON file (`$NIX_ATTRS_JSON_FILE`) instead of
exporting them as environment variables. Lists become **bash arrays**, not
space-separated strings. Only attributes in the `env` attrset are exported as
environment variables.

## Key Behavioral Changes

| Aspect | `__structuredAttrs = false` | `__structuredAttrs = true` |
|---|---|---|
| List attributes | space-separated string | bash indexed array |
| Attribute access | environment variable | in JSON file, NOT in env |
| `env` attrset | merged into top-level | exported as env vars |
| `outputs` | space-separated string | bash associative array |
| Booleans | `"1"` / `""` | bash has no booleans; same `"1"` / `""` via `toString` |

## Common Patterns and Fixes

### 1. Iterating Over List Attributes

List derivation attributes (e.g., `buildFlags`, `configureFlags`, custom lists)
become arrays. Bare `$var` word-splitting no longer works correctly.

```bash
# BROKEN: word-splits the first element or entire array as one token
for item in $myList; do ...

# FIXED: proper array expansion
for item in "${myList[@]}"; do ...
```

If the variable might be unset:

```bash
for item in ${myList+"${myList[@]}"}; do ...
```

### 2. Testing if a List is Empty

```bash
# BROKEN: tests the string representation of element 0
if [ -z "$myList" ]; then ...

# FIXED: check array length
if [ "${#myList[@]}" -eq 0 ]; then ...
```

### 3. Checking if a Variable is Set

```bash
# Works for both arrays and strings
if [ -z "${myVar+set}" ]; then
    echo "myVar is unset"
fi
```

### 4. Default Values for List Attributes

```bash
# BROKEN: ${var[*]:-default} flattens the array to a string, then reassigns
myList=${myList[*]:-a b c}

# FIXED: check and assign as array
if [ -z "${myList+set}" ]; then
    myList=(a b c)
fi
```

### 5. Passing Lists to Functions

When a function needs to receive a list, prefer passing the variable **name**
(for nameref) or flattening explicitly at the call site.

```bash
# Option A: pass as name, use nameref in function
caller() {
    processItems myArray
}
processItems() {
    local -n _items="$1"
    for item in "${_items[@]}"; do ...
}

# Option B: flatten at call site, word-split in function (legacy-compatible)
caller() {
    processItems "${myArray[*]}"
}
processItems() {
    local items="$1"
    for item in ${items}; do ...  # word-splitting intentional
}
```

Option B is preferred when the function also feeds into commands like `find` or
`xargs` that expect space-separated arguments, since it avoids changing the
function's internal logic.

### 6. substituteAll and Environment Variables

`substituteAll` replaces `@varName@` tokens using environment variables. With
structured attrs, only `env` attributes are in the environment. Top-level
derivation attributes are in the JSON file and invisible to `substituteAll`.

For `makeSetupHook`, substitutions are automatically placed in `env`. For
`mkDerivation`, place variables needed by `substituteAll` in the `env` attrset:

```nix
stdenv.mkDerivation {
  # ...
  env = {
    myVar = "value";          # visible to substituteAll
    myPath = "${./script}";   # path -> store path via interpolation
    myDrv = somePkg;          # derivation -> outPath
  };

  buildPhase = ''
    substituteAll $src $out/bin/script
  '';
};
```

**`_allFlags`** (used by `substituteAll`) only sees variables matching
`^[a-z][a-zA-Z0-9_]*$` plus the explicitly exported `system`, `pname`, `name`,
`version`.

### 7. Variables That Are NOT Affected

These are **not** derivation attributes and don't change with structured attrs:

- **Local variables**: `local foo="bar"` — always strings.
- **Variables from `read`**: `read -r line` — always strings.
- **Variables from files**: `source ./file` or `. ./file` — depends on file content.
- **PATH, PYTHONPATH, etc.**: Built up via `addToSearchPath`, always strings.
- **`$out`, `$dev`, etc.**: Output paths are exported as plain strings.
- **Hook lists**: `preConfigureHooks`, `fixupOutputHooks`, etc. — always arrays
  (they were arrays even before structured attrs).

### 8. The `outputs` Variable

```bash
# BROKEN: treats outputs as space-separated string
for o in $outputs; do ...

# FIXED: outputs is an associative array; iterate keys
for o in "${!outputs[@]}"; do ...

# Get all output names:
getAllOutputNames   # helper function, returns space-separated string
```

### 9. prependToVar / appendToVar

These helpers handle array variables. With structured attrs always on, they
always operate in array mode:

```bash
# Append a flag — works whether configureFlags is set or not
appendToVar configureFlags "--enable-foo"

# Prepend
prependToVar configureFlags "--prefix=$out"
```

### 10. concatTo

Use `concatTo` to accumulate multiple flag variables into a local array:

```bash
local -a flagsArray=()
concatTo flagsArray makeFlags makeFlagsArray buildFlags buildFlagsArray
someCommand "${flagsArray[@]}"
```

`concatTo` handles both arrays and strings, so it works regardless of how each
variable was declared.

## Nix-Side Considerations

### Coercing Values for `env`

The `env` attrset accepts strings, booleans, integers, and derivations. It does
**not** accept paths. Convert paths via string interpolation:

```nix
env = {
  script = "${./my-script.sh}";    # path -> store path (CORRECT)
  script = toString ./my-script.sh; # path -> source path (WRONG)
  myDrv = somePkg;                 # derivation: OK, tracked as dependency
  flag = true;                     # boolean: OK, becomes "1" / ""
  count = 42;                      # integer: OK, becomes "42"
};
```

### makeSetupHook Substitutions

`makeSetupHook` automatically places `substitutions` into `env`. Paths in
substitutions are interpolated to store paths. All other types use `toString`:

```nix
makeSetupHook {
  name = "my-hook";
  substitutions = {
    script = ./check.py;     # path: interpolated to /nix/store/...
    python = python3;        # derivation: toString gives outPath
    sitePackages = "lib/python3.13/site-packages";  # string: as-is
  };
} ./my-hook.sh
```

## Debugging Tips

1. **Check if a variable is an array or string:**
   ```bash
   declare -p myVar
   # declare -a myVar=(...) means indexed array
   # declare -A myVar=(...) means associative array
   # declare -- myVar="..." means plain string
   ```

2. **Print all environment variables visible to substituteAll:**
   ```bash
   awk 'BEGIN { for (v in ENVIRON) if (v ~ /^[a-z][a-zA-Z0-9_]*$/) print v, ENVIRON[v] }'
   ```

3. **Inspect the JSON attrs file:**
   ```bash
   cat "$NIX_ATTRS_JSON_FILE" | jq .
   ```

4. **Check if structured attrs is enabled:**
   ```bash
   if [ -n "$__structuredAttrs" ]; then
       echo "structured attrs enabled"
   fi
   ```

## Patterns to Avoid

- **Don't flatten arrays to strings prematurely.** Keep arrays as arrays for as
  long as possible. Only flatten (`${arr[*]}`) at the boundary where a command
  expects a space-separated string.

- **Don't use `$var` (unquoted) to iterate arrays.** This only works on strings.
  Use `"${var[@]}"` for arrays.

- **Don't put paths in `env` via `toString`.** Use string interpolation
  `"${path}"` to copy paths to the store.

- **Don't assume derivation attributes are in the environment.** Use `env` for
  variables that `substituteAll` or other tools need to see.
