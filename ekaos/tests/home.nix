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

      # Test 8: User units are enabled through [Install] links
      unitText = install: ''
        [Service]
        ExecStart=/bin/true

        [Install]
        ${install}
      '';
      unitsResult = evalHome [
        {
          home.users.alice.file = {
            ".config/systemd/user/wanted.service".text = unitText "WantedBy=default.target";
            ".config/systemd/user/multi.service".text = unitText ''
              WantedBy=a.target b.target
                WantedBy = c.target
            '';
            ".config/systemd/user/reset.service".text = unitText ''
              WantedBy=dropped.target
              WantedBy=
              WantedBy=kept.target
            '';
            ".config/systemd/user/required.service".text = unitText ''
              RequiredBy=req.target
              UpheldBy=up.target
            '';
            ".config/systemd/user/inst@.service".text = unitText ''
              WantedBy=default.target
              DefaultInstance=main
            '';
            ".config/systemd/user/noinst@.service".text = unitText "WantedBy=default.target";
            ".config/systemd/user/plain.service".text = "[Service]\nExecStart=/bin/true\n";
          };
        }
      ];
      units = unitsResult.activationPackages.alice;

      # Test 9: A unit directory linked as a whole still builds
      unitDirResult = evalHome [
        {
          home.users.alice.file.".config/systemd/user".source = pkgs.writeTextDir "wanted.service" (
            unitText "WantedBy=default.target"
          );
        }
      ];
      unitDir = unitDirResult.activationPackages.alice;

    in
    {
      inherit
        basic
        files
        lang
        activation
        combined
        units
        unitDir
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

            # Test 8: User unit [Install] links
            unitdir=${units}/home-files/.config/systemd/user
            check_link() {
              local name="$1" path="$2"
              if [ -L "$unitdir/$path" ] && [ -f "$unitdir/$path" ]; then
                echo "PASS: $name" >> "$results"
                pass=$((pass + 1))
              else
                echo "FAIL: $name ($path missing)" >> "$results"
                fail=$((fail + 1))
              fi
            }
            check_no_link() {
              local name="$1" path="$2"
              if [ ! -e "$unitdir/$path" ] && [ ! -L "$unitdir/$path" ]; then
                echo "PASS: $name" >> "$results"
                pass=$((pass + 1))
              else
                echo "FAIL: $name ($path should not exist)" >> "$results"
                fail=$((fail + 1))
              fi
            }

            check_link "units: WantedBy" default.target.wants/wanted.service
            check_link "units: several targets on one line (1)" a.target.wants/multi.service
            check_link "units: several targets on one line (2)" b.target.wants/multi.service
            check_link "units: indented WantedBy" c.target.wants/multi.service
            check_no_link "units: empty WantedBy= resets" dropped.target.wants/reset.service
            check_link "units: target after reset" kept.target.wants/reset.service
            check_link "units: RequiredBy" req.target.requires/required.service
            check_link "units: UpheldBy" up.target.upholds/required.service
            check_link "units: template uses DefaultInstance" default.target.wants/inst@main.service
            check_no_link "units: template not linked as-is" default.target.wants/inst@.service
            check_no_link "units: template without DefaultInstance" default.target.wants/noinst@.service
            check_no_link "units: no [Install] section" default.target.wants/plain.service

            check "units: manifest has wants link" \
              ${units}/home-files-manifest ".config/systemd/user/default.target.wants/wanted.service"
            check "units: manifest has requires link" \
              ${units}/home-files-manifest ".config/systemd/user/req.target.requires/required.service"

            # Test 9: Unit directory linked as a whole
            check "unitDir: manifest has the directory link" \
              ${unitDir}/home-files-manifest '".config/systemd/user"'

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

  # ── Per-user program module tests ───────────────────────────────────

  programTests =
    let
      # Evaluate all programs in standalone home context
      progResult = evalHome [
        {
          home.users.alice = {
            programs.bash = {
              enable = true;
              initExtra = "eval \"$(direnv hook bash)\"";
              historySize = 50000;
              historyControl = [
                "ignoredups"
                "erasedups"
              ];
              shellOptions = [
                "histappend"
                "globstar"
                "cdspell"
              ];
              profileExtra = "export GPG_TTY=$(tty)";
            };
            programs.git = {
              enable = true;
              settings = {
                user.name = "Alice";
                user.email = "alice@example.com";
                init.defaultBranch = "main";
                pull.rebase = true;
              };
              signing = {
                key = "0xABCDEF";
                signByDefault = true;
              };
              aliases.st = "status";
              includes = [
                {
                  condition = "gitdir:~/work/";
                  path = "~/.config/git/work-config";
                }
              ];
              lfs.enable = true;
            };
            programs.ssh = {
              enable = true;
              forwardAgent = true;
              addKeysToAgent = "yes";
              serverAliveInterval = 60;
              matchBlocks.work = {
                hostname = "dev.example.com";
                user = "alice";
                identityFile = "~/.ssh/work_ed25519";
                forwardAgent = true;
              };
              matchBlocks."github.com" = {
                identityFile = "~/.ssh/github_ed25519";
              };
            };
            programs.gpg-agent = {
              enable = true;
              enableSshSupport = true;
              defaultCacheTtl = 3600;
              maxCacheTtl = 7200;
            };
          };
        }
      ];
      u = progResult.config.home.users.alice;
      bashrc = u.file.".bashrc".text;
      bashProfile = u.file.".bash_profile".text;
      gitconfig = u.file.".config/git/config".text;
      sshconfig = u.file.".ssh/config".text;
      gpgconf = u.file.".gnupg/gpg-agent.conf".text;

      # Test disabled programs produce no files
      disabledResult = evalHome [
        {
          home.users.bob = {
            programs.bash.enable = false;
            programs.git.enable = false;
            programs.ssh.enable = false;
            programs.gpg-agent.enable = false;
            sessionVariables.X = "1"; # give bob something so he exists
          };
        }
      ];
      bobFiles = disabledResult.config.home.users.bob.file;

    in
    {
      all = pkgs.runCommand "home-program-tests" { } ''
        mkdir -p $out
        results=$out/test-results.txt

        pass=0
        fail=0

        check_contains() {
          local name="$1" text="$2" pattern="$3"
          if echo "$text" | grep -qF "$pattern"; then
            echo "PASS: $name" >> "$results"
            pass=$((pass + 1))
          else
            echo "FAIL: $name (expected '$pattern')" >> "$results"
            fail=$((fail + 1))
          fi
        }

        check_not_contains() {
          local name="$1" text="$2" pattern="$3"
          if ! echo "$text" | grep -qF "$pattern"; then
            echo "PASS: $name" >> "$results"
            pass=$((pass + 1))
          else
            echo "FAIL: $name (should NOT contain '$pattern')" >> "$results"
            fail=$((fail + 1))
          fi
        }

        echo "=== Per-user program module tests ===" > "$results"
        echo "" >> "$results"

        # ── Bash tests ──
        bashrc=${lib.escapeShellArg bashrc}
        bash_profile=${lib.escapeShellArg bashProfile}

        check_contains "bash: sources session-vars.sh" \
          "$bashrc" "session-vars.sh"

        check_contains "bash: HISTSIZE" \
          "$bashrc" "HISTSIZE=50000"

        check_contains "bash: HISTCONTROL erasedups" \
          "$bashrc" "HISTCONTROL=ignoredups:erasedups"

        check_contains "bash: shopt histappend" \
          "$bashrc" "shopt -s histappend"

        check_contains "bash: shopt cdspell" \
          "$bashrc" "shopt -s cdspell"

        check_contains "bash: initExtra" \
          "$bashrc" 'eval "$(direnv hook bash)"'

        check_contains "bash: profile sources bashrc" \
          "$bash_profile" ".bashrc"

        check_contains "bash: profileExtra" \
          "$bash_profile" 'export GPG_TTY=$(tty)'

        # ── Git tests ──
        gitconfig=${lib.escapeShellArg gitconfig}

        check_contains "git: user.name" \
          "$gitconfig" "name = Alice"

        check_contains "git: user.email" \
          "$gitconfig" "email = alice@example.com"

        check_contains "git: init.defaultBranch" \
          "$gitconfig" "defaultBranch = main"

        check_contains "git: signing key" \
          "$gitconfig" "signingkey = 0xABCDEF"

        check_contains "git: commit gpgsign" \
          "$gitconfig" "gpgsign = true"

        check_contains "git: alias" \
          "$gitconfig" "st = status"

        check_contains "git: lfs filter" \
          "$gitconfig" '[filter "lfs"]'

        check_contains "git: lfs clean" \
          "$gitconfig" "clean = git-lfs clean"

        check_contains "git: includeIf" \
          "$gitconfig" 'includeIf "gitdir:~/work/"'

        check_contains "git: include path" \
          "$gitconfig" "path = ~/.config/git/work-config"

        # ── SSH tests ──
        sshconfig=${lib.escapeShellArg sshconfig}

        check_contains "ssh: ForwardAgent" \
          "$sshconfig" "ForwardAgent yes"

        check_contains "ssh: AddKeysToAgent" \
          "$sshconfig" "AddKeysToAgent yes"

        check_contains "ssh: Host work" \
          "$sshconfig" "Host work"

        check_contains "ssh: HostName" \
          "$sshconfig" "HostName dev.example.com"

        check_contains "ssh: User alice" \
          "$sshconfig" "User alice"

        check_contains "ssh: IdentityFile work" \
          "$sshconfig" "IdentityFile ~/.ssh/work_ed25519"

        check_contains "ssh: Host github" \
          "$sshconfig" "Host github.com"

        check_contains "ssh: IdentityFile github" \
          "$sshconfig" "IdentityFile ~/.ssh/github_ed25519"

        # ── GPG agent tests ──
        gpgconf=${lib.escapeShellArg gpgconf}

        check_contains "gpg: enable-ssh-support" \
          "$gpgconf" "enable-ssh-support"

        check_contains "gpg: default-cache-ttl" \
          "$gpgconf" "default-cache-ttl 3600"

        check_contains "gpg: max-cache-ttl" \
          "$gpgconf" "max-cache-ttl 7200"

        # ── Disabled programs produce no files ──
        ${
          let
            hasBashrc = bobFiles ? ".bashrc";
            hasGitconfig = bobFiles ? ".config/git/config";
            hasSshconfig = bobFiles ? ".ssh/config";
            hasGpgconf = bobFiles ? ".gnupg/gpg-agent.conf";
          in
          ''
            ${
              if !hasBashrc then
                ''
                  echo "PASS: disabled: no .bashrc" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: disabled: .bashrc should not exist" >> "$results"
                  fail=$((fail + 1))
                ''
            }
            ${
              if !hasGitconfig then
                ''
                  echo "PASS: disabled: no .config/git/config" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: disabled: .config/git/config should not exist" >> "$results"
                  fail=$((fail + 1))
                ''
            }
            ${
              if !hasSshconfig then
                ''
                  echo "PASS: disabled: no .ssh/config" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: disabled: .ssh/config should not exist" >> "$results"
                  fail=$((fail + 1))
                ''
            }
            ${
              if !hasGpgconf then
                ''
                  echo "PASS: disabled: no .gnupg/gpg-agent.conf" >> "$results"
                  pass=$((pass + 1))
                ''
              else
                ''
                  echo "FAIL: disabled: .gnupg/gpg-agent.conf should not exist" >> "$results"
                  fail=$((fail + 1))
                ''
            }
          ''
        }

        echo "" >> "$results"
        echo "Program results: $pass passed, $fail failed" >> "$results"

        if [ "$fail" -gt 0 ]; then
          cat "$results" >&2
          exit 1
        fi
      '';
    };

  # ── Activation tests (run activate against a scratch $HOME) ────────

  activationTests =
    let
      dir = pkgs.writeTextDir "x" "store";

      gen1Module = {
        home.users.alice = {
          sessionVariables.EDITOR = "vim";
          file.".gitconfig".text = "gen1";
          file.".config/old/conf".text = "old";
          file.".config/dir".source = dir;
        };
      };

      gen2Module = {
        home.users.alice = {
          sessionVariables.EDITOR = "vim";
          file.".gitconfig".text = "gen2";
          file.".config/new/conf".text = "new";
          file.".config/dir".source = dir;
        };
      };

      mkGen = modules: (evalHome modules).activationPackages.alice;
      gen1 = mkGen [ gen1Module ];
      gen2 = mkGen [ gen2Module ];
      genFail = mkGen [
        gen2Module
        { home.users.alice.onReplacedFile = "fail"; }
      ];
      genSilent = mkGen [
        gen2Module
        { home.users.alice.onReplacedFile = "silent"; }
      ];
    in
    {
      inherit
        gen1
        gen2
        genFail
        genSilent
        ;

      all = pkgs.runCommand "home-activation-tests" { } ''
        mkdir -p $out
        results=$out/test-results.txt

        pass=0
        fail=0

        expect() {
          local name="$1"
          shift
          if "$@"; then
            echo "PASS: $name" >> "$results"
            pass=$((pass + 1))
          else
            echo "FAIL: $name" >> "$results"
            fail=$((fail + 1))
          fi
        }

        not() { ! "$@"; }
        absent() { [ ! -e "$1" ] && [ ! -L "$1" ]; }
        in_store() {
          case "$(readlink "$1")" in
            ${builtins.storeDir}/*) return 0 ;;
          esac
          return 1
        }

        # Start a scenario with an empty home directory
        fresh() {
          export HOME=$TMPDIR/$1
          mkdir -p "$HOME"
        }

        # Run a generation's activate script; output goes to $HOME.log
        run() {
          rc=0
          "$1/activate" > "$HOME.log" 2>&1 || rc=$?
        }

        # Replace a managed link with a file the user owns
        user_file() {
          rm "$HOME/$1"
          echo mine > "$HOME/$1"
        }

        echo "=== Activation tests ===" > "$results"
        echo "" >> "$results"

        # A second activation replaces the first
        fresh upgrade
        run ${gen1}
        expect "upgrade: first activation succeeds" test "$rc" = 0
        expect "upgrade: .gitconfig links into the store" in_store "$HOME/.gitconfig"
        expect "upgrade: session-vars.sh links into the store" \
          in_store "$HOME/.config/ekaos/session-vars.sh"
        expect "upgrade: .ekaos-profile links into the store" in_store "$HOME/.ekaos-profile"
        run ${gen2}
        expect "upgrade: second activation succeeds" test "$rc" = 0
        expect "upgrade: .gitconfig updated" grep -qx gen2 "$HOME/.gitconfig"
        expect "upgrade: new file linked" in_store "$HOME/.config/new/conf"
        expect "upgrade: dropped file removed" absent "$HOME/.config/old/conf"
        expect "upgrade: generation 2 recorded" test -L "$HOME/.config/ekaos/generations/2"
        expect "upgrade: no warnings" not grep -q WARNING "$HOME.log"

        # Read-only copies of the state files, left by older activations,
        # are replaced. Skipped as root, where nothing is read-only.
        if [ "$(id -u)" != 0 ]; then
          fresh legacy
          run ${gen1}
          state=$HOME/.config/ekaos
          rm "$state/session-vars.sh" "$state/home-files-manifest"
          install -m 0444 ${gen1}/session-vars.sh "$state/session-vars.sh"
          install -m 0444 ${gen1}/home-files-manifest "$state/home-files-manifest"
          run ${gen2}
          expect "legacy: activation over read-only copies succeeds" test "$rc" = 0
          expect "legacy: session-vars.sh now links into the store" \
            in_store "$state/session-vars.sh"
          expect "legacy: manifest is writable" test -w "$state/home-files-manifest"
          expect "legacy: manifest updated" \
            cmp -s ${gen2}/home-files-manifest "$state/home-files-manifest"
          expect "legacy: no warnings" not grep -q WARNING "$HOME.log"
        fi

        # Default (warn): replaced paths are kept and reported
        fresh warn
        run ${gen1}
        user_file .gitconfig
        rm "$HOME/.config/dir"
        mkdir "$HOME/.config/dir"
        echo mine > "$HOME/.config/dir/x"
        ln -sfn "$TMPDIR/elsewhere" "$HOME/.config/old/conf"
        run ${gen2}
        expect "warn: activation succeeds" test "$rc" = 0
        expect "warn: replaced file kept" grep -qx mine "$HOME/.gitconfig"
        expect "warn: replaced directory kept" grep -qx mine "$HOME/.config/dir/x"
        expect "warn: user symlink at a dropped path kept" \
          test "$(readlink "$HOME/.config/old/conf")" = "$TMPDIR/elsewhere"
        expect "warn: warns about .gitconfig" grep -q 'WARNING: ~/.gitconfig ' "$HOME.log"
        expect "warn: warns about .config/dir" grep -q 'WARNING: ~/.config/dir ' "$HOME.log"
        expect "warn: other files still linked" in_store "$HOME/.config/new/conf"
        expect "warn: no backup made" absent "$HOME/.gitconfig.ekaos-backup"
        expect "warn: generation 2 recorded" test -L "$HOME/.config/ekaos/generations/2"

        # fail: report replaced paths and change nothing
        fresh fail
        run ${gen1}
        user_file .gitconfig
        run ${genFail}
        expect "fail: activation fails" not test "$rc" = 0
        expect "fail: lists the replaced path" grep -q '~/.gitconfig' "$HOME.log"
        expect "fail: replaced file kept" grep -qx mine "$HOME/.gitconfig"
        expect "fail: nothing new linked" absent "$HOME/.config/new/conf"
        expect "fail: dropped file not removed yet" in_store "$HOME/.config/old/conf"
        expect "fail: no generation recorded" absent "$HOME/.config/ekaos/generations/2"

        # silent: replaced paths are kept without a message
        fresh silent
        run ${gen1}
        user_file .gitconfig
        run ${genSilent}
        expect "silent: activation succeeds" test "$rc" = 0
        expect "silent: replaced file kept" grep -qx mine "$HOME/.gitconfig"
        expect "silent: no warnings" not grep -q WARNING "$HOME.log"

        # Running activate through a symlink (e.g. ./result) still links
        # into the store, so the next activation can replace those links
        fresh symlink
        ln -s ${gen1} "$TMPDIR/result"
        run "$TMPDIR/result"
        expect "symlink: activation succeeds" test "$rc" = 0
        expect "symlink: session-vars.sh links into the store" \
          in_store "$HOME/.config/ekaos/session-vars.sh"
        expect "symlink: generation links into the store" \
          in_store "$HOME/.config/ekaos/generations/1"

        echo "" >> "$results"
        echo "Activation results: $pass passed, $fail failed" >> "$results"

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
  programs = programTests;
  activation = activationTests;
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

    cat ${programTests.all}/test-results.txt >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    cat ${activationTests.all}/test-results.txt >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    cat ${devshellTests.all}/test-results.txt >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    echo "All home module tests passed." >> $out/test-results.txt
  '';
}
