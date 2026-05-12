"""Test driver for running runit tests with Python scripts."""

import argparse
import sys
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Dict

from .logger import Logger
from .machine import RunitMachine


class TestDriver:
    """Main test driver for executing runit tests."""

    def __init__(self, testscript_path: str):
        """Initialize the test driver.

        Args:
            testscript_path: Path to the Python test script
        """
        self.testscript_path = testscript_path
        self.logger = Logger()
        self.machine = RunitMachine()
        self.test_failed = False

    @contextmanager
    def subtest(self, name: str):
        """Context manager for test sections with automatic success/failure logging.

        Args:
            name: Name of the subtest

        Example:
            with subtest("service startup"):
                machine.wait_for_open_port(8080)
        """
        self.logger.enter_subtest(name)
        success = False
        try:
            yield
            success = True
        except Exception as e:
            self.test_failed = True
            raise
        finally:
            self.logger.exit_subtest(name, success)

    def log(self, message: str) -> None:
        """Log a message to stderr.

        Args:
            message: Message to log
        """
        self.logger.log(message)

    def run(self) -> int:
        """Run the test script and return exit code.

        Returns:
            0 if test succeeds, 1 if test fails
        """
        # Load test script
        test_path = Path(self.testscript_path)
        if not test_path.exists():
            self.logger.log_error(f"Test script not found: {self.testscript_path}")
            return 1

        try:
            test_code = test_path.read_text()
        except Exception as e:
            self.logger.log_error(f"Failed to read test script: {e}")
            return 1

        # Compile test script
        try:
            compiled = compile(test_code, self.testscript_path, "exec")
        except SyntaxError as e:
            self.logger.log_error(f"Syntax error in test script: {e}")
            return 1

        # Prepare test environment (similar to nixosTests)
        test_symbols: Dict[str, Any] = {
            "machine": self.machine,
            "subtest": self.subtest,
            "log": self.log,
            # For compatibility with nixosTests idioms
            "Machine": RunitMachine,  # Type hint support
        }

        # Execute test script
        self.logger.log("=== Running test script ===")

        try:
            exec(compiled, test_symbols, None)
        except Exception as e:
            self.logger.log_error(f"Test failed with exception: {e}")
            import traceback
            traceback.print_exc(file=sys.stderr)
            return 1

        if self.test_failed:
            self.logger.log_error("=== Test failed ===")
            return 1

        self.logger.log("=== Test completed successfully ===")
        return 0


def main() -> None:
    """Main entry point for the test driver CLI."""
    parser = argparse.ArgumentParser(
        description="Runit test driver - Run Python test scripts for runitTests"
    )
    parser.add_argument(
        "--testscript",
        required=True,
        help="Path to the Python test script to execute",
    )

    args = parser.parse_args()

    driver = TestDriver(args.testscript)
    exit_code = driver.run()
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
