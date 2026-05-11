"""
ekaosTest Driver
Python test driver for ekaos systems
"""

from .machine import Machine
from .logger import log, log_error, log_warning, log_success

__all__ = [
    "Machine",
    "register_machine",
    "start_all",
    "subtest",
    "log",
    "log_error",
    "log_warning",
    "log_success",
]

# Global list of machines
_machines = []


def register_machine(machine: Machine) -> None:
    """Register a machine for start_all()"""
    _machines.append(machine)


def start_all() -> None:
    """Start all registered machines"""
    log("Starting all machines")
    for machine in _machines:
        machine.start()
    log("All machines started")


def shutdown_all() -> None:
    """Shutdown all machines"""
    log("Shutting down all machines")
    for machine in _machines:
        try:
            machine.shutdown()
        except Exception as e:
            log_error(f"Error shutting down {machine.name}: {e}")


class subtest:
    """Context manager for grouping test sections"""

    def __init__(self, name: str):
        self.name = name

    def __enter__(self):
        log(f"=== Subtest: {self.name} ===")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is None:
            log_success(f"=== Subtest '{self.name}' passed ===")
        else:
            log_error(f"=== Subtest '{self.name}' failed ===")
        return False  # Don't suppress exceptions
