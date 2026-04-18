# Test suite for launchd plist generation
{
  pkgs ? import ../../. { },
}:

let
  services = import ../default.nix { inherit pkgs; };

  # Test 1: Basic service with minimal options
  basicServiceConfig = {
    basic-test = {
      enable = true;
      description = "Basic Test Service";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "Hello from launchd" ];
      restartPolicy = "never";

      launchd = {
        runAtLoad = true;
      };
    };
  };

  # Test 2: Service with environment variables and PATH
  envServiceConfig = {
    env-test = {
      enable = true;
      description = "Environment Test Service";
      command = "${pkgs.bash}/bin/bash";
      args = [ "-c" "echo $TEST_VAR" ];

      environment = {
        TEST_VAR = "test-value";
        ANOTHER_VAR = "another-value";
      };

      path = with pkgs; [ coreutils gnugrep ];

      restartPolicy = "always";

      launchd = {
        label = "org.nixos.env-test";
        keepAlive = true;
      };
    };
  };

  # Test 3: Service with scheduling (StartCalendarInterval)
  scheduledServiceConfig = {
    scheduled-test = {
      enable = true;
      description = "Scheduled Test Service";
      command = "${pkgs.coreutils}/bin/date";
      restartPolicy = "never";

      launchd = {
        label = "org.nixos.scheduled-test";
        runAtLoad = false;

        # Run at 2:30 AM every day
        startCalendarInterval = {
          hour = 2;
          minute = 30;
        };
      };
    };
  };

  # Test 4: Service with multiple calendar intervals
  multiScheduleServiceConfig = {
    multi-schedule-test = {
      enable = true;
      description = "Multi-Schedule Test Service";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "Running scheduled task" ];
      restartPolicy = "never";

      launchd = {
        # Run at 9 AM and 5 PM every day
        startCalendarInterval = [
          { hour = 9; minute = 0; }
          { hour = 17; minute = 0; }
        ];
      };
    };
  };

  # Test 5: Service with event-driven triggers
  watchServiceConfig = {
    watch-test = {
      enable = true;
      description = "File Watch Test Service";
      command = "${pkgs.coreutils}/bin/echo";
      args = [ "Config file changed" ];
      restartPolicy = "never";

      launchd = {
        label = "org.nixos.watch-test";
        runAtLoad = false;

        # Watch for config file changes
        watchPaths = [
          "$HOME/.config/myapp/config.yaml"
          "$HOME/.config/myapp/settings.json"
        ];
      };
    };
  };

  # Test 6: Service with resource limits
  limitedServiceConfig = {
    limited-test = {
      enable = true;
      description = "Resource Limited Test Service";
      command = "${pkgs.python3}/bin/python3";
      args = [ "-m" "http.server" "8080" ];
      user = "nobody";
      group = "nobody";
      restartPolicy = "on-failure";

      launchd = {
        label = "org.nixos.limited-test";
        keepAlive = { successfulExit = false; };
        processType = "Background";
        nice = 10;

        softResourceLimits = {
          NumberOfFiles = 256;
          NumberOfProcesses = 32;
        };

        hardResourceLimits = {
          NumberOfFiles = 512;
          NumberOfProcesses = 64;
        };

        exitTimeout = 30;
      };
    };
  };

  # Test 7: Service with working directory and preStart
  workdirServiceConfig = {
    workdir-test = {
      enable = true;
      description = "Working Directory Test Service";
      command = "${pkgs.coreutils}/bin/pwd";
      workingDirectory = "/tmp/test-service";
      restartPolicy = "never";

      preStart = ''
        mkdir -p /tmp/test-service
        echo "Initialized" > /tmp/test-service/status.txt
      '';

      launchd = {
        runAtLoad = true;
      };
    };
  };

  # Test 8: Service with KeepAlive conditions
  keepAliveConditionsConfig = {
    keepalive-conditions-test = {
      enable = true;
      description = "KeepAlive Conditions Test";
      command = "${pkgs.coreutils}/bin/sleep";
      args = [ "infinity" ];
      restartPolicy = "always";

      launchd = {
        label = "org.nixos.keepalive-conditions";

        # Complex KeepAlive with multiple conditions
        keepAlive = {
          successfulExit = false;
          networkState = true;
          pathState = {
            "/tmp/enable-service" = true;
          };
        };
      };
    };
  };

  # Build all test services
  basicService = services.buildLaunchdUserAgents basicServiceConfig;
  envService = services.buildLaunchdUserAgents envServiceConfig;
  scheduledService = services.buildLaunchdUserAgents scheduledServiceConfig;
  multiScheduleService = services.buildLaunchdUserAgents multiScheduleServiceConfig;
  watchService = services.buildLaunchdUserAgents watchServiceConfig;
  limitedService = services.buildLaunchdUserAgents limitedServiceConfig;
  workdirService = services.buildLaunchdUserAgents workdirServiceConfig;
  keepAliveConditionsService = services.buildLaunchdUserAgents keepAliveConditionsConfig;

  # Helper to extract plist content for inspection
  getPlist = svc: name:
    builtins.readFile "${svc.${name}}/${name}.plist";

in
{
  # Export all test services
  inherit
    basicService
    envService
    scheduledService
    multiScheduleService
    watchService
    limitedService
    workdirService
    keepAliveConditionsService
    ;

  # Export configs for inspection
  configs = {
    inherit
      basicServiceConfig
      envServiceConfig
      scheduledServiceConfig
      multiScheduleServiceConfig
      watchServiceConfig
      limitedServiceConfig
      workdirServiceConfig
      keepAliveConditionsConfig
      ;
  };

  # Convenience attribute for building all tests at once
  all = pkgs.linkFarm "launchd-tests" [
    { name = "basic-test.plist"; path = "${basicService.basic-test}/basic-test.plist"; }
    { name = "env-test.plist"; path = "${envService.env-test}/env-test.plist"; }
    { name = "scheduled-test.plist"; path = "${scheduledService.scheduled-test}/scheduled-test.plist"; }
    { name = "multi-schedule-test.plist"; path = "${multiScheduleService.multi-schedule-test}/multi-schedule-test.plist"; }
    { name = "watch-test.plist"; path = "${watchService.watch-test}/watch-test.plist"; }
    { name = "limited-test.plist"; path = "${limitedService.limited-test}/limited-test.plist"; }
    { name = "workdir-test.plist"; path = "${workdirService.workdir-test}/workdir-test.plist"; }
    { name = "keepalive-conditions-test.plist"; path = "${keepAliveConditionsService.keepalive-conditions-test}/keepalive-conditions-test.plist"; }
  ];
}
