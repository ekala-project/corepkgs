# Test backdoor for ekaosTest VMs
#
# The test driver creates a listening unix socket and passes its path to
# the VM script via EKAOS_TEST_SHELL_SOCKET. QEMU connects to it as a
# virtio console (/dev/hvc0 in the guest), where this service runs a root
# shell. Machine.execute() drives that shell.
#
# The service is started via the `systemd.wants=` kernel parameter so it
# does not depend on [Install]-based enablement.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  bash = pkgs.bashNonInteractive;

  backdoorScript = ''
    export PATH=/run/current-system/sw/bin:/run/wrappers/bin:${
      lib.makeBinPath [
        pkgs.coreutils
        bash
        config.systemd.package
      ]
    }
    export USER=root HOME=/root
    # Commands run on a tty, so keep systemctl and friends from paging.
    export PAGER= SYSTEMD_PAGER=
    cd /

    exec < /dev/hvc0 > /dev/hvc0
    # Keep stderr out of the command channel; it shows up in the serial log.
    while ! exec 2> /dev/ttyS0; do sleep 0.1; done

    # Raw mode: no echo of sent commands, no NL -> CR/NL translation.
    stty -F /dev/hvc0 raw -echo

    echo "ekaos-backdoor: spawning root shell" >&2
    echo "ekaos-backdoor-ready"
    # Passing the device as a script argument keeps bash non-interactive
    # even though stdin is a tty: no readline (which would eat tabs and
    # control bytes), job control, prompt or history.
    PS1= exec ${bash}/bin/bash --norc /dev/hvc0
  '';
in
{
  virtualisation.qemuOptions = ''
    if [ -n "''${EKAOS_TEST_SHELL_SOCKET:-}" ]; then
      QEMU_OPTS+=(
        -chardev socket,id=shell,path="$EKAOS_TEST_SHELL_SOCKET"
        -device virtio-serial-pci
        -device virtconsole,chardev=shell
      )
    fi
  '';

  boot.kernelParams = [ "systemd.wants=ekaos-test-backdoor.service" ];

  systemd.services.ekaos-test-backdoor = {
    description = "ekaosTest backdoor shell";
    requires = [ "dev-hvc0.device" ];
    after = [ "dev-hvc0.device" ];
    script = backdoorScript;
    serviceConfig = {
      Type = "simple";
      KillSignal = "SIGHUP";
    };
  };

  # systemd-getty-generator spawns gettys on the kernel console and on
  # virtio consoles. They fight the backdoor for hvc0 and make writes to
  # ttyS0 fail with EIO, so mask both.
  environment.etc."systemd/system/serial-getty@hvc0.service".source = "/dev/null";
  environment.etc."systemd/system/serial-getty@ttyS0.service".source = "/dev/null";
}
