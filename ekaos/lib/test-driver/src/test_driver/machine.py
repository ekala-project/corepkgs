"""
Machine class for ekaosTest
Provides test primitives for controlling and testing VMs

Commands run through a root shell inside the guest (see
lib/testing/backdoor.nix). The driver listens on a unix socket and QEMU
connects to it as a virtio console, so the guest shell is reachable as
soon as the backdoor service starts.
"""

import base64
import os
import shlex
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
from typing import Optional, Tuple
from .logger import log

READY_MARKER = b"ekaos-backdoor-ready"

# Extra host-side slack on top of the guest-side `timeout` before the
# channel is declared hung.
CHANNEL_GRACE = 30


class Machine:
    """Represents a test VM with methods to control and test it"""

    def __init__(self, name: str, vm_script: str, boot_timeout: int = 900):
        self.name = name
        self.vm_script = vm_script
        self.boot_timeout = boot_timeout
        self.process: Optional[subprocess.Popen] = None
        self.booted = False
        self.shell: Optional[socket.socket] = None
        self._listener: Optional[socket.socket] = None
        self._state_dir: Optional[str] = None
        self._buf = b""
        self._serial_thread: Optional[threading.Thread] = None

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    def start(self) -> None:
        """Start the VM (returns immediately; commands wait for the shell)"""
        if self.process is not None:
            return

        log(f"Starting machine '{self.name}'")

        self._state_dir = tempfile.mkdtemp(prefix=f"ekaos-{self.name}-")
        sock_path = os.path.join(self._state_dir, "shell")
        self._listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self._listener.bind(sock_path)
        self._listener.listen(1)

        env = dict(os.environ, EKAOS_TEST_SHELL_SOCKET=sock_path)
        self.process = subprocess.Popen(
            [self.vm_script],
            # Kept open (but idle) so send_console()/console_interact()
            # can type on the serial console.
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            env=env,
            cwd=self._state_dir,
        )

        # The serial console must be drained or QEMU blocks once the pipe
        # buffer fills.
        self._serial_thread = threading.Thread(
            target=self._pump_serial, daemon=True
        )
        self._serial_thread.start()

    def _pump_serial(self) -> None:
        assert self.process is not None and self.process.stdout is not None
        for raw in iter(self.process.stdout.readline, b""):
            line = raw.decode(errors="replace").rstrip("\r\n")
            log(f"[{self.name} serial] {line}")

    def _connect(self) -> None:
        """Wait for QEMU to connect and the guest shell to come up"""
        if self.shell is not None:
            return
        # Like the NixOS driver, the first command boots the machine.
        if self.process is None:
            self.start()
        if not self.is_up():
            raise Exception(f"Machine '{self.name}' is not running")
        assert self._listener is not None

        log(f"[{self.name}] Waiting for backdoor shell")
        deadline = time.time() + self.boot_timeout

        self._listener.settimeout(1)
        while self.shell is None:
            self._check_alive()
            if time.time() > deadline:
                raise Exception(f"Machine '{self.name}': QEMU never connected")
            try:
                self.shell, _ = self._listener.accept()
            except socket.timeout:
                pass

        while True:
            line = self._read_line(deadline)
            if line.strip() == READY_MARKER:
                break

        self.booted = True
        log(f"[{self.name}] Backdoor shell connected")

    def shutdown(self, timeout: int = 60) -> None:
        """Power off the VM gracefully, killing it on timeout"""
        if self.process is None:
            return

        log(f"Shutting down machine '{self.name}'")

        if self.shell is not None and self.is_up():
            try:
                self.shell.sendall(b"systemctl poweroff\n")
            except OSError:
                pass
            self.wait_for_shutdown(timeout=timeout)
        else:
            self.crash()
        self._cleanup()

    def crash(self) -> None:
        """Kill the VM immediately"""
        if self.process is None:
            return
        log(f"Killing machine '{self.name}'")
        self.process.terminate()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait()
        self._cleanup()

    def wait_for_shutdown(self, timeout: int = 60) -> None:
        """Wait for VM to shutdown"""
        if self.process is None:
            return

        try:
            self.process.wait(timeout=timeout)
            log(f"Machine '{self.name}' shut down")
        except subprocess.TimeoutExpired:
            log(f"Shutdown timeout for '{self.name}', killing")
            self.process.kill()
            self.process.wait()
        self._cleanup()

    def _cleanup(self) -> None:
        if self.process is not None and self.process.poll() is None:
            return
        if self._serial_thread is not None:
            self._serial_thread.join(timeout=5)
            self._serial_thread = None
        for s in (self.shell, self._listener):
            if s is not None:
                s.close()
        if self.process is not None and self.process.stdin is not None:
            self.process.stdin.close()
        self.shell = None
        self._listener = None
        self._buf = b""
        if self._state_dir is not None:
            shutil.rmtree(self._state_dir, ignore_errors=True)
            self._state_dir = None
        self.process = None
        self.booted = False

    def is_up(self) -> bool:
        """Check if VM is running"""
        return self.process is not None and self.process.poll() is None

    def _check_alive(self) -> None:
        if not self.is_up():
            code = None if self.process is None else self.process.returncode
            raise Exception(f"Machine '{self.name}' exited (status {code})")

    # ------------------------------------------------------------------
    # Command channel
    # ------------------------------------------------------------------

    def _read_line(self, deadline: float) -> bytes:
        assert self.shell is not None
        while b"\n" not in self._buf:
            remaining = deadline - time.time()
            if remaining <= 0:
                raise Exception(f"Machine '{self.name}': timeout on shell channel")
            self.shell.settimeout(min(remaining, 1.0))
            try:
                chunk = self.shell.recv(65536)
            except socket.timeout:
                self._check_alive()
                continue
            if not chunk:
                raise Exception(f"Machine '{self.name}': shell channel closed")
            self._buf += chunk
        line, self._buf = self._buf.split(b"\n", 1)
        return line

    def execute(
        self, command: str, check_return: bool = True, timeout: int = 900
    ) -> Tuple[int, str]:
        """
        Execute a command in the VM as root

        Stdout is captured and returned; stderr goes to the serial log.
        A command exceeding `timeout` seconds is killed and reported with
        exit code 124.

        Returns: (return_code, stdout)
        Raises: Exception if check_return=True and command fails
        """
        self._connect()
        assert self.shell is not None

        log(f"[{self.name}] $ {command}")

        wrapped = (
            f"timeout {int(timeout)} bash -c {shlex.quote(command)} < /dev/null"
            ' | (base64 -w 0; echo); echo "${PIPESTATUS[0]}"\n'
        )
        self.shell.sendall(wrapped.encode())

        deadline = time.time() + timeout + CHANNEL_GRACE
        output = base64.b64decode(self._read_line(deadline)).decode(
            errors="replace"
        )
        return_code = int(self._read_line(deadline).strip())

        if output:
            log(f"[{self.name}] Output: {output.rstrip()}")

        if check_return and return_code != 0:
            raise Exception(
                f"Command failed with exit code {return_code}: {command}"
            )
        return return_code, output

    def succeed(self, command: str, timeout: int = 900) -> str:
        """Execute command and assert it succeeds (exit code 0)"""
        _, output = self.execute(command, check_return=True, timeout=timeout)
        return output

    def fail(self, command: str, timeout: int = 900) -> str:
        """Execute command and assert it fails (non-zero exit code)"""
        ret, output = self.execute(command, check_return=False, timeout=timeout)
        if ret == 0:
            raise Exception(f"Command unexpectedly succeeded: {command}")
        return output

    # ------------------------------------------------------------------
    # Higher-level helpers
    # ------------------------------------------------------------------

    def wait_for_unit(
        self, unit: str, user: Optional[str] = None, timeout: int = 900
    ) -> None:
        """Wait for a systemd unit to be active"""
        log(f"[{self.name}] Waiting for unit '{unit}'")

        q = shlex.quote(unit)
        cmd = f"systemctl is-active {q}"
        if user:
            cmd = (
                f"systemctl --user -M {shlex.quote(user)}@ is-active {q}"
            )

        self.wait_until_succeeds(cmd, timeout=timeout)
        log(f"[{self.name}] Unit '{unit}' is active")

    def wait_for_open_port(
        self, port: int, addr: str = "127.0.0.1", timeout: int = 900
    ) -> None:
        """Wait for a TCP port to accept connections inside the guest"""
        log(f"[{self.name}] Waiting for port {addr}:{port}")
        self.wait_until_succeeds(
            f"exec 3<>/dev/tcp/{addr}/{int(port)}", timeout=timeout
        )
        log(f"[{self.name}] Port {addr}:{port} is open")

    def wait_for_closed_port(
        self, port: int, addr: str = "127.0.0.1", timeout: int = 900
    ) -> None:
        """Wait for a TCP port to stop accepting connections in the guest"""
        log(f"[{self.name}] Waiting for port {addr}:{port} to close")
        self.wait_until_fails(
            f"exec 3<>/dev/tcp/{addr}/{int(port)}", timeout=timeout
        )

    def wait_for_file(self, path: str, timeout: int = 900) -> None:
        """Wait for a file to exist"""
        log(f"[{self.name}] Waiting for file '{path}'")
        self.wait_until_succeeds(f"test -f {shlex.quote(path)}", timeout=timeout)
        log(f"[{self.name}] File '{path}' exists")

    def wait_until_succeeds(self, command: str, timeout: int = 900) -> str:
        """Retry command until it succeeds"""
        log(f"[{self.name}] Waiting until succeeds: {command}")

        # Boot time does not count against the command's timeout.
        self._connect()
        deadline = time.time() + timeout
        last = None

        while True:
            remaining = max(1, int(deadline - time.time()))
            ret, output = self.execute(
                command, check_return=False, timeout=min(remaining, 60)
            )
            if ret == 0:
                return output
            last = (ret, output)
            if time.time() >= deadline:
                break
            time.sleep(1)

        raise Exception(
            f"Command never succeeded: {command} "
            f"(last exit code {last[0]}, output: {last[1]!r})"
        )

    def wait_until_fails(self, command: str, timeout: int = 900) -> str:
        """Retry command until it fails"""
        log(f"[{self.name}] Waiting until fails: {command}")

        self._connect()
        deadline = time.time() + timeout

        while True:
            remaining = max(1, int(deadline - time.time()))
            ret, output = self.execute(
                command, check_return=False, timeout=min(remaining, 60)
            )
            if ret != 0:
                return output
            if time.time() >= deadline:
                break
            time.sleep(1)

        raise Exception(f"Command never failed: {command}")

    def systemctl(self, command: str, user: Optional[str] = None) -> str:
        """Run systemctl command"""
        cmd = f"systemctl {command}"
        if user:
            cmd = f"systemctl --user -M {shlex.quote(user)}@ {command}"
        return self.succeed(cmd)

    def shell_interact(self, address: Optional[str] = None) -> None:
        """
        Attach to the guest's root shell (for test development only)

        `address` is a socat address. By default the calling terminal gets
        a readline prompt; something like "TCP-LISTEN:4444" lets you attach
        from elsewhere instead. Commands' stderr shows up in the serial log.
        Ending the session with Ctrl-D or Ctrl-C also ends the guest shell.
        """
        self._connect()
        assert self.shell is not None

        if address is None:
            address = "READLINE,prompt=$ "
            log(f"[{self.name}] Terminal is ready (there is no initial prompt)")

        fd = self.shell.fileno()
        try:
            subprocess.run(["socat", address, f"FD:{fd}"], pass_fds=[fd])
        except KeyboardInterrupt:
            # Let users leave the session without failing the test.
            pass

    def send_console(self, chars: str) -> None:
        r"""
        Type on the serial console (QEMU's stdin)

        Works without the backdoor shell, e.g. for systemd emergency mode:
        `send_console("\n\nsystemctl default\n")`.
        """
        self._write_console(chars.encode())

    def _write_console(self, data: bytes) -> None:
        if not self.is_up():
            raise Exception(f"Machine '{self.name}' is not running")
        assert self.process is not None and self.process.stdin is not None
        self.process.stdin.write(data)
        self.process.stdin.flush()

    def console_interact(self) -> None:
        """
        Forward terminal input to the serial console (for test development)

        Meant for the interactive driver, not for tests. Console output
        shows up line-wise in the serial log. Ctrl-D returns to the REPL;
        Ctrl-C also reaches QEMU and kills the VM.
        """
        log(f"[{self.name}] Terminal is ready (there is no prompt)")
        while True:
            try:
                char = sys.stdin.buffer.read(1)
            except KeyboardInterrupt:
                break
            if char == b"":  # Ctrl-D
                log(f"[{self.name}] Closing connection to the console")
                break
            self._write_console(char)
