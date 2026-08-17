# User services test
# Validates that users.services.* generates correct service files
# for both systemd and runit service managers.
#
# Usage:
#   nix-build ekaos/tests/user-services.nix -A all
#   cat result/test-results.txt
#
#   nix-build ekaos/tests/user-services.nix -A systemd.basic
#   cat result
{
  pkgs ? import ../../. { },
}:

let
  inherit (pkgs) lib;

  evalEkaos =
    modules:
    (import ../eval-config.nix { inherit lib pkgs; }) {
      modules = [
        # Enable systemd by default for tests
        {
          serviceManager.systemd.enable = lib.mkDefault true;

          # Minimal system config to satisfy module requirements
          boot.kernelPackages = pkgs.linuxPackages;
          fileSystems."/" = {
            device = "/dev/null";
            fsType = "ext4";
          };
        }
      ]
      ++ modules;
    };

  # Helper: evaluate with a specific service manager
  evalWithSystemd =
    modules:
    evalEkaos (
      [
        { serviceManager.systemd.enable = true; }
      ]
      ++ modules
    );

  evalWithRunit =
    modules:
    evalEkaos (
      [
        {
          serviceManager.systemd.enable = lib.mkForce false;
          serviceManager.runit.enable = true;
        }
      ]
      ++ modules
    );

  # Get the /etc entries from an evaluation
  getEtc = eval: eval.config.environment.etc;

  # ── Systemd tests ──────────────────────────────────────────────────

  systemdTests =
    let
      # Test 1: Basic user service generates a unit file
      basicEval = evalWithSystemd [
        {
          users.services.test-daemon = {
            enable = true;
            description = "Test User Daemon";
            command = "${pkgs.coreutils}/bin/sleep";
            args = [ "infinity" ];
          };
        }
      ];
      basic = (getEtc basicEval)."systemd/user/test-daemon.service".source;

      # Test 2: User service defaults to default.target
      defaultTargetEval = evalWithSystemd [
        {
          users.services.target-check = {
            enable = true;
            command = "${pkgs.coreutils}/bin/true";
          };
        }
      ];
      defaultTarget = (getEtc defaultTargetEval)."systemd/user/target-check.service".source;

      # Test 3: Custom wantedBy overrides default
      customTargetEval = evalWithSystemd [
        {
          users.services.custom-target = {
            enable = true;
            command = "${pkgs.coreutils}/bin/true";
            systemd = {
              wantedBy = [ "graphical-session.target" ];
            };
          };
        }
      ];
      customTarget = (getEtc customTargetEval)."systemd/user/custom-target.service".source;

      # Test 4: User service has NO User= or Group= directive
      noUserEval = evalWithSystemd [
        {
          users.services.no-user = {
            enable = true;
            command = "${pkgs.coreutils}/bin/true";
          };
        }
      ];
      noUser = (getEtc noUserEval)."systemd/user/no-user.service".source;

      # Test 5: Environment variables
      envEval = evalWithSystemd [
        {
          users.services.env-svc = {
            enable = true;
            command = "${pkgs.coreutils}/bin/env";
            environment = {
              MY_VAR = "hello";
              MY_PATH = "/custom/path";
            };
          };
        }
      ];
      env = (getEtc envEval)."systemd/user/env-svc.service".source;

      # Test 6: Restart policy mapping
      restartEval = evalWithSystemd [
        {
          users.services.restart-never = {
            enable = true;
            command = "${pkgs.coreutils}/bin/true";
            restartPolicy = "never";
          };
        }
      ];
      restartNever = (getEtc restartEval)."systemd/user/restart-never.service".source;

      # Test 7: Dependencies (After, Wants)
      depsEval = evalWithSystemd [
        {
          users.services.with-deps = {
            enable = true;
            command = "${pkgs.coreutils}/bin/true";
            systemd = {
              after = [ "graphical-session.target" ];
              wants = [ "xdg-desktop-portal.service" ];
            };
          };
        }
      ];
      deps = (getEtc depsEval)."systemd/user/with-deps.service".source;

      # Test 8: WorkingDirectory
      wdEval = evalWithSystemd [
        {
          users.services.with-wd = {
            enable = true;
            command = "${pkgs.coreutils}/bin/true";
            workingDirectory = "/tmp/workdir";
          };
        }
      ];
      workingDir = (getEtc wdEval)."systemd/user/with-wd.service".source;

      # Test 9: Disabled service should NOT generate a unit
      disabledEval = evalWithSystemd [
        {
          users.services.disabled-svc = {
            enable = false;
            command = "${pkgs.coreutils}/bin/true";
          };
        }
      ];
      disabledEtc = getEtc disabledEval;

      # Test 10: Service without command should NOT generate a unit
      noCmdEval = evalWithSystemd [
        {
          users.services.no-cmd = {
            enable = true;
          };
        }
      ];
      noCmdEtc = getEtc noCmdEval;

      # Test 11: User services don't affect system services
      coexistEval = evalWithSystemd [
        {
          users.services.user-svc = {
            enable = true;
            command = "${pkgs.coreutils}/bin/true";
            description = "User Service";
          };
          services.dbus.enable = true;
        }
      ];
      coexistEtc = getEtc coexistEval;

      # Test 12: preStart and postStop hooks
      hooksEval = evalWithSystemd [
        {
          users.services.with-hooks = {
            enable = true;
            command = "${pkgs.coreutils}/bin/true";
            preStart = "echo setting up";
            postStop = "echo cleaning up";
          };
        }
      ];
      hooks = (getEtc hooksEval)."systemd/user/with-hooks.service".source;

    in
    {
      inherit
        basic
        defaultTarget
        customTarget
        noUser
        env
        restartNever
        deps
        workingDir
        hooks
        ;

      all = pkgs.runCommand "user-services-systemd-tests" { } ''
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

        echo "=== ekaos users.services systemd tests ===" > "$results"
        echo "" >> "$results"

        # Test 1: Basic service has description
        check "basic service has description" ${basic} "Description=Test User Daemon"

        # Test 2: Basic service has ExecStart
        check "basic service has ExecStart" ${basic} "ExecStart=.*sleep infinity"

        # Test 3: Default wantedBy is default.target
        check "default wantedBy is default.target" ${defaultTarget} "WantedBy=default.target"

        # Test 4: Custom wantedBy overrides default
        check "custom wantedBy" ${customTarget} "WantedBy=graphical-session.target"

        # Test 5: No User= directive in user service
        check_absent "no User= in user service" ${noUser} "^User="

        # Test 6: No Group= directive in user service
        check_absent "no Group= in user service" ${noUser} "^Group="

        # Test 7: Environment variables
        check "env var MY_VAR" ${env} 'Environment="MY_VAR=hello"'
        check "env var MY_PATH" ${env} 'Environment="MY_PATH=/custom/path"'

        # Test 8: Restart=no for never policy
        check "restart never maps to no" ${restartNever} "Restart=no"

        # Test 9: After dependency
        check "After dependency" ${deps} "After=graphical-session.target"

        # Test 10: Wants dependency
        check "Wants dependency" ${deps} "Wants=xdg-desktop-portal.service"

        # Test 11: WorkingDirectory
        check "WorkingDirectory" ${workingDir} "WorkingDirectory=/tmp/workdir"

        # Test 12: Disabled service has no unit file
        ${
          if disabledEtc ? "systemd/user/disabled-svc.service" then
            ''
              echo "FAIL: disabled service should not generate unit file" >> "$results"
              fail=$((fail + 1))
            ''
          else
            ''
              echo "PASS: disabled service has no unit file" >> "$results"
              pass=$((pass + 1))
            ''
        }

        # Test 13: Service without command has no unit file
        ${
          if noCmdEtc ? "systemd/user/no-cmd.service" then
            ''
              echo "FAIL: service without command should not generate unit file" >> "$results"
              fail=$((fail + 1))
            ''
          else
            ''
              echo "PASS: service without command has no unit file" >> "$results"
              pass=$((pass + 1))
            ''
        }

        # Test 14: User service exists alongside system service
        ${
          if coexistEtc ? "systemd/user/user-svc.service" && coexistEtc ? "systemd/system/dbus.service" then
            ''
              echo "PASS: user and system services coexist" >> "$results"
              pass=$((pass + 1))
            ''
          else
            ''
              echo "FAIL: user and system services should coexist" >> "$results"
              fail=$((fail + 1))
            ''
        }

        # Test 15: ExecStartPre for preStart
        check "preStart generates ExecStartPre" ${hooks} "ExecStartPre="

        # Test 16: ExecStopPost for postStop
        check "postStop generates ExecStopPost" ${hooks} "ExecStopPost="

        echo "" >> "$results"
        echo "Results: $pass passed, $fail failed" >> "$results"

        if [ "$fail" -gt 0 ]; then
          cat "$results" >&2
          exit 1
        fi

        # Copy individual service files for inspection
        cp ${basic} $out/basic.service
        cp ${defaultTarget} $out/default-target.service
        cp ${customTarget} $out/custom-target.service
        cp ${noUser} $out/no-user.service
        cp ${env} $out/env.service
        cp ${restartNever} $out/restart-never.service
        cp ${deps} $out/deps.service
        cp ${workingDir} $out/working-dir.service
        cp ${hooks} $out/hooks.service
      '';
    };

  # ── Runit tests ────────────────────────────────────────────────────

  runitTests =
    let
      # Test 1: Basic user service generates a run script
      basicEval = evalWithRunit [
        {
          users.services.test-daemon = {
            enable = true;
            description = "Test User Daemon";
            command = "${pkgs.coreutils}/bin/sleep";
            args = [ "infinity" ];
          };
        }
      ];
      basic = (getEtc basicEval)."sv-user/test-daemon".source;

      # Test 2: No chpst in user services
      noChpstEval = evalWithRunit [
        {
          users.services.no-chpst = {
            enable = true;
            command = "${pkgs.coreutils}/bin/true";
          };
        }
      ];
      noChpst = (getEtc noChpstEval)."sv-user/no-chpst".source;

      # Test 3: Environment variables
      envEval = evalWithRunit [
        {
          users.services.env-svc = {
            enable = true;
            command = "${pkgs.coreutils}/bin/env";
            environment = {
              MY_VAR = "hello";
            };
          };
        }
      ];
      env = (getEtc envEval)."sv-user/env-svc".source;

      # Test 4: WorkingDirectory
      wdEval = evalWithRunit [
        {
          users.services.with-wd = {
            enable = true;
            command = "${pkgs.coreutils}/bin/true";
            workingDirectory = "/tmp/workdir";
          };
        }
      ];
      workingDir = (getEtc wdEval)."sv-user/with-wd".source;

      # Test 5: postStop generates finish script
      finishEval = evalWithRunit [
        {
          users.services.with-finish = {
            enable = true;
            command = "${pkgs.coreutils}/bin/true";
            postStop = "echo cleanup";
          };
        }
      ];
      finish = (getEtc finishEval)."sv-user/with-finish".source;

      # Test 6: Disabled service should NOT generate directory
      disabledEval = evalWithRunit [
        {
          users.services.disabled-svc = {
            enable = false;
            command = "${pkgs.coreutils}/bin/true";
          };
        }
      ];
      disabledEtc = getEtc disabledEval;

      # Test 7: User services coexist with system services
      coexistEval = evalWithRunit [
        {
          users.services.user-svc = {
            enable = true;
            command = "${pkgs.coreutils}/bin/true";
          };
          services.dbus.enable = true;
        }
      ];
      coexistEtc = getEtc coexistEval;

    in
    {
      inherit
        basic
        noChpst
        env
        workingDir
        finish
        ;

      all = pkgs.runCommand "user-services-runit-tests" { } ''
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

        echo "=== ekaos users.services runit tests ===" > "$results"
        echo "" >> "$results"

        # Test 1: Run script exists and is executable
        if [ -x ${basic}/run ]; then
          echo "PASS: run script exists and is executable" >> "$results"
          pass=$((pass + 1))
        else
          echo "FAIL: run script missing or not executable" >> "$results"
          fail=$((fail + 1))
        fi

        # Test 2: Run script has description comment
        check "run script has description" ${basic}/run "Test User Daemon"

        # Test 3: Run script has exec with command
        check "run script has exec command" ${basic}/run "exec.*sleep infinity"

        # Test 4: No chpst command invocation in user service run script
        check_absent "no chpst invocation in user service" ${noChpst}/run "chpst -u"

        # Test 5: Environment variable exported
        check "env var exported" ${env}/run 'export MY_VAR="hello"'

        # Test 6: Working directory cd
        check "working directory cd" ${workingDir}/run "cd /tmp/workdir"

        # Test 7: Finish script exists for postStop
        if [ -x ${finish}/finish ]; then
          echo "PASS: finish script exists for postStop" >> "$results"
          pass=$((pass + 1))
        else
          echo "FAIL: finish script missing for postStop" >> "$results"
          fail=$((fail + 1))
        fi

        # Test 8: Finish script has cleanup content
        check "finish script content" ${finish}/finish "echo cleanup"

        # Test 9: Disabled service has no directory
        ${
          if disabledEtc ? "sv-user/disabled-svc" then
            ''
              echo "FAIL: disabled service should not generate directory" >> "$results"
              fail=$((fail + 1))
            ''
          else
            ''
              echo "PASS: disabled service has no directory" >> "$results"
              pass=$((pass + 1))
            ''
        }

        # Test 10: User and system services coexist
        ${
          if coexistEtc ? "sv-user/user-svc" && coexistEtc ? "sv/dbus" then
            ''
              echo "PASS: user and system services coexist" >> "$results"
              pass=$((pass + 1))
            ''
          else
            ''
              echo "FAIL: user and system services should coexist" >> "$results"
              fail=$((fail + 1))
            ''
        }

        echo "" >> "$results"
        echo "Results: $pass passed, $fail failed" >> "$results"

        if [ "$fail" -gt 0 ]; then
          cat "$results" >&2
          exit 1
        fi
      '';
    };

in

{
  systemd = systemdTests;
  runit = runitTests;

  # Run all tests
  all = pkgs.runCommand "user-services-all-tests" { } ''
    mkdir -p $out

    echo "=== Systemd tests ===" > $out/test-results.txt
    cat ${systemdTests.all}/test-results.txt >> $out/test-results.txt
    echo "" >> $out/test-results.txt

    echo "=== Runit tests ===" >> $out/test-results.txt
    cat ${runitTests.all}/test-results.txt >> $out/test-results.txt

    echo "" >> $out/test-results.txt
    echo "All user-services tests passed." >> $out/test-results.txt
  '';
}
