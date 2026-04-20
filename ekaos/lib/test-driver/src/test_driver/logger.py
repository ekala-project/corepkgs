"""
Simple logging for ekaosTest
"""

import sys
from datetime import datetime


def log(message: str, level: str = "INFO") -> None:
    """Log a message with timestamp"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] [{level}] {message}", file=sys.stderr, flush=True)


def log_error(message: str) -> None:
    """Log an error message"""
    log(message, level="ERROR")


def log_warning(message: str) -> None:
    """Log a warning message"""
    log(message, level="WARNING")


def log_success(message: str) -> None:
    """Log a success message"""
    log(message, level="SUCCESS")
