#!/usr/bin/env python3
"""Bounded stock-Godot checks, with optional two-process ENet regression tests."""

import argparse
import os
from pathlib import Path
import re
import socket
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get("GODOT_BIN", "godot")
ERROR = re.compile(r"SCRIPT ERROR:|(?:^|\n)ERROR:|CHECK FAILED:|CHECKS_FAILED")


def verify(label, result, require_receipt=False):
    output = result.stdout
    if result.returncode or ERROR.search(output) or (require_receipt and "CHECKS_PASSED" not in output):
        raise RuntimeError(f"{label} failed:\n{output}")
    print(f"PASS: {label}")


def run(label, arguments, receipt=False):
    result = subprocess.run(
        [GODOT, "--headless", "--path", str(ROOT), *arguments],
        cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        timeout=90,
    )
    verify(label, result, receipt)


def network():
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    # Use the local harness temporary root when present, otherwise Python's default.
    parent = "/tmp/opencode" if Path("/tmp/opencode").is_dir() else None
    with tempfile.TemporaryDirectory(prefix="potion-check-", dir=parent) as directory:
        ready = Path(directory) / "ready"
        with (Path(directory) / "host.log").open("w+") as log:
            host = subprocess.Popen(
                [GODOT, "--headless", "--path", str(ROOT), "tests/runner.tscn", "--",
                 "--test-host", f"--port={port}", f"--ready-file={ready}"],
                cwd=ROOT, text=True, stdout=log, stderr=subprocess.STDOUT,
            )
            try:
                deadline = time.monotonic() + 10
                while not ready.exists():
                    if host.poll() is not None or time.monotonic() >= deadline:
                        log.seek(0)
                        raise RuntimeError("Host did not become ready:\n" + log.read())
                    time.sleep(0.05)
                for label in ("ENet client", "ENet rejoin"):
                    run(label, ["tests/runner.tscn", "--", "--test-client", f"--port={port}"], True)
                host.wait(timeout=15)
                log.seek(0)
                verify("ENet host convergence and disconnect", subprocess.CompletedProcess([], host.returncode, log.read()), True)
            finally:
                if host.poll() is None:
                    host.terminate()
                    try:
                        host.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        host.kill()
                        host.wait()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--network", action="store_true", help="also test host/client and rejoin")
    args = parser.parse_args()
    run("Godot import and script compilation", ["--editor", "--import"])
    run("main menu boot", ["--quit-after", "20"])
    run("menu mouse click", ["--script", "res://tests/menu_input.gd"], True)
    run("menu keyboard activation", ["--script", "res://tests/menu_input.gd", "--", "--keyboard"], True)
    run("menu-to-solo launch", ["--quit-after", "30", "--", "--solo"])
    run("direct shop scene (F6)", ["res://client/main.tscn", "--quit-after", "30"])
    run("shop rules, resource loading, and solo input", ["tests/runner.tscn"], True)
    if args.network:
        network()


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        raise SystemExit(str(error)) from error
