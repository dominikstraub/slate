#!/usr/bin/env python3
#
# Make an Xcode-generated compile_commands.json consumable by an upstream
# (Homebrew) clang-tidy. Used by `make compile-db`.
#
# Why this is needed: xcpretty captures the EXACT command line Apple's Xcode
# clang was invoked with, and that command line is not portable to upstream
# LLVM's clang-tidy:
#   * Apple-only driver flags upstream clang rejects outright
#     (-index-store-path, -index-unit-output-path, -ivfsstatcache).
#   * -gmodules (often hidden inside an `@<file>.resp` response file) selects
#     the "obj" PCH/module-debug container, which a stock clang-tidy cannot read
#     -> "LLVM ERROR: unknown module format" crash.
#   * Dependency-/diagnostic-/output-generation flags (-MD, -MT, -MF, -c, -o,
#     --serialize-diagnostics) that only make sense while actually building.
#
# This script expands any `@response-file` references inline (so the flags
# inside them can be filtered too), drops the offending flags, and rewrites
# compile_commands.json in place.
#
# Usage: scripts/sanitize-compile-db.py [path/to/compile_commands.json]
#        (defaults to ./compile_commands.json)

import json
import os
import shlex
import sys

# Flags that consume the FOLLOWING token as their argument; drop both.
STRIP_WITH_ARG = {
    "-ivfsstatcache",
    "-index-store-path",
    "-index-unit-output-path",
    "-MF", "-MT", "-MQ", "-MJ",
    "--serialize-diagnostics", "-serialize-diagnostics",
    "-o",
}

# Standalone flags that take no argument; drop just the flag.
STRIP_FLAG = {
    "-gmodules",
    "-fmodule-format=obj",
    "-MD", "-MMD", "-M", "-MM", "-MG", "-MP",
    "-c",
}


def expand_response_files(tokens):
    """Inline the contents of any `@file` argument so its flags are filterable."""
    out = []
    for tok in tokens:
        if tok.startswith("@") and os.path.isfile(tok[1:]):
            with open(tok[1:]) as fh:
                out.extend(expand_response_files(shlex.split(fh.read())))
        else:
            out.append(tok)
    return out


def sanitize(command):
    tokens = expand_response_files(shlex.split(command))
    out = []
    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if tok in STRIP_WITH_ARG:
            i += 2
            continue
        if tok in STRIP_FLAG:
            i += 1
            continue
        out.append(tok)
        i += 1
    return " ".join(shlex.quote(t) for t in out)


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "compile_commands.json"
    with open(path) as fh:
        db = json.load(fh)
    for entry in db:
        if "command" in entry:
            entry["command"] = sanitize(entry["command"])
    with open(path, "w") as fh:
        json.dump(db, fh, indent=2)
    print(f"sanitized {len(db)} entries in {path} for upstream clang-tidy")


if __name__ == "__main__":
    main()
