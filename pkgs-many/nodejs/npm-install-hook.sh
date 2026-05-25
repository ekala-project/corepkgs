#!/usr/bin/env bash

# npm install hook for buildNpmPackage
# This hook sets up the npm environment and handles dependency installation

npmInstallHook() {
    echo "Executing npmInstallHook"

    runHook preInstall

    if [ -z "${dontNpmInstall-}" ]; then
        local dest="$out/lib/node_modules/${pname}"

        # Check if this is a workspace-based monorepo
        if [ -n "${npmWorkspace-}" ]; then
            echo "Installing workspace-based monorepo"

            # Install workspace packages to node_modules
            _npmInstallWorkspacePackages

            # Install the main workspace package
            if [ -d "${npmWorkspace}" ]; then
                _npmInstallFromWorkspace "${npmWorkspace}"
            else
                echo "Warning: npmWorkspace '${npmWorkspace}' not found"
            fi
        else
            # Standard single-package installation
            echo "Installing to $dest"
            mkdir -p "$dest"

            # Copy package files
            cp -r . "$dest/"

            # Create bin directory
            mkdir -p "$out/bin"

            # Link binaries from package.json
            if [ -f package.json ]; then
                # Check for bin entries
                if grep -q '"bin"' package.json 2>/dev/null; then
                    cd "$dest"

                    # Try to link from node_modules/.bin first
                    if [ -d node_modules/.bin ]; then
                        for bin in node_modules/.bin/*; do
                            if [ -f "$bin" ]; then
                                local binName=$(basename "$bin")
                                ln -s "../lib/node_modules/${pname}/$bin" "$out/bin/$binName" 2>/dev/null || true
                            fi
                        done
                    fi
                fi
            fi
        fi
    fi

    runHook postInstall

    echo "npmInstallHook completed"
}

# Helper: Install workspace packages to node_modules
_npmInstallWorkspacePackages() {
    local workspacesDir="${npmWorkspacesDir:-packages}"

    if [ ! -d "$workspacesDir" ]; then
        return
    fi

    echo "Installing workspace packages from $workspacesDir"
    mkdir -p "$out/lib/node_modules"

    # Copy each workspace package using its own package.json name
    for pkg in "$workspacesDir"/*; do
        if [ -d "$pkg" ] && [ -f "$pkg/package.json" ]; then
            # Read the full package name from package.json (includes scope if present)
            local fullName=$(node -pe "
                try {
                    const pkg = JSON.parse(fs.readFileSync('$pkg/package.json'));
                    pkg.name || ''
                } catch(e) {
                    ''
                }
            " 2>/dev/null)

            if [ -z "$fullName" ]; then
                echo "Warning: Could not read package name from $pkg/package.json"
                continue
            fi

            # Check if package name has a scope (starts with @)
            if [[ "$fullName" == @*/* ]]; then
                # Extract scope and package name
                local scope="${fullName%%/*}"  # @mongosh
                local pkgName="${fullName#*/}"  # cli-repl

                echo "  Installing $fullName"
                mkdir -p "$out/lib/node_modules/$scope"
                cp -r "$pkg" "$out/lib/node_modules/$scope/$pkgName"
            else
                # No scope, install directly
                echo "  Installing $fullName"
                cp -r "$pkg" "$out/lib/node_modules/$fullName"
            fi
        fi
    done

    # Collect all workspace scopes to exclude when copying root node_modules
    local workspaceScopes=()
    for pkg in "$workspacesDir"/*; do
        if [ -f "$pkg/package.json" ]; then
            local fullName=$(node -pe "
                try {
                    const pkg = JSON.parse(fs.readFileSync('$pkg/package.json'));
                    if (pkg.name && pkg.name.startsWith('@')) {
                        pkg.name.split('/')[0]
                    } else {
                        ''
                    }
                } catch(e) {
                    ''
                }
            " 2>/dev/null)
            if [ -n "$fullName" ] && [[ ! " ${workspaceScopes[@]} " =~ " ${fullName} " ]]; then
                workspaceScopes+=("$fullName")
            fi
        fi
    done

    # Copy root node_modules (excluding workspace scopes to avoid conflicts)
    if [ -d node_modules ]; then
        for item in node_modules/*; do
            local itemName=$(basename "$item")

            # Skip if it's a workspace scope
            local skip=false
            for scope in "${workspaceScopes[@]}"; do
                if [ "$itemName" = "$scope" ]; then
                    skip=true
                    break
                fi
            done

            if [ "$skip" = false ]; then
                cp -r "$item" "$out/lib/node_modules/" 2>/dev/null || true
            fi
        done
    fi

    # Remove common dangling symlinks from workspaces
    find "$out/lib/node_modules" -xtype l -delete 2>/dev/null || true
}

# Helper: Install specific workspace package binaries
_npmInstallFromWorkspace() {
    local workspace="$1"

    if [ ! -f "$workspace/package.json" ]; then
        echo "Warning: No package.json found in workspace $workspace"
        return
    fi

    # Get the full package name (with scope if present)
    local pkgFullName=$(node -pe "
        try {
            const pkg = JSON.parse(fs.readFileSync('$workspace/package.json'));
            pkg.name || ''
        } catch(e) {
            ''
        }
    " 2>/dev/null)

    if [ -z "$pkgFullName" ]; then
        echo "Warning: Could not read package name from $workspace/package.json"
        return
    fi

    # Determine the installed path in node_modules
    local installedPath
    if [[ "$pkgFullName" == @*/* ]]; then
        # Scoped package: @scope/name
        installedPath="$out/lib/node_modules/$pkgFullName"
    else
        # Unscoped package
        installedPath="$out/lib/node_modules/$pkgFullName"
    fi

    if [ ! -d "$installedPath" ]; then
        echo "Warning: Package $pkgFullName not found at $installedPath"
        return
    fi

    # Read bin entries from package.json
    local binEntries=$(node -pe "
        try {
            const pkg = JSON.parse(fs.readFileSync('$workspace/package.json'));
            if (typeof pkg.bin === 'string') {
                console.log(pkg.name + ':' + pkg.bin);
            } else if (typeof pkg.bin === 'object') {
                Object.entries(pkg.bin).forEach(([name, path]) => console.log(name + ':' + path));
            }
        } catch(e) {}
    " 2>/dev/null)

    if [ -z "$binEntries" ]; then
        return
    fi

    mkdir -p "$out/bin"

    # Link each binary from the installed location
    echo "$binEntries" | while IFS=: read -r binName binPath; do
        local fullPath="$installedPath/$binPath"
        if [ -f "$fullPath" ]; then
            chmod +x "$fullPath"
            echo "  Linking binary: $binName -> $pkgFullName/$binPath"
            # Create relative symlink from $out/bin to the installed package in node_modules
            ln -sf "../lib/node_modules/$pkgFullName/$binPath" "$out/bin/$binName"
        else
            echo "Warning: Binary $binPath not found at $fullPath"
        fi
    done
}

if [ -z "${dontUseNpmInstall-}" ] && [ -z "${installPhase-}" ]; then
    echo "Using npmInstallHook"
    installPhase=npmInstallHook
fi
