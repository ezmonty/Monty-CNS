---
type: retro
status: review
origin_type: ai-proposed
confidence: 3
access: private
truth_layer: working
tags: [retro, valor2.0, security, secrets-vault, egress-policy]
---

# Retro — Valor Secrets Vault + Egress Policy — 2026-05-01

## Accomplished

- Shipped a **Valor-native two-layer secret-handling system** end-to-end in one session:
  - Layer 1: `core/secret_intake.py` (11-kind regex catalog, ULID+HMAC handle, Fernet-encrypted vault) + `POST /secret/intake` on MontyCore + `secrets_vault` Postgres table (alembic `e6f7a8b9c0d1`).
  - Layer 2: `core/policy/egress_scrub.py` + `core/llm/provider_egress_gate.py` — every LLMToolAgent provider call gated by URL allowlist + scrubber + peppered HMAC audit log (`egress_scrub_log`).
  - `SecretInstallAgent` (port 8504) — perm-gated, atomic `.env` writes via `O_RDWR + flock`.
  - `~/.claude/hooks/secret-intake.sh` Claude Code shim, fail-closed.
  - `scripts/backscrub_claude_transcripts.py` retrofitting historical transcripts.
- Closed pre-existing P0 follow-ups: rotated OpenAI key into `.env`, audited GitHub forks (clean — repo private, 0 forks), scheduled mid-June backup-branch deletion via remote routine.
- Survived a brutal **adversarial review verdict: BLOCK** — fixed all 5 BLOCK + 6 CRITICAL + 5 WARNING findings (silent-fallback paths in egress gate, audit log swallow, weak peppers, SHA-vs-flock TOCTOU, dedup correctness, regex tightness). Then a `/review last` pass closed 3 MED + 6 LOW + 1 NIT findings on the fix commit itself.
- Activated the system live: nginx route added, shim hook turned on, `VALOR_EGRESS_FAIL_CLOSED=true` flipped, historical transcripts back-scrubbed (208 detections / 22 files after extending the script's record walker).
- Final state: **32/32 smoke pass on Postgres**, end-to-end intake working through the public `/api/console/secret/intake` route, hook + fail-closed both live.
- Stats: ~15 commits this session, 8+ files added, 4 alembic-related migrations referenced, 1 new agent + 1 new endpoint + 1 new audit table.

## Learned

1. **Silent-fallback paths are the exact thing an adversary will probe.** The first cut of LLMToolAgent had `_EGRESS_GATE_AVAILABLE = False` → `_provider_dispatch` falling through to a raw `client.post` if the gate module failed to import. That's a single ImportError away from being a no-op chokepoint. Lesson: when shipping a security control, every "fallback" branch is a bypass branch unless `RuntimeError` raised.

2. **Backscrubbing transcripts is harder than the regex pass.** Initial walker only handled `type=user` records. The same secret survived in `assistant.tool_use.input.command` (Bash commands containing the key as args), in `last-prompt` cache entries, and in `tool_result.content` blocks. Catching it required a recursive content-block walker. Lesson: transcript schema is wider than the obvious "user message" — assume any string-bearing field anywhere in the JSON can carry a secret.

3. **Detector catalog is a moving target.** The system caught typed-prefix secrets (`AKIA…`, `sk-proj-…`, `ghp_…`) and `KEY=VALUE` env-assignments, but a bare 64-hex token (`VALOR_API_KEY`) inside an unrelated context (e.g. nginx config in a transcript) is invisible. Generic high-entropy detection needs care — a git SHA is also 40-hex, a UUID is 32-hex. The pragmatic answer is to rotate keys you know are in transcripts rather than perfect the regex.

4. **Two distinct peppers > one.** Vault pepper (handle generation) ≠ log pepper (egress_scrub_log HMAC). Distinct values in env mean the egress audit log is non-invertible to vault entries even if both peppers are eventually exposed. Should be the default pattern any time you have "encrypted-at-rest content" + "audit log mentioning that content."

5. **Tests need explicit override APIs for env-driven globals.** When `VALOR_EGRESS_FAIL_CLOSED` flipped to true in production, three previously-passing tests broke because they implicitly assumed soft mode. Adding a `fail_closed_override=Optional[bool]` parameter to `scrub_for_egress` lets tests pin behavior independent of env. Same pattern should apply to any "global flag controls behavior" function.

6. **The backscrub script is destructive — keep `--apply` strictly opt-in.** The script defaults to `--dry-run`, requires `shred` binary at startup, and refuses `os.remove` fallback. Encryption-at-rest of the original happens before the shred. This is the right shape for an irreversible-by-design tool.

## Next time

- **Don't echo the secret in verification commands.** I ran `grep "sk-proj-iRq9aN" ~/.claude/projects/...` to verify scrubbing — every such grep gets recorded in the live transcript as a `tool_result`, which then needs scrubbing on the next pass. Use a checksum or partial prefix instead.
- **rsync isn't shred.** The backscrub workflow rsyncs to staging on valor-vm, runs there, rsyncs back. The original plaintext on bcdusa_llc gets overwritten by rsync, but disk blocks may persist. For a forensic-grade wipe, run shred locally on the bcdusa_llc paths after the staging round-trip. Document this caveat better.
- **nginx config edits via shell heredoc are footguns.** First attempt at adding the route munged newlines via sed; second attempt put the backup file in `sites-enabled/` which nginx parsed as a duplicate server block. Always: (a) edit via Python `read → modify → write`, (b) put backups OUTSIDE `sites-enabled`.
- **Settings.json is mode 777** on this CNS-installed machine — don't put secrets there. The pattern of `~/.claude/.valor-env` (mode 0600) sourced by the hook is cleaner. Apply this anywhere a hook needs a credential.
- **Adversarial review verdict was BLOCK on first pass.** I shipped the system as-was after self-review, then the dedicated adversarial agent caught five silent-fallback paths I'd missed. Lesson: spawn the adversarial review BEFORE declaring "done" — not after.
- **Detector regex on `env_assignment`** is the highest-FP-risk pattern. The first cut matched 16+ chars of value; tightened to 20+ chars + anchored LHS. Even so, this is the regex most likely to surface false positives on docstrings / placeholder strings. Watch the `egress_scrub_log` for raw_leak spikes.
- **What's still hanging:** detector gap on bare hex tokens; user-side OpenAI key revocation + billing spot-check; current-session `tool_result` capturing pre-scrub state (resolves on next backscrub).

## Session stats

- Commits this session (top of branch `main`): ~15 (8 feature/fix on the secrets system + 4 review/test follow-ups + 3 docs/worklog).
- Files added: ~12 (`core/secret_intake.py`, `core/storage/secrets_vault.py`, `core/storage/egress_scrub_log.py`, `core/policy/egress_scrub.py`, `core/llm/provider_egress_gate.py`, `agents/SecretInstallAgent.py`, `scripts/backscrub_claude_transcripts.py`, `~/.claude/hooks/secret-intake.sh`, `~/.claude/.valor-env`, `tests/smoke_secrets_vault_storage.py`, `tests/smoke_egress_scrub.py`, `tests/smoke_secret_install.py`, `tests/smoke_shim_failclosed.py`, `docs/m2codex/SECRETS_AND_EGRESS.md`).
- Files modified: ~6 (`agents/LLMToolAgent.py`, `core/monty_api.py`, `core/storage/_monolith.py`, `core/storage/__init__.py`, `configs/agent_processes.json`, `configs/agents.json`, `configs/roles.json`, `ui/construction-console/src/types/api.ts`, `ui/construction-console/src/api/valorApi.ts`).
- Tests: 32 new smoke tests (vault + egress + install + workstation regression). All pass on Postgres.
- Adversarial review pass: 5 BLOCK + 6 CRITICAL + 5 WARNING fixed. Self-review pass: 3 MED + 6 LOW + 1 NIT fixed.
- Backscrub: 208 detections across 22 transcript files, originals encrypted + shredded.
- Duration: ~5 hours of focused work (one session).
