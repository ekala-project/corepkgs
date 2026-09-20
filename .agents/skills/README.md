# Skills Directory

Detailed guides for AI agents working with core-pkgs. Each skill is a
directory containing a `SKILL.md` whose front matter declares when to load it.

## Available Skills

- **[cmake](cmake/SKILL.md)** - CMake build system
- **[go](go/SKILL.md)** - Go modules (`buildGoModule`)
- **[meson](meson/SKILL.md)** - Meson build system
- **[mk-many-variants](mk-many-variants/SKILL.md)** - Multi-version packages in `pkgs-many`
- **[packaging](packaging/SKILL.md)** - Packaging conventions and package organization
- **[porting](porting/SKILL.md)** - Porting from nixpkgs
- **[python](python/SKILL.md)** - Python packages (`buildPythonPackage`)
- **[rust](rust/SKILL.md)** - Rust crates (`buildRustPackage`)
- **[structured-attrs](structured-attrs/SKILL.md)** - Migrating bash to `__structuredAttrs = true`
- **[validation](validation/SKILL.md)** - Validation procedures

## Usage

Read a skill when its front matter `description` matches the task at hand.
