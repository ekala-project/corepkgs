"""Logging utilities for runit test driver."""

import sys
from typing import TextIO


class Logger:
    """Logger for test output with optional color support."""

    def __init__(self, output: TextIO = sys.stderr):
        """Initialize logger.

        Args:
            output: Output stream for log messages (default: stderr)
        """
        self.output = output
        self.use_color = output.isatty()
        self._subtest_depth = 0

    def log(self, message: str) -> None:
        """Log a message to the output stream.

        Args:
            message: Message to log
        """
        indent = "  " * self._subtest_depth
        if self.use_color:
            # Green color for success messages
            print(f"\033[32m{indent}{message}\033[0m", file=self.output)
        else:
            print(f"{indent}{message}", file=self.output)
        self.output.flush()

    def log_error(self, message: str) -> None:
        """Log an error message in red.

        Args:
            message: Error message to log
        """
        indent = "  " * self._subtest_depth
        if self.use_color:
            print(f"\033[31m{indent}{message}\033[0m", file=self.output)
        else:
            print(f"{indent}{message}", file=self.output)
        self.output.flush()

    def enter_subtest(self, name: str) -> None:
        """Enter a subtest context (increases indentation).

        Args:
            name: Name of the subtest
        """
        self.log(f">>> subtest: {name}")
        self._subtest_depth += 1

    def exit_subtest(self, name: str, success: bool) -> None:
        """Exit a subtest context (decreases indentation).

        Args:
            name: Name of the subtest
            success: Whether the subtest succeeded
        """
        self._subtest_depth -= 1
        if success:
            self.log(f"<<< subtest '{name}' succeeded")
        else:
            self.log_error(f"<<< subtest '{name}' failed")
