#!/usr/bin/env bash
#
# Single source of truth for clang-format checking/fixing of *staged* changes.
# Used by both the pre-commit hook (.githooks/pre-commit) and `make format` /
# `make format-check`.
#
# Incremental: relies on `git clang-format`, which only touches the lines a
# commit actually changes (not whole files), so existing code stays untouched
# until edited.
#
# Usage:
#   scripts/format.sh check   # exit non-zero if staged .m/.h changes need formatting
#   scripts/format.sh fix     # reformat the staged changed lines in the working tree
#
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

cmd="${1:-check}"

# Pin to Xcode's clang-format so output is deterministic regardless of any
# (newer) Homebrew clang-format on $PATH. Fall back to PATH if xcrun can't help.
CF="$(xcrun -f clang-format 2>/dev/null || true)"
[ -n "$CF" ] || CF="$(command -v clang-format || true)"
if [ -z "$CF" ]; then
  echo "warning: clang-format not found; skipping format check." >&2
  exit 0  # fail-open: never block a commit just because tooling is missing
fi

# `git clang-format` (a Python subcommand) is not bundled with Xcode. If it's
# absent, fail-open with a hint — `make setup` is the supported install path.
if ! git clang-format -h >/dev/null 2>&1; then
  echo "warning: 'git clang-format' not installed; skipping format check." >&2
  echo "         Run 'make setup' (installs it via 'brew install clang-format')." >&2
  exit 0  # fail-open backstop
fi

case "$cmd" in
  check)
    # --diff prints a unified diff of what WOULD change (it does not modify
    # files). A real diff always carries '@@' hunk headers; the clean-tree
    # sentinels ("no modified files to format" / "clang-format did not modify
    # any files") and empty output do not — so '@@' is our reliable signal and
    # we don't depend on fragile sentinel strings or exit codes across versions.
    out="$(git clang-format --staged --diff --extensions m,h --binary "$CF" 2>/dev/null || true)"
    if printf '%s\n' "$out" | grep -q '^@@'; then
      echo "✖ Staged .m/.h changes are not clang-format clean:" >&2
      echo >&2
      printf '%s\n' "$out" >&2
      echo >&2
      echo "  Fix with:  make format   then 'git add' the files and commit again." >&2
      exit 1
    fi
    ;;
  fix)
    git clang-format --staged --extensions m,h --binary "$CF"
    echo "Formatted staged changed lines. Review, then 'git add' the result."
    ;;
  *)
    echo "usage: $0 {check|fix}" >&2
    exit 2
    ;;
esac
