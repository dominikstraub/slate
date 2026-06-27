# Slate developer tooling. Run `make` (or `make help`) for the target list.
#
# Formatting/linting is built on clang-format (formatter, in the pre-commit
# hook) plus optional clang-tidy and the Clang Static Analyzer (manual). See
# CLAUDE.md > Build & Test for the full story.

SHELL := /bin/bash

SCHEME       := Slate
DEST         := platform=macOS
CLANG_FORMAT := $(shell xcrun -f clang-format 2>/dev/null)
# clang-tidy ships with Homebrew's keg-only `llvm`, so it is NOT on $PATH after
# `brew install llvm`. Prefer one on PATH, else fall back to the llvm keg.
CLANG_TIDY   := $(shell command -v clang-tidy 2>/dev/null || echo "$$(brew --prefix llvm 2>/dev/null)/bin/clang-tidy")
SRC          := $(shell find Slate -name '*.m' -o -name '*.h')

.DEFAULT_GOAL := help
.PHONY: help setup format format-check format-all compile-db tidy analyze test

help: ## Show this help
	@echo "Slate make targets:"
	@awk 'BEGIN{FS=":.*##"} /^[a-zA-Z_-]+:.*##/{printf "  \033[36m%-13s\033[0m %s\n",$$1,$$2}' $(MAKEFILE_LIST)

setup: ## Install the pre-commit hook + ensure git-clang-format
	git config core.hooksPath .githooks
	@if git clang-format -h >/dev/null 2>&1; then \
	  echo "git clang-format: present"; \
	elif command -v brew >/dev/null 2>&1; then \
	  echo "Installing git clang-format via Homebrew..."; \
	  brew install clang-format || echo "warning: install failed; the hook fails-open until 'git clang-format' is available."; \
	else \
	  echo "warning: Homebrew not found. Install 'git clang-format' manually; the hook fails-open until then."; \
	fi
	@echo "Pre-commit hook active (core.hooksPath=.githooks)."

format: ## Format staged changed lines (clang-format)
	@scripts/format.sh fix

format-check: ## Check staged changed lines are formatted (what the hook runs)
	@scripts/format.sh check

format-all: ## Reformat ALL .m/.h files in place — big-bang, never automatic
	@test -n "$(CLANG_FORMAT)" || { echo "clang-format not found (xcrun -f clang-format)"; exit 1; }
	"$(CLANG_FORMAT)" -i $(SRC)
	@echo "Reformatted $(words $(SRC)) files."

compile-db: ## Generate compile_commands.json for clang-tidy (best-effort)
	@command -v xcpretty >/dev/null 2>&1 || { echo "needs: gem install xcpretty (or use xcode-build-server)"; exit 1; }
	set -o pipefail; xcodebuild -scheme $(SCHEME) -destination '$(DEST)' clean build \
	  | xcpretty -r json-compilation-database --output compile_commands.json
	@# xcpretty records Apple clang's exact flags, which upstream clang-tidy
	@# can't parse (-index-store-path, -gmodules in @response-files, etc.).
	@# Strip them so `make tidy` works against a Homebrew/LLVM clang-tidy.
	python3 scripts/sanitize-compile-db.py compile_commands.json
	@echo "Wrote compile_commands.json"

tidy: ## Run clang-tidy (best-effort; needs compile_commands.json + brew install llvm)
	@test -x "$(CLANG_TIDY)" || { echo "needs: brew install llvm (clang-tidy not found on PATH or in the llvm keg)"; exit 1; }
	@test -f compile_commands.json || { echo "run 'make compile-db' first"; exit 1; }
	"$(CLANG_TIDY)" -p . $$(find Slate -name '*.m')

analyze: ## Run the Clang Static Analyzer via xcodebuild
	xcodebuild analyze -scheme $(SCHEME) -destination '$(DEST)'

test: ## Run the XCTest suite
	xcodebuild test -scheme $(SCHEME) -destination '$(DEST)'
