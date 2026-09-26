# Adios port of ekaos/modules/system/toplevel.nix.
#
# Tree path: system/toplevel is parent.system.toplevel.
#
# Top-level system builder: creates the system closure derivation from
# explicitly wired inputs. The derivation builders close over pkgs in the
# top-level let (impl only sees { options, inputs }).
#
# Inputs (owning modules outside this batch marked verify):
# - inputs.kernel (parent.boot.kernel): boot.kernelParams,
#   boot.kernelPackages.kernel, system.boot.loader.kernelFile
# - inputs.initrd (parent.boot.initrd): boot.initrd.enable,
#   system.build.initrd
# - inputs.loader (parent.boot."systemd-boot"): boot.loader.systemd-boot
#   .enable/.sortKey, boot.loader.efi.type
# - inputs.stage2 (parent.boot."stage-2"): system.build.bootStage2
# - inputs.activation (parent.system.activation): buildActivationScript
# - inputs.etcBuild (parent.system.etc): buildEtc
# - inputs.manifest (parent.system.package-manifest): buildPackageManifest
# TODO(adios-cutover): AGGREGATION GAP (load-bearing). Legacy
# mkServiceManagerVariant used extendModules to re-evaluate the whole
# system with a different service manager; adios cannot re-fixpoint.
# system.build.{systemd,runit,launchd,rcd} are kept as option stubs with
# no value — selecting a service-manager variant has no adios equivalent
# yet. Default system build assumes the systemd variant (as legacy did
# via misc/defaults.nix).
# TODO(adios-cutover): priority lost (was mkForce): variant selection is
# dropped entirely (see above).
# TODO(adios-cutover): impl returns system.build.toplevel / system.path
# (this module's read-only outputs) and environment.systemPackages (merge
# of defaultPackages ++ packages); the tree must merge impl outputs back
# (NixOS module-merge semantics).
{ types, pkgs, ... }:

