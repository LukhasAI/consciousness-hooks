# Interactive Git Hooks — LUKHΛS AI

**Experimental developer tooling** for interactive Git hooks and a VS Code extension prototype.

> **Status:** source and examples are available, but this README does **not** certify that the installer, VS Code extension, or advertised workflows are currently tested, published or production-ready.

## Repository contents

| Path | Contents | Verification boundary |
| --- | --- | --- |
| [`interactive-hook-framework.sh`](interactive-hook-framework.sh) | Bash framework with interaction and file-handling functions | Source exists; no clean-environment behavior check is asserted |
| [`install-interactive-hooks.sh`](install-interactive-hooks.sh) | Shell installer scaffold | References hook source filenames that need reconciliation (see below) |
| [`examples/`](examples/) | Example hook templates | Templates may need adapting for a target repository |
| [`vscode-extension/`](vscode-extension/) | TypeScript VS Code extension source, manifest and supporting documentation | Presence of source and command declarations is not proof of marketplace publication or runtime correctness |

The VS Code extension manifest declares commands for opening a panel, running hooks, creating hooks, configuration and diff actions. Verify their implementation and supported VS Code versions independently before relying on these functions.

## Current installer limitation

At the inspected revision (25 October 2026), [`install-interactive-hooks.sh`](install-interactive-hooks.sh) references the following source files **relative to the repository root**:

- `tone-validation-hook.sh`
- `code-quality-hook.sh`
- `security-validation-hook.sh`

Those files were **not present at those root paths** in the inspected repository tree. The [`examples/`](examples/) directory contains a separate `code-quality-hook.sh` example, but that does not automatically satisfy the installer's expected path or the other missing files.

**Do not run the installer expecting a supported one-command installation.** Reconcile those paths, inspect side effects, and perform an isolated end-to-end test before publishing setup instructions.

## Inspect before trying the code

```bash
git clone https://github.com/LukhasAI/consciousness-hooks.git
cd consciousness-hooks
```

Review the shell scripts and [extension source](vscode-extension/src/) before running or packaging. Hooks execute in your development environment and can read or modify files. Do not rely on an experimental tool to enforce security rules or protect secrets without independent verification.

This README intentionally omits a Marketplace installation command: the repository contains extension metadata, but successful publication and availability were **not verified** in this documentation pass.

## Licence and provenance

The repository root did not contain a `LICENSE` file in the inspected tree. The [VS Code extension has its own licence file](vscode-extension/LICENSE), whose applicability to other repository files should not be assumed without confirmation. Public visibility alone does not grant permission to reuse code.

The project is independently developed; use of third-party tools does not imply their endorsement or partnership.

[Project website](https://lukhas.ai) · [LUKHΛS AI](https://github.com/LukhasAI)

---

*Source-only documentation audit: 25 October 2026. No installer execution, packaged-extension launch or Marketplace availability test has been claimed.*
