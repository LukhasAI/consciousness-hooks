# Git hooks installer status

**Research status: incomplete. Do not rely on this for production enforcement.**

The published installer refers to root files named `tone-validation-hook.sh`, `code-quality-hook.sh`, and `security-validation-hook.sh`. Those files are absent at the expected locations. The template at `examples/code-quality-hook.sh` is not a drop-in equivalent.

The installer uses Bash associative arrays and therefore requires Bash 4+ (the default system Bash on many macOS versions is 3.2). This patch adds a deterministic preflight that **refuses** automated or interactive installation before changing Git hooks if required source files are absent. It does **not** make the installer operational.

The repository's GitHub Actions workflow `Hook installer safety` checks Bash syntax and uses the **real script** in a temporary `git init` repository to demonstrate fail-closed behavior, with no mocks. A passing test only establishes those negative cases, not installer success, VS Code functionality, or security-scanning coverage.

**Follow-up to graduate the installer:** implement and review the missing sources, define one composition policy for multiple selected hook types targeting the same hook file (current loop overwrites), review backup/rollback and shell safety, then verify successful end-to-end installation on clean macOS and Linux environments before changing installation guidance.

This document is evidence-scoped to the repository snapshot reviewed 29 October 2026.