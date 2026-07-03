# Translate common timer options to launchd plist with scheduling
{ lib, pkgs }:

let
  inherit (lib) optionalString;

  launchdTranslate = import ./launchd-translate.nix { inherit lib pkgs; };

  # Convert calendar shorthand to launchd StartCalendarInterval dict
  calendarToLaunchd =
    cal:
    if cal == "minutely" then
      { }
    else if cal == "hourly" then
      { Minute = 0; }
    else if cal == "daily" then
      {
        Hour = 0;
        Minute = 0;
      }
    else if cal == "weekly" then
      {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      }
    else if cal == "monthly" then
      {
        Day = 1;
        Hour = 0;
        Minute = 0;
      }
    else
      # For complex expressions, fall back to hourly as safe default
      # (systemd OnCalendar syntax doesn't map cleanly to launchd)
      { Minute = 0; };

  # Generate plist XML for a dict
  dictToPlist =
    dict:
    let
      entries = lib.mapAttrsToList (k: v: ''
        <key>${k}</key>
        <integer>${toString v}</integer>
      '') dict;
    in
    ''
      <dict>
        ${lib.concatStringsSep "" entries}
      </dict>
    '';

in
{
  # Generate a launchd plist for a scheduled task
  toLaunchdPlist =
    name: config:
    let
      sched = config.schedule;
      scriptDrv = pkgs.writeShellScript "${name}-timer" config.script;
      label = "org.ekaos.timer.${name}";
    in
    ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>${label}</string>

        <key>ProgramArguments</key>
        <array>
          <string>${scriptDrv}</string>
        </array>

        <key>UserName</key>
        <string>${config.user}</string>

        <key>GroupName</key>
        <string>${config.group}</string>

        ${optionalString (sched.calendar != null) ''
          <key>StartCalendarInterval</key>
          ${dictToPlist (calendarToLaunchd sched.calendar)}
        ''}

        ${optionalString (sched.interval != null) ''
          <key>StartInterval</key>
          <integer>${toString sched.interval}</integer>
        ''}

        ${optionalString (sched.onBoot != null) ''
          <key>RunAtLoad</key>
          <true/>
        ''}
      </dict>
      </plist>
    '';
}
