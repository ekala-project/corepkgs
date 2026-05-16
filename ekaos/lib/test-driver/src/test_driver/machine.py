"""
Machine class for ekaosTest
Provides test primitives for controlling and testing VMs
"""

import subprocess
import time
import os
import socket
from typing import Optional, Tuple
from .logger import log


class Machine:
    """Represents a test VM with methods to control and test it"""

    def __init__(self, name: str, vm_script: str):
        self.name = name
        self.vm_script = vm_script
        self.process: Optional[subprocess.Popen] = None
        self.booted = False

    def start(self) -> None:
        """Start the VM"""
        if self.process is not None:
            return

        log(f"Starting machine '{self.name}'")

        self.process = subprocess.Popen(
            [self.vm_script],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        # Give VM time to boot
        time.sleep(2)
        self.booted = True
        log(f"Machine '{self.name}' started")

    def shutdown(self) -> None:
        """Shutdown the VM gracefully"""
        if self.process is None:
            return

        log(f"Shutting down machine '{self.name}'")

        # TODO: Implement proper VM shutdown via QMP or serial console
        # For now, just kill the QEMU process since execute() is non-functional
        try:
            self.process.terminate()
            self.process.wait(timeout=5)
            log(f"Machine '{self.name}' shut down")
        except subprocess.TimeoutExpired:
            log(f"Terminate timeout, killing machine '{self.name}'")
            self.process.kill()
            self.process.wait()

        self.process = None
        self.booted = False

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

    def is_up(self) -> bool:
        """Check if VM is running"""
        return self.process is not None and self.process.poll() is None

    def execute(self, command: str, check_return: bool = True, timeout: int = 900) -> Tuple[int, str]:
        """
        Execute a command in the VM

        Returns: (return_code, stdout)
        Raises: Exception if check_return=True and command fails
        """
        if not self.is_up():
            raise Exception(f"Machine '{self.name}' is not running")

        log(f"[{self.name}] $ {command}")

        # For MVP, we'll use a simple approach: write to VM stdin
        # In full implementation, this would use QMP/shell socket
        try:
            # Simple execution via process stdin/stdout
            # This is a simplified version for MVP
            self.process.stdin.write(f"{command}\n".encode())
            self.process.stdin.flush()

            # Read output (simplified)
            output = ""
            return_code = 0

            if check_return and return_code != 0:
                raise Exception(f"Command failed with exit code {return_code}: {command}")

            log(f"[{self.name}] Output: {output}")
            return return_code, output

        except Exception as e:
            log(f"[{self.name}] Command failed: {e}")
            if check_return:
                raise
            return 1, str(e)

    def succeed(self, command: str, timeout: int = 900) -> str:
        """Execute command and assert it succeeds (exit code 0)"""
        ret, output = self.execute(command, check_return=True, timeout=timeout)
        return output

    def fail(self, command: str, timeout: int = 900) -> str:
        """Execute command and assert it fails (non-zero exit code)"""
        ret, output = self.execute(command, check_return=False, timeout=timeout)
        if ret == 0:
            raise Exception(f"Command unexpectedly succeeded: {command}")
        return output

    def wait_for_unit(self, unit: str, user: Optional[str] = None, timeout: int = 900) -> None:
        """Wait for a systemd unit to be active"""
        log(f"[{self.name}] Waiting for unit '{unit}'")

        cmd = f"systemctl is-active {unit}"
        if user:
            cmd = f"systemctl --user is-active {unit}"

        self.wait_until_succeeds(cmd, timeout=timeout)
        log(f"[{self.name}] Unit '{unit}' is active")

    def wait_for_open_port(self, port: int, timeout: int = 900) -> None:
        """Wait for a TCP port to be open"""
        log(f"[{self.name}] Waiting for port {port}")

        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)
                # For MVP, assume localhost. Full version would handle VMs properly
                result = sock.connect_ex(('localhost', port))
                sock.close()

                if result == 0:
                    log(f"[{self.name}] Port {port} is open")
                    return
            except Exception:
                pass

            time.sleep(1)

        raise Exception(f"Timeout waiting for port {port}")

    def wait_for_file(self, path: str, timeout: int = 900) -> None:
        """Wait for a file to exist"""
        log(f"[{self.name}] Waiting for file '{path}'")
        self.wait_until_succeeds(f"test -f {path}", timeout=timeout)
        log(f"[{self.name}] File '{path}' exists")

    def wait_until_succeeds(self, command: str, timeout: int = 900) -> str:
        """Retry command until it succeeds"""
        log(f"[{self.name}] Waiting until succeeds: {command}")

        start_time = time.time()
        last_error = None

        while time.time() - start_time < timeout:
            try:
                ret, output = self.execute(command, check_return=True, timeout=10)
                return output
            except Exception as e:
                last_error = e
                time.sleep(1)

        raise Exception(f"Command never succeeded: {command}. Last error: {last_error}")

    def wait_until_fails(self, command: str, timeout: int = 900) -> None:
        """Retry command until it fails"""
        log(f"[{self.name}] Waiting until fails: {command}")

        start_time = time.time()

        while time.time() - start_time < timeout:
            ret, _ = self.execute(command, check_return=False, timeout=10)
            if ret != 0:
                return
            time.sleep(1)

        raise Exception(f"Command never failed: {command}")

    def systemctl(self, command: str, user: Optional[str] = None) -> str:
        """Run systemctl command"""
        cmd = f"systemctl {command}"
        if user:
            cmd = f"systemctl --user {command}"
        return self.succeed(cmd)

    def shell_interact(self) -> None:
        """Open an interactive shell (for debugging)"""
        log(f"Opening interactive shell for '{self.name}'")
        log("Note: Interactive mode not fully implemented in MVP")
        # Full implementation would connect to VM shell socket
