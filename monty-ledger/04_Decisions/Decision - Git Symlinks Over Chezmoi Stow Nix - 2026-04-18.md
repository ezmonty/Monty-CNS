---
type: decision
status: active
created: 2026-04-18
tags: [decision, dotfiles, infrastructure, architecture]
confidence: 3
access: private
truth_layer: working
role_mode: builder
persona_mix: [builder, pragmatist]
origin_type: ai-assisted
review_due: 2026-05-18
---
# Decision — Git+Symlinks Over Chezmoi, Stow, and Nix

## Context

Dotfiles need to be version-controlled and deployed to multiple
machines. Several mature tools exist for this. This decision was
pragmatic — not a formal evaluation but a conscious choice to start
simple and upgrade only if needed.

## Alternatives considered

| Tool | Approach | Why not |
|---|---|---|
| **chezmoi** | Template-based, generates files from sources | Adds templating layer, learning curve, tool dependency |
| **GNU stow** | Symlink-based (similar to ours) | Extra dependency for what ~180 lines of bash already does |
| **Nix Home Manager** | Declarative, reproducible builds | Heavy infrastructure for a single-user dotfiles system |

## Chosen path

**Raw git + symlinks via bootstrap.sh (~180 lines of bash).**

Why this works:
1. **Simplest mental model** — a symlink is a live reference, not a
   generated copy. Edit the file, the change is live everywhere.
2. **No additional tooling** — git is universal, bash is universal.
3. **Auditable** — the entire deployment logic fits in one script.
4. **Merge-mode for directories** — symlink children individually so
   tracked files and local-only files coexist in the same directory
   (e.g. `~/.config/fish/` has both tracked and untracked files).

## Tradeoffs accepted

- **No templating** — cannot generate machine-specific configs from
  templates (chezmoi can). Handled via conditional blocks in scripts.
- **No rollback beyond git** — Nix has atomic rollback. We rely on
  `git checkout` and manual intervention.
- **No dependency resolution** — install order is manual in bootstrap.
- **No formal evaluation** — this was a pragmatic starting point, not
  a researched decision. Acknowledged here for honesty.

These tradeoffs are acceptable for a single-user system.
