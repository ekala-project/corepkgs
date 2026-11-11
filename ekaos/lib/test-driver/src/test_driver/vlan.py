"""
Shared VDE switch connecting all test VMs (see lib/testing/vlan.nix)
"""

import os
import shutil
import subprocess
import tempfile
import time
from typing import Optional
from .logger import log


class VLan:
    def __init__(self, vde_switch: str):
        self.dir = tempfile.mkdtemp(prefix="ekaos-vlan-")
        self.socket = os.path.join(self.dir, "switch")
        log(f"Starting VDE switch at {self.socket}")
        # vde_switch reads management commands from stdin and exits on EOF,
        # so stdin stays an open pipe for the switch's lifetime.
        self.process = subprocess.Popen(
            [vde_switch, "-s", self.socket, "--dirmode", "0700"],
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        ctl = os.path.join(self.socket, "ctl")
        deadline = time.time() + 30
        while not os.path.exists(ctl):
            if self.process.poll() is not None:
                raise Exception(
                    f"vde_switch exited with status {self.process.returncode}"
                )
            if time.time() > deadline:
                raise Exception("Timeout waiting for vde_switch")
            time.sleep(0.1)

    def stop(self) -> None:
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
        shutil.rmtree(self.dir, ignore_errors=True)


_vlan: Optional[VLan] = None


def vlan_socket() -> Optional[str]:
    """Socket of the shared switch, started on first use; None if unavailable"""
    global _vlan
    vde_switch = os.environ.get("EKAOS_TEST_VDE_SWITCH")
    if not vde_switch:
        return None
    if _vlan is None:
        _vlan = VLan(vde_switch)
    return _vlan.socket


def stop_vlan() -> None:
    global _vlan
    if _vlan is not None:
        _vlan.stop()
        _vlan = None
