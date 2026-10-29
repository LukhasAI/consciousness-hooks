#!/usr/bin/env bash
set -euo pipefail

# Uses the real installer inside an isolated throwaway Git repository.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash -n "$ROOT/install-interactive-hooks.sh"
bash -n "$ROOT/interactive-hook-framework.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git init -q "$TMP/repo"

cd "$TMP/repo"
bash "$ROOT/install-interactive-hooks.sh" --help > "$TMP/help"
grep -q -- '--auto' "$TMP/help"

if bash "$ROOT/install-interactive-hooks.sh" --auto > "$TMP/auto.log" 2>&1; then
  echo "Unexpected success: required hook files are absent" >&2
  exit 1
fi
grep -q 'Missing hook source:' "$TMP/auto.log"
test ! -e .git/hooks/interactive-hook-framework.sh
test ! -e .git/hooks/interactive-hook.conf
test ! -e .git/hooks/pre-commit

if bash "$ROOT/install-interactive-hooks.sh" --auto --type=unrecognised > "$TMP/unknown.log" 2>&1; then
  echo "Unexpected success: unrecognised hook type" >&2
  exit 1
fi
grep -q 'Unknown hook type:' "$TMP/unknown.log"
test ! -e .git/hooks/interactive-hook-framework.sh
test ! -e .git/hooks/interactive-hook.conf
test ! -e .git/hooks/pre-commit

echo "PASS: syntax, help, missing-source preflight and unknown-type refusal (real Git repo)"
