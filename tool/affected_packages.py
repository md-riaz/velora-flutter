#!/usr/bin/env python3
"""Prints, as a JSON array, the packages and examples a change affects.

Usage: tool/affected_packages.py <base-ref>     (e.g. origin/main)
       tool/affected_packages.py --all

A package is affected when a file inside it changed, or when a local package
it depends on (directly or transitively, including dev dependencies) is
affected. A change to CI workflows, tool/, or the root analysis options
affects everything. Markdown changes affect nothing.

CI uses the output as a job matrix, so a PR only analyzes and tests what it
can break.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(
    subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], text=True
    ).strip()
)
# Paths that change how every package is checked.
GLOBAL = (
    ".github/workflows/",
    "tool/affected_packages.py",
    "tool/check_baseline.sh",
    "tool/pub_get_all.sh",
    "analysis_options.yaml",
)


def packages():
    out = subprocess.check_output(
        ["git", "ls-files", "packages/*/pubspec.yaml", "examples/*/pubspec.yaml"],
        cwd=ROOT,
        text=True,
    )
    return sorted(str(Path(line).parent) for line in out.splitlines() if line)


def local_deps(package, known):
    """Local packages `package` depends on through `path:` entries."""
    text = (ROOT / package / "pubspec.yaml").read_text()
    deps = set()
    for match in re.finditer(r"^\s+path:\s*(\S+)\s*$", text, re.M):
        target = (ROOT / package / match.group(1)).resolve()
        try:
            relative = str(target.relative_to(ROOT))
        except ValueError:
            continue
        if relative in known:
            deps.add(relative)
    return deps


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    all_packages = packages()
    if sys.argv[1] == "--all":
        print(json.dumps(all_packages))
        return

    changed = subprocess.check_output(
        ["git", "diff", "--name-only", f"{sys.argv[1]}...HEAD"],
        cwd=ROOT,
        text=True,
    ).splitlines()
    # Markdown cannot break analysis or tests; tool/check_docs.sh covers it.
    changed = [path for path in changed if not path.endswith(".md")]
    if any(path.startswith(GLOBAL) for path in changed):
        print(json.dumps(all_packages))
        return

    known = set(all_packages)
    deps = {p: local_deps(p, known) for p in all_packages}
    affected = {
        p for p in all_packages if any(c.startswith(p + "/") for c in changed)
    }
    # Propagate to dependents until nothing new is added.
    grew = True
    while grew:
        grew = False
        for package in all_packages:
            if package not in affected and deps[package] & affected:
                affected.add(package)
                grew = True
    print(json.dumps(sorted(affected)))


if __name__ == "__main__":
    main()