let
  # Build the system closure derivation from explicitly passed components.
  buildToplevel =
    {
      ekaosVersion,
      ekaosLabel,
      kernel,
      kernelFile,
      kernelParams,
      initrdEnable,
      efiType,
      systemdBootEnable,
      sortKey,
      bootStage2,
      activationScript,
      etc,
      systemPath,
      systemdPackage,
      packageManifest,
      initrd,
    }:
    let
      # Generate bootspec (boot.json) for the system
      bootspecJson = pkgs.writeText "bootspec.json" (
        builtins.toJSON (
          {
            "org.nixos.bootspec.v1" = {
              system = pkgs.stdenv.hostPlatform.system;
              kernel = "${kernel}/${kernelFile}";
              inherit kernelParams;
              init = "@init@"; # Will be substituted
              toplevel = "@toplevel@"; # Will be substituted
              label = ekaosLabel;
              version = ekaosVersion;
            }
            // (
              if initrdEnable then
                {
                  # Include initrd in bootspec when enabled
                  initrd = "@initrd@"; # Will be substituted
                }
              else
                { }
            );
          }
          // {
            "org.nixos.specialisation.v1" = { };
          }
          // (
            if systemdBootEnable then
              {
                "org.nixos.systemd-boot" = {
                  inherit sortKey;
                };
              }
            else
              { }
          )
        )
      );

      # Build the system closure
      systemBuilder = ''
        set -e
        mkdir -p $out

        # Copy and configure the init script (stage-2)
        cp ${bootStage2} $out/init
        chmod +x $out/init

        # Substitute system configuration path
        substituteInPlace $out/init \
          --subst-var-by systemConfig $out

        # Copy activation script
        cp ${activationScript} $out/activate
        chmod +x $out/activate

        # Substitute @out@ in activation script
        substituteInPlace $out/activate \
          --replace '@out@' "$out"

        # Create bin directory and switch-to-configuration wrapper
        mkdir -p $out/bin
        cat > $out/bin/switch-to-configuration <<'WRAPPER'
        #!${pkgs.runtimeShell}
        # Wrapper for ekaos activation (NixOS compatibility)
        set -e
        action="''${1:-switch}"
        exec $out/activate "$action"
        WRAPPER
        chmod +x $out/bin/switch-to-configuration

        # Substitute $out in switch-to-configuration
        substituteInPlace $out/bin/switch-to-configuration \
          --replace '$out' "$out"

        # Create symlinks to key components
        ln -s ${etc}/etc $out/etc
        ln -s ${systemPath} $out/sw
        ln -s ${systemdPackage} $out/systemd

        # Write version information
        echo -n "${ekaosVersion}" > $out/ekaos-version

        # Embed package manifest for SBOM generation
        cp ${packageManifest} $out/package-manifest.json
        echo -n "systemd ${toString systemdPackage.interfaceVersion}" > $out/init-interface-version
        echo -n "${pkgs.stdenv.hostPlatform.system}" > $out/system

        # Copy initrd if enabled
        ${
          if initrdEnable && initrd != null then
            ''
              cp ${initrd}/initrd $out/initrd
            ''
          else
            ""
        }

        # Build UKI if requested
        ${
          if builtins.elem "uki" efiType then
            ''
                    echo "Building Unified Kernel Image (UKI)..."

                    # Determine the EFI stub path
                    stubName="linux${pkgs.stdenv.hostPlatform.efiArch}.efi.stub"
                    stub="${systemdPackage}/lib/systemd/boot/efi/$stubName"

                    if [ ! -f "$stub" ]; then
                      echo "error: EFI stub not found at $stub" >&2
                      echo "hint: systemd must be built with withBootloader=true and withEfi=true" >&2
                      exit 1
                    fi

                    # Write kernel command line
                    echo -n "init=$out/init ${builtins.concatStringsSep " " kernelParams}" > cmdline.txt

                    # Write os-release for the UKI .osrel section
                    cat > uki-os-release.txt <<OSREL
              NAME=ekaos
              ID=ekaos
              VERSION=${ekaosVersion}
              VERSION_ID=${ekaosVersion}
              PRETTY_NAME=ekaos ${ekaosVersion} (${ekaosLabel})
              OSREL

                    # Calculate VMA offsets from the stub's existing sections
                    # Each new section must be placed at a non-overlapping, page-aligned VMA
                    highest_end=$(objdump -h "$stub" | awk '
                      /^[[:space:]]+[0-9]+/ {
                        vma = strtonum("0x" $4)
                        size = strtonum("0x" $3)
                        end = vma + size
                        if (end > max) max = end
                      }
                      END { printf "%d", max }
                    ')

                    align=4096

                    # .osrel section
                    vma_osrel=$(( (highest_end + align - 1) / align * align ))
                    osrel_size=$(stat -c%s uki-os-release.txt)

                    # .cmdline section
                    vma_cmdline=$(( (vma_osrel + osrel_size + align - 1) / align * align ))
                    cmdline_size=$(stat -c%s cmdline.txt)

                    # .linux section
                    vma_linux=$(( (vma_cmdline + cmdline_size + align - 1) / align * align ))
                    kernelFile="${kernel}/${kernelFile}"
                    linux_size=$(stat -c%s "$kernelFile")

                    ${
                      if initrdEnable then
                        ''
                          # .initrd section
                          vma_initrd=$(( (vma_linux + linux_size + align - 1) / align * align ))
                        ''
                      else
                        ""
                    }

                    objcopy \
                      --add-section .osrel=uki-os-release.txt --set-section-flags .osrel=readonly,data \
                      --change-section-vma .osrel=$vma_osrel \
                      --add-section .cmdline=cmdline.txt --set-section-flags .cmdline=readonly,data \
                      --change-section-vma .cmdline=$vma_cmdline \
                      --add-section .linux="$kernelFile" --set-section-flags .linux=readonly,data \
                      --change-section-vma .linux=$vma_linux \
                      ${
                        if initrdEnable then
                          ''
                            --add-section .initrd=$out/initrd --set-section-flags .initrd=readonly,data \
                            --change-section-vma .initrd=$vma_initrd \
                          ''
                        else
                          ""
                      } \
                      "$stub" \
                      $out/uki.efi

                    echo "UKI built: $out/uki.efi"
            ''
          else
            ""
        }

        # Generate bootspec (boot.json)
        ${
          let
            hasUki = builtins.elem "uki" efiType;
            baseArgs = ''
              --arg toplevel "$out" \
              --arg init "$out/init"
            '';
            initrdArgs =
              if initrdEnable then
                ''
                  --arg initrd "$out/initrd"
                ''
              else
                "";
            ukiArgs =
              if hasUki then
                ''
                  --arg uki "$out/uki.efi"
                ''
              else
                "";
            baseFilter = ''
              ."org.nixos.bootspec.v1".toplevel = $toplevel |
              ."org.nixos.bootspec.v1".init = $init
            '';
            initrdFilter =
              if initrdEnable then
                ''
                  | ."org.nixos.bootspec.v1".initrd = $initrd
                ''
              else
                "";
            ukiFilter =
              if hasUki then
                ''
                  | ."org.nixos.systemd-boot".uki = $uki
                ''
              else
                "";
          in
          ''
            ${pkgs.jq}/bin/jq \
              '${baseFilter}${initrdFilter}${ukiFilter}' \
              ${baseArgs} \
              ${initrdArgs} \
              ${ukiArgs} \
              < ${bootspecJson} > $out/boot.json
          ''
        }

        # Create extra dependencies file for GC roots
        mkdir -p $out/extra-dependencies
        ln -s ${kernel} $out/extra-dependencies/kernel
        ${
          if initrdEnable then
            ''
              ln -s ${initrd} $out/extra-dependencies/initrd
            ''
          else
            ""
        }
      '';
    in
    pkgs.stdenvNoCC.mkDerivation {
      name = "ekaos-system-${ekaosLabel}";
      preferLocalBuild = true;
      allowSubstitutes = false;

      buildCommand = systemBuilder;

      nativeBuildInputs =
        if builtins.elem "uki" efiType then
          [
            pkgs.binutils
            pkgs.gawk
          ]
        else
          [ ];

      # Pass through for use in scripts
      inherit (pkgs) jq;
      package = systemdPackage;
    };

  # Build system path from packages.
  mkSystemPath =
    { systemPackages, pathsToLink }:
    pkgs.buildEnv {
      name = "system-path";
      paths = systemPackages;
      inherit pathsToLink;
      ignoreCollisions = true;
    };
in

{
  options = {
    ekaos = {
      description = "Ekaos release identity.";
      options = {
        version = {
          type = types.string;
          default = "24.11";
          description = "The ekaos version string.";
        };

        label = {
          type = types.string;
          default = "ekaos";
          description = "Label for the system (shown in boot menu).";
        };
      };
    };

    stateVersion = {
      type = types.string;
      # Legacy: default = config.system.ekaos.version.
      defaultFunc = { inputs, options }: options.ekaos.version;
      description = ''
        The version of ekaos at the time of initial installation. This is
        used by modules to avoid breaking changes on existing deployments.
        Do not change this after installation.
      '';
    };

    systemd = {
      description = ''
        Top-level systemd options for backward compatibility.
        These are set by service-managers/systemd.nix when systemd is enabled.
      '';
      options = {
        package = {
          type = types.derivation;
          default = pkgs.systemd;
          description = "The systemd package to use.";
        };

        defaultTarget = {
          type = types.string;
          default = "multi-user.target";
          description = "The default systemd target to boot into.";
        };
      };
    };

    build = {
      description = "System build outputs.";
      options = {
        # Read-only output; value comes from impl.
        toplevel = {
          type = types.derivation;
          description = ''
            The complete system closure.

            This derivation contains everything needed to boot and run
            the system: init script, activation script, /etc, packages, etc.
          '';
        };

        nixosInstall = {
          type = types.derivation;
          default = pkgs.nixos-install;
          description = "The nixos-install tool for installing the system.";
        };

        nixosEnter = {
          type = types.derivation;
          default = pkgs.nixos-enter;
          description = "The nixos-enter tool for entering a NixOS chroot.";
        };

        # Read-only outputs; extendModules variants have no adios
        # equivalent (see header TODO), kept as option stubs.
        systemd = {
          type = types.derivation;
          description = ''
            Complete system closure with systemd service manager.

            This variant uses systemd for service management.
            Build with: nix-build -A config.system.build.systemd
          '';
        };

        runit = {
          type = types.derivation;
          description = ''
            Complete system closure with runit service manager.

            This variant uses runit for service management.
            Build with: nix-build -A config.system.build.runit
          '';
        };

        launchd = {
          type = types.derivation;
          description = ''
            Complete system closure with launchd service manager (stub).

            Note: This is a stub for architecture completeness.
            launchd is macOS-specific and cannot run as PID 1 on Linux.
          '';
        };

        rcd = {
          type = types.derivation;
          description = ''
            Complete system closure with BSD rc.d service manager (stub).

            Note: This is a stub for architecture completeness.
            rc.d requires BSD kernel and userland.
          '';
        };
      };
    };

    # Read-only output; value comes from impl.
    systemPath = {
      type = types.derivation;
      description = ''
        The system environment (/run/current-system/sw).

        Contains all packages that should be available system-wide.
      '';
    };

    extraDependencies = {
      type = types.listOf types.derivation;
      default = [ ];
      description = ''
        Extra build-time dependencies for the system.
        These packages will be referenced by the system derivation to ensure
        they're built and available at build time.
      '';
    };

    environment = {
      description = "System environment package sets.";
      options = {
        packages = {
          type = types.listOf types.derivation;
          default = [ ];
          description = ''
            Context-agnostic package list. In the system context these are
            forwarded to environment.systemPackages. Language modules and
            devshells write to this option instead of systemPackages directly.
          '';
        };

        systemPackages = {
          type = types.listOf types.derivation;
          default = [ ];
          example = "[ pkgs.vim pkgs.git ]";
          description = ''
            Packages to install in the system environment.
            The impl merges defaultPackages ++ packages into this output;
            the tree must merge impl outputs back.
          '';
        };

        defaultPackages = {
          type = types.listOf types.derivation;
          default = with pkgs; [
            coreutils
            util-linux
            systemd
            bash
            grep
            sed
            gawk
            findutils
            diffutils
            gnutar
            gzip
            xz
            zstd
            less
            procps-ng
            iproute2
            iputils
            netcat
            curl
            which
          ];
          description = ''
            Set of default packages for a functional system. These can be
            removed for a more minimal installation.
          '';
        };

        pathsToLink = {
          type = types.listOf types.string;
          default = [
            "/bin"
            "/sbin"
            "/lib"
            "/share"
            "/etc"
          ];
          description = "List of directories to be symlinked in /run/current-system/sw.";
        };
      };
    };
  };

  inputs = {
    kernel.from = { root }: root.boot.kernel;
    initrd.from = { root }: root.boot.initrd;
    loader.from = { root }: root.boot."systemd-boot";
    stage2.from = { root }: root.boot."stage-2";
    activation.from = { parent }: parent.activation;
    etcBuild.from = { parent }: parent.etc;
    manifest.from = { parent }: parent.package-manifest;
  };

  impl =
    { options, inputs }:
    let
      systemPackages = options.environment.defaultPackages ++ options.environment.packages;
      systemPath = mkSystemPath {
        inherit systemPackages;
        inherit (options.environment) pathsToLink;
      };
    in
    {
      # Default system build (uses systemd by default via misc/defaults.nix)
      system.build.toplevel = buildToplevel {
        ekaosVersion = options.ekaos.version;
        ekaosLabel = options.ekaos.label;
        kernel = inputs.kernel.kernelPackages.kernel;
        kernelFile = inputs.kernel.kernelFile;
        kernelParams = inputs.kernel.kernelParams;
        initrdEnable = inputs.initrd.enable;
        efiType = inputs.loader.efiType;
        systemdBootEnable = inputs.loader.enable or false;
        sortKey = inputs.loader.sortKey;
        bootStage2 = inputs.stage2.bootStage2;
        activationScript = inputs.activation.buildActivationScript;
        etc = inputs.etcBuild.buildEtc;
        inherit systemPath;
        systemdPackage = options.systemd.package;
        packageManifest = inputs.manifest.buildPackageManifest;
        initrd = inputs.initrd.initrd or null;
      };

      # Build system path from packages
      system.path = systemPath;

      # Include default packages and language module packages in system environment
      environment.systemPackages = systemPackages;
    };
}
