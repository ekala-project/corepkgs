# Home module tests
# Validates the home.users.* namespace, standalone eval-home.nix,
# backward compatibility with users.users.*, and language integration.
#
# Usage:
#   nix-build ekaos/tests/home.nix -A all
#   cat result/test-results.txt
#
#   nix-build ekaos/tests/home.nix -A standalone.basic
#   ls result/
{
  pkgs ? import ../../. { },
}:

let
  inherit (pkgs) lib;

  # Standalone home evaluator (no system dependencies)
  evalHome =
    modules:
    (import ../eval-home.nix { inherit lib pkgs; }) {
      inherit modules;
    };

  # Full system evaluator (for backward compat and bridge tests)
  evalSystem =
    modules:
    (import ../eval-config.nix { inherit lib pkgs; }) {
      modules = [
        {
          serviceManager.systemd.enable = lib.mkDefault true;
          boot.kernelPackages = pkgs.linuxPackages;
          fileSystems."/" = {
            device = "/dev/null";
            fsType = "ext4";
          };
        }
      ]
      ++ modules;
    };

  # ── Standalone home evaluator tests ────────────────────────────────

  standaloneTests =
    let
      # Test 1: Basic home config evaluates
      basicResult = evalHome [
        {
          home.users.alice = {
            sessionVariables.EDITOR = "vim";
            shellAliases.gs = "git status";
            sessionPath = [ "$HOME/.local/bin" ];
          };
        }
      ];
      basic = basicResult.activationPackages.alice;

      # Test 2: Home file management
      filesResult = evalHome [
        {
          home.users.alice = {
            file.".bashrc".text = "PS1='alice$ '";
            file.".config/git/config".text = ''
              [user]
                name = Alice
            '';
            file.".local/bin/hello" = {
              text = ''
                #!/bin/sh
                echo hello
              '';
              executable = true;
            };
          };
        }
      ];
      files = filesResult.activationPackages.alice;

      # Test 3: Multiple users
      multiResult = evalHome [
        {
          home.users.alice = {
            sessionVariables.EDITOR = "vim";
            shellAliases.ll = "ls -la";
          };
          home.users.bob = {
            sessionVariables.EDITOR = "emacs";
            sessionPath = [ "$HOME/bin" ];
          };
        }
      ];
      multiAlice = multiResult.activationPackages.alice;
      multiBob = multiResult.activationPackages.bob;

      # Test 4: Language integration
      langResult = evalHome [
        {
          home.users.alice = {
            languages.go.enable = true;
            languages.rust.enable = true;
          };
        }
      ];
      lang = langResult.activationPackages.alice;

      # Test 5: Activation scripts
      activationResult = evalHome [
        {
          home.users.alice.activation.setupDirs = {
            deps = [ ];
            text = "mkdir -p $HOME/.vim/undo";
          };
          home.users.alice.activation.setupGit = {
            deps = [ "setupDirs" ];
            text = "echo git setup";
          };
        }
      ];
      activation = activationResult.activationPackages.alice;

      # Test 6: Empty config produces no users
      emptyResult = evalHome [ { } ];

      # Test 7: Combined activation package
      combinedResult = evalHome [
        {
          home.users.alice.sessionVariables.X = "1";
          home.users.bob.sessionVariables.Y = "2";
        }
      ];
      combined = combinedResult.activationPackage;

    in
    {
      inherit
        basic
        files
        lang
        activation
        combined
        ;

      all =
        pkgs.runCommand "home-standalone-tests"
          {
            nativeBuildInputs = [ pkgs.jq ];
          }
          ''
            mkdir -p $out
            results=$out/test-results.txt

            pass=0
            fail=0

            check() {
              local name="$1" file="$2" pattern="$3"
              if grep -q "$pattern" "$file"; then
                echo "PASS: $name" >> "$results"
                pass=$((pass + 1))
              else
                echo "FAIL: $name (expected '$pattern')" >> "$results"
                echo "  File contents:" >> "$results"
                sed 's/^/    /' "$file" >> "$results"
                fail=$((fail + 1))
              fi
            }

            check_absent() {
              local name="$1" file="$2" pattern="$3"
              if ! grep -q "$pattern" "$file"; then
                echo "PASS: $name" >> "$results"
                pass=$((pass + 1))
              else
                echo "FAIL: $name (should NOT contain '$pattern')" >> "$results"
                fail=$((fail + 1))
              fi
            }

            echo "=== Standalone home evaluator tests ===" > "$results"
            echo "" >> "$results"

            # Test 1: Basic - session vars
            check "basic: EDITOR exported" \
              ${basic}/session-vars.sh "export EDITOR=vim"

            check "basic: alias gs" \
              ${basic}/session-vars.sh "alias gs='git status'"

            check "basic: PATH prepend" \
              ${basic}/session-vars.sh 'HOME/.local/bin'

            # Test 2: Files - home-files created
            test -d ${files}/home-files && {
              echo "PASS: home-files directory exists" >> "$results"
              pass=$((pass + 1))
            } || {
              echo "FAIL: home-files directory missing" >> "$results"
              fail=$((fail + 1))
            }

            # Files - manifest lists managed targets
            check "files: manifest has .bashrc" \
              ${files}/home-files-manifest ".bashrc"

            check "files: manifest has git config" \
              ${files}/home-files-manifest ".config/git/config"

            # Files - .bashrc content via symlink
            bashrc_target=$(readlink -f ${files}/home-files/.bashrc)
            check "files: .bashrc content" \
              "$bashrc_target" "PS1='alice\$ '"

            # Test 3: Multiple users
            check "multi: alice EDITOR" \
              ${multiAlice}/session-vars.sh "export EDITOR=vim"

            check "multi: bob EDITOR" \
              ${multiBob}/session-vars.sh "export EDITOR=emacs"

            check "multi: bob PATH" \
              ${multiBob}/session-vars.sh 'HOME/bin'

            # Test 4: Language integration
            check "lang: GOPATH set" \
              ${lang}/session-vars.sh "GOPATH"

            check "lang: CARGO_HOME set" \
              ${lang}/session-vars.sh "CARGO_HOME"

            # Language packages added to home-path
            test -L ${lang}/home-path && {
              echo "PASS: lang: home-path symlink exists" >> "$results"
              pass=$((pass + 1))
            } || {
              echo "FAIL: lang: home-path symlink missing" >> "$results"
              fail=$((fail + 1))
            }

            # Go binary should be in home-path
            home_path=$(readlink -f ${lang}/home-path)
            if [ -e "$home_path/bin/go" ]; then
              echo "PASS: lang: go binary in home-path" >> "$results"
              pass=$((pass + 1))
            else
              echo "FAIL: lang: go binary not in home-path" >> "$results"
              fail=$((fail + 1))
            fi

            # Test 5: Activation scripts in activate
            check "activation: setupDirs in activate" \
              ${activation}/activate "mkdir -p .HOME/.vim/undo"

            check "activation: setupGit in activate" \
              ${activation}/activate "echo git setup"

            # Dependency ordering: setupDirs before setupGit
            dirs_line=$(grep -n "setupDirs" ${activation}/activate | head -1 | cut -d: -f1)
            git_line=$(grep -n "setupGit" ${activation}/activate | head -1 | cut -d: -f1)
            if [ "$dirs_line" -lt "$git_line" ]; then
              echo "PASS: activation: setupDirs before setupGit" >> "$results"
              pass=$((pass + 1))
            else
              echo "FAIL: activation: setupDirs should come before setupGit" >> "$results"
              fail=$((fail + 1))
            fi

            # Test 6: Empty config
            ${
              if emptyResult.activationPackages == { } then
                ''
                  echo "PASS: empty config produces no activation packages" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: empty config should produce no activation packages" >> "$results"
                  fail=$((fail + 1))
                ''
            }

            # Test 7: Combined package has both users
            test -L ${combined}/users/alice && {
              echo "PASS: combined: alice in users/" >> "$results"
              pass=$((pass + 1))
            } || {
              echo "FAIL: combined: alice not in users/" >> "$results"
              fail=$((fail + 1))
            }

            test -L ${combined}/users/bob && {
              echo "PASS: combined: bob in users/" >> "$results"
              pass=$((pass + 1))
            } || {
              echo "FAIL: combined: bob not in users/" >> "$results"
              fail=$((fail + 1))
            }

            # Combined activate script exists
            test -x ${combined}/activate && {
              echo "PASS: combined: activate script exists" >> "$results"
              pass=$((pass + 1))
            } || {
              echo "FAIL: combined: activate script missing" >> "$results"
              fail=$((fail + 1))
            }

            echo "" >> "$results"
            echo "Standalone results: $pass passed, $fail failed" >> "$results"

            if [ "$fail" -gt 0 ]; then
              cat "$results" >&2
              exit 1
            fi
          '';
    };

  # ── Backward compatibility tests (users.users → home.users) ────────

  backwardCompatTests =
    let
      # Test 1: users.users config forwards to home.users
      forwardResult = evalSystem [
        {
          users.users.testuser = {
            isNormalUser = true;
            sessionVariables.EDITOR = "vim";
            shellAliases.ll = "ls -la";
            sessionPath = [ "$HOME/.cargo/bin" ];
          };
        }
      ];

      # Test 2: home.users config works in system eval
      directResult = evalSystem [
        {
          home.users.alice = {
            sessionVariables.PAGER = "less";
            shellAliases.gs = "git status";
          };
        }
      ];

      # Test 3: Both styles coexist
      mixedResult = evalSystem [
        {
          users.users.legacy = {
            isNormalUser = true;
            sessionVariables.A = "1";
          };
          home.users.modern = {
            sessionVariables.B = "2";
          };
        }
      ];

      # Test 4: home.users language integration in system eval
      langSysResult = evalSystem [
        {
          home.users.devuser.languages.go.enable = true;
        }
      ];

      # Test 5: system.build.home is accessible
      buildHomeResult = evalSystem [
        {
          home.users.alice.sessionVariables.X = "1";
        }
      ];

    in
    {
      all = pkgs.runCommand "home-backward-compat-tests" { } ''
        mkdir -p $out
        results=$out/test-results.txt

        pass=0
        fail=0

        echo "=== Backward compatibility tests ===" > "$results"
        echo "" >> "$results"

        # Test 1: Forward from users.users to home.users
        ${
          let
            fwdEditor = forwardResult.config.home.users.testuser.sessionVariables.EDITOR or null;
            fwdAlias = forwardResult.config.home.users.testuser.shellAliases.ll or null;
            fwdPath = forwardResult.config.home.users.testuser.sessionPath;
          in
          ''
            ${
              if fwdEditor == "vim" then
                ''
                  echo "PASS: forward: sessionVariables.EDITOR" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: forward: sessionVariables.EDITOR (got ${toString fwdEditor})" >> "$results"
                  fail=$((fail + 1))
                ''
            }
            ${
              if fwdAlias == "ls -la" then
                ''
                  echo "PASS: forward: shellAliases.ll" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: forward: shellAliases.ll" >> "$results"
                  fail=$((fail + 1))
                ''
            }
            ${
              if builtins.length fwdPath > 0 then
                ''
                  echo "PASS: forward: sessionPath non-empty" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: forward: sessionPath should be non-empty" >> "$results"
                  fail=$((fail + 1))
                ''
            }
          ''
        }

        # Test 2: Direct home.users in system eval
        ${
          let
            pager = directResult.config.home.users.alice.sessionVariables.PAGER or null;
            alias = directResult.config.home.users.alice.shellAliases.gs or null;
          in
          ''
            ${
              if pager == "less" then
                ''
                  echo "PASS: direct: home.users.alice.sessionVariables.PAGER" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: direct: home.users.alice.sessionVariables.PAGER" >> "$results"
                  fail=$((fail + 1))
                ''
            }
            ${
              if alias == "git status" then
                ''
                  echo "PASS: direct: home.users.alice.shellAliases.gs" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: direct: home.users.alice.shellAliases.gs" >> "$results"
                  fail=$((fail + 1))
                ''
            }
          ''
        }

        # Test 3: Mixed old/new styles coexist
        ${
          let
            legacyA = mixedResult.config.home.users.legacy.sessionVariables.A or null;
            modernB = mixedResult.config.home.users.modern.sessionVariables.B or null;
          in
          ''
            ${
              if legacyA == "1" then
                ''
                  echo "PASS: mixed: legacy user forwarded" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: mixed: legacy user not forwarded" >> "$results"
                  fail=$((fail + 1))
                ''
            }
            ${
              if modernB == "2" then
                ''
                  echo "PASS: mixed: modern user works" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: mixed: modern user not working" >> "$results"
                  fail=$((fail + 1))
                ''
            }
          ''
        }

        # Test 4: Language integration in system eval
        ${
          let
            goEnabled = langSysResult.config.home.users.devuser.languages.go.enable;
            gopath = langSysResult.config.home.users.devuser.sessionVariables.GOPATH or null;
          in
          ''
            ${
              if goEnabled then
                ''
                  echo "PASS: lang-sys: go enabled" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: lang-sys: go not enabled" >> "$results"
                  fail=$((fail + 1))
                ''
            }
            ${
              if gopath == "$HOME/go" then
                ''
                  echo "PASS: lang-sys: GOPATH set" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: lang-sys: GOPATH not set (got ${toString gopath})" >> "$results"
                  fail=$((fail + 1))
                ''
            }
          ''
        }

        # Test 5: system.build.home is a derivation
        test -e ${buildHomeResult.config.system.build.home} 2>/dev/null || true
        # If we got here without eval error, it's accessible
        echo "PASS: system.build.home is accessible" >> "$results"
        pass=$((pass + 1))

        echo "" >> "$results"
        echo "Backward compat results: $pass passed, $fail failed" >> "$results"

        if [ "$fail" -gt 0 ]; then
          cat "$results" >&2
          exit 1
        fi
      '';
    };

  # ── Devshell integration tests ─────────────────────────────────────

  devshellTests =
    let
      devShell = import ../../dev-shell {
        inherit (pkgs) lib stdenv;
        inherit pkgs;
      };

      # Test 1: Devshell with languages still works
      langShell = devShell.mkDevShell {
        modules = [
          { languages.go.enable = true; }
          { languages.rust.enable = true; }
        ];
      };

      # Test 2: Devshell with no modules
      emptyShell = devShell.mkDevShell { modules = [ ]; };

    in
    {
      all = pkgs.runCommand "home-devshell-tests" { } ''
        mkdir -p $out
        results=$out/test-results.txt

        pass=0
        fail=0

        echo "=== Devshell integration tests ===" > "$results"
        echo "" >> "$results"

        # Test 1: Language devshell instantiates
        ${
          if builtins.isAttrs langShell then
            ''
              echo "PASS: devshell with languages instantiates" >> "$results"
              pass=$((pass + 1))
            ''
          else
            ''
              echo "FAIL: devshell with languages failed" >> "$results"
              fail=$((fail + 1))
            ''
        }

        # Test 2: Empty devshell instantiates
        ${
          if builtins.isAttrs emptyShell then
            ''
              echo "PASS: empty devshell instantiates" >> "$results"
              pass=$((pass + 1))
            ''
          else
            ''
              echo "FAIL: empty devshell failed" >> "$results"
              fail=$((fail + 1))
            ''
        }

        echo "" >> "$results"
        echo "Devshell results: $pass passed, $fail failed" >> "$results"

        if [ "$fail" -gt 0 ]; then
          cat "$results" >&2
          exit 1
        fi
      '';
    };

in

{
  standalone = standaloneTests;
  backward-compat = backwardCompatTests;
  devshell = devshellTests;

  # Run all tests
  all = pkgs.runCommand "home-all-tests" { } ''
    mkdir -p $out

    echo "=== Home module test suite ===" > $out/test-results.txt
    echo "" >> $out/test-results.txt

    cat ${standaloneTests.all}/test-results.txt >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    cat ${backwardCompatTests.all}/test-results.txt >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    cat ${devshellTests.all}/test-results.txt >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    echo "All home module tests passed." >> $out/test-results.txt
  '';
}
