"""RunitMachine class for interacting with runit-supervised services in tests."""

import os
import socket
import subprocess
import time
from pathlib import Path
from typing import Optional, Tuple


class RunitMachine:
    """Represents the runit-supervised sandbox environment for testing.

    This class provides an API similar to nixosTests' Machine class, but adapted
    for local sandbox execution with runit supervision instead of VM-based testing.

    Example:
        machine = RunitMachine()
        machine.wait_for_open_port(8080)
        output = machine.succeed("curl http://localhost:8080")
    """

    def __init__(
        self,
        default_timeout: int = 900,
        runit_service_dir: Optional[str] = None,
    ):
        """Initialize the RunitMachine.

        Args:
            default_timeout: Default timeout for operations in seconds
            runit_service_dir: Path to runit service directory (from $RUNIT_SERVICE_DIR)
        """
        self.default_timeout = default_timeout
        self.runit_service_dir = runit_service_dir or os.environ.get("RUNIT_SERVICE_DIR", "")

    def execute(
        self,
        command: str,
        timeout: Optional[int] = None,
    ) -> Tuple[int, str]:
        """Execute a command in the sandbox and return (returncode, output).

        Args:
            command: Shell command to execute
            timeout: Timeout in seconds (uses default_timeout if None)

        Returns:
            Tuple of (return_code, combined_output)

        Example:
            ret, out = machine.execute("echo hello")
            assert ret == 0
        """
        timeout = timeout if timeout is not None else self.default_timeout

        try:
            result = subprocess.run(
                ["bash", "-c", command],
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            # Combine stdout and stderr like nixosTests does
            output = result.stdout + result.stderr
            return (result.returncode, output)
        except subprocess.TimeoutExpired:
            raise Exception(f"Command timed out after {timeout}s: {command}")

    def succeed(
        self,
        command: str,
        timeout: Optional[int] = None,
    ) -> str:
        """Execute a command and assert it succeeds (returncode == 0).

        Args:
            command: Shell command to execute
            timeout: Timeout in seconds

        Returns:
            Combined stdout and stderr output

        Raises:
            Exception: If command fails (non-zero return code)

        Example:
            output = machine.succeed("curl http://localhost:8080")
        """
        ret, output = self.execute(command, timeout)
        if ret != 0:
            raise Exception(
                f"Command failed (exit {ret}): {command}\nOutput:\n{output}"
            )
        return output

    def fail(
        self,
        command: str,
        timeout: Optional[int] = None,
    ) -> str:
        """Execute a command and assert it fails (returncode != 0).

        Args:
            command: Shell command to execute
            timeout: Timeout in seconds

        Returns:
            Combined stdout and stderr output

        Raises:
            Exception: If command succeeds (zero return code)

        Example:
            machine.fail("false")
        """
        ret, output = self.execute(command, timeout)
        if ret == 0:
            raise Exception(
                f"Command succeeded unexpectedly: {command}\nOutput:\n{output}"
            )
        return output

    def wait_for_open_port(
        self,
        port: int,
        addr: str = "localhost",
        timeout: int = 900,
    ) -> None:
        """Wait for a TCP port to accept connections.

        Args:
            port: TCP port number
            addr: Address to connect to (default: localhost)
            timeout: Timeout in seconds

        Raises:
            Exception: If port doesn't open within timeout

        Example:
            machine.wait_for_open_port(8080)
        """
        start = time.time()
        while time.time() - start < timeout:
            try:
                with socket.create_connection((addr, port), timeout=1):
                    return
            except (socket.timeout, ConnectionRefusedError, OSError):
                time.sleep(1)

        raise Exception(
            f"Port {port} on {addr} did not open within {timeout}s"
        )

    def wait_for_closed_port(
        self,
        port: int,
        addr: str = "localhost",
        timeout: int = 900,
    ) -> None:
        """Wait for a TCP port to be closed (no longer accepting connections).

        Args:
            port: TCP port number
            addr: Address to check (default: localhost)
            timeout: Timeout in seconds

        Raises:
            Exception: If port doesn't close within timeout

        Example:
            machine.wait_for_closed_port(8080)
        """
        start = time.time()
        while time.time() - start < timeout:
            try:
                with socket.create_connection((addr, port), timeout=1):
                    # Port is still open, keep waiting
                    time.sleep(1)
            except (socket.timeout, ConnectionRefusedError, OSError):
                # Port is closed
                return

        raise Exception(
            f"Port {port} on {addr} did not close within {timeout}s"
        )

    def wait_until_succeeds(
        self,
        command: str,
        timeout: int = 900,
    ) -> str:
        """Retry command until it succeeds (returncode == 0).

        Args:
            command: Shell command to execute
            timeout: Timeout in seconds

        Returns:
            Output from the successful command execution

        Raises:
            Exception: If command never succeeds within timeout

        Example:
            machine.wait_until_succeeds("curl http://localhost:8080")
        """
        start = time.time()
        last_output = ""

        while time.time() - start < timeout:
            ret, output = self.execute(command, timeout=10)
            if ret == 0:
                return output
            last_output = output
            time.sleep(1)

        raise Exception(
            f"Command never succeeded within {timeout}s: {command}\n"
            f"Last output:\n{last_output}"
        )

    def wait_until_fails(
        self,
        command: str,
        timeout: int = 900,
    ) -> str:
        """Retry command until it fails (returncode != 0).

        Args:
            command: Shell command to execute
            timeout: Timeout in seconds

        Returns:
            Output from the failed command execution

        Raises:
            Exception: If command never fails within timeout

        Example:
            machine.wait_until_fails("systemctl is-active failing.service")
        """
        start = time.time()
        last_output = ""

        while time.time() - start < timeout:
            ret, output = self.execute(command, timeout=10)
            if ret != 0:
                return output
            last_output = output
            time.sleep(1)

        raise Exception(
            f"Command never failed within {timeout}s: {command}\n"
            f"Last output:\n{last_output}"
        )

    def wait_for_file(
        self,
        path: str,
        timeout: int = 900,
    ) -> None:
        """Wait for a file to exist.

        Args:
            path: File path to wait for
            timeout: Timeout in seconds

        Raises:
            Exception: If file doesn't exist within timeout

        Example:
            machine.wait_for_file("/tmp/ready")
        """
        start = time.time()

        while time.time() - start < timeout:
            if Path(path).exists():
                return
            time.sleep(1)

        raise Exception(f"File {path} did not appear within {timeout}s")

    def wait_for_unit(
        self,
        service: str,
        timeout: int = 900,
    ) -> None:
        """Wait for a runit service to be supervised and running.

        This checks that the service is being supervised by runit using 'sv status'.

        Args:
            service: Service name (directory name in RUNIT_SERVICE_DIR)
            timeout: Timeout in seconds

        Raises:
            Exception: If service is not running within timeout

        Example:
            machine.wait_for_unit("myservice")
        """
        if not self.runit_service_dir:
            raise Exception("RUNIT_SERVICE_DIR not set")

        service_path = f"{self.runit_service_dir}/{service}"

        # Wait for service to be running according to 'sv status'
        def check_status():
            ret, output = self.execute(f"sv status {service_path}", timeout=10)
            # sv status returns 0 and output contains "run:" when service is running
            return ret == 0 and "run:" in output

        start = time.time()
        while time.time() - start < timeout:
            if check_status():
                return
            time.sleep(1)

        # Get final status for error message
        ret, output = self.execute(f"sv status {service_path}", timeout=10)
        raise Exception(
            f"Service '{service}' did not start within {timeout}s\n"
            f"Status: {output}"
        )

    def sv_status(self, service: str) -> str:
        """Get the status of a runit service.

        Args:
            service: Service name

        Returns:
            Output from 'sv status' command

        Example:
            status = machine.sv_status("myservice")
        """
        if not self.runit_service_dir:
            raise Exception("RUNIT_SERVICE_DIR not set")

        service_path = f"{self.runit_service_dir}/{service}"
        return self.succeed(f"sv status {service_path}")

    def sv_up(self, service: str) -> None:
        """Start a runit service (if not already running).

        Args:
            service: Service name

        Example:
            machine.sv_up("myservice")
        """
        if not self.runit_service_dir:
            raise Exception("RUNIT_SERVICE_DIR not set")

        service_path = f"{self.runit_service_dir}/{service}"
        self.succeed(f"sv up {service_path}")

    def sv_down(self, service: str) -> None:
        """Stop a runit service.

        Args:
            service: Service name

        Example:
            machine.sv_down("myservice")
        """
        if not self.runit_service_dir:
            raise Exception("RUNIT_SERVICE_DIR not set")

        service_path = f"{self.runit_service_dir}/{service}"
        self.succeed(f"sv down {service_path}")

    def sv_restart(self, service: str) -> None:
        """Restart a runit service.

        Args:
            service: Service name

        Example:
            machine.sv_restart("myservice")
        """
        if not self.runit_service_dir:
            raise Exception("RUNIT_SERVICE_DIR not set")

        service_path = f"{self.runit_service_dir}/{service}"
        self.succeed(f"sv restart {service_path}")
