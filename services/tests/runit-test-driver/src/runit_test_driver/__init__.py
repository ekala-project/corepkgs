"""Runit test driver - Python test bindings for runitTests.

This module provides Python test bindings similar to nixosTests/ekaosTests,
but adapted for local sandbox execution with runit supervision.

Example:
    machine.wait_for_open_port(8080)
    response = machine.succeed("curl http://localhost:8080")
    assert "expected" in response
"""

from .machine import RunitMachine
from .logger import Logger

__all__ = ["RunitMachine", "Logger"]
__version__ = "0.1.0"
