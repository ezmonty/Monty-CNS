# Monty-CNS

> Personal dotfiles for Claude Code (`~/.claude`) — settings, hooks, slash
> commands, skills, and MCP server configs — synced across every machine
> via git + symlinks. Self-hostable, single-user, no vendors.

**CNS** = *Claude Nervous System*. One repo to rule the fleet (laptop, desk,
work box, home server) so every Claude Code session everywhere starts from
the same baseline — and the moment you improve something on one machine, the
next session on every other machine picks it up.

## Status

| Item | State |
|---|---|
| Repo visibility | **private** — auth required; install path uses `git clone`, not `curl` |
| One-line install | `git clone <url> ~/src/Monty-CNS && ~/src/Monty-CNS/install.sh` (HTTPS / SSH / `gh` variants documented) |
| macOS double-click installer | `Install.command` — copy to Desktop, double-click |
| `/newmachine` slash command | Inside-session re-sync (bootstrap + secrets + MCP) |
| Install mechanism | `bootstrap.sh` (idempotent symlinks, merge-mode for dirs) |
| `SessionStart` hook | ✅ pulls repo, runs bootstrap, loads env, runs drop-ins |
| `PreCompact` hook | ✅ writes CHECKPOINT.md before context compaction |
| `Stop` hook | ✅ git-cleanliness nag |
| `PostToolUse` hook | ✅ syntax gate — auto-checks py/js/ts/go/rb/sh/json/yaml after edits |
| Universal `PreToolUse` hooks | ✅ protects secret files + blocks destructive Bash |
| Slash commands | **27** — generic workflow + notebook + `/newmachine` + `/worklog-merge` + `/learn` |
| Skills | **12** — generic library, cross-project |
| MCP servers tracked | **5** — github, filesystem, fetch, memory, brave-search |
| Monty-Ledger MCP | ✅ 7 tools, Postgres-backed, access-enforced |
| Plans infrastructure | ✅ `docs/plans/` — phased plans, worklogs, coordination protocol |
| Secrets (sops + age) | ✅ `activate-secrets.sh` one-command installer, tested end-to-end |
| Self-hosting guide | ✅ plain SSH git / Forgejo / Tailscale |

## Design principles

1. **Config, yes. State, no. Secrets, never.** The repo tracks portable
   configuration. Per-machine state (sessions, history, caches) stays
   local. Secrets live in a separate private repo, encrypted at rest.
2. **Symlinks, not copies.** Machines never have their own copy of
   anything. A `git pull` is all it takes to be up to date; the live
   running session sees the change immediately through the symlink.
3. **Merge, never replace.** `bootstrap.sh` refuses to clobber real
   directories. It recurses and symlinks children individually so tracked
   and machine-local files coexist in the same dir.
4. **No-op under uncertainty.** Every hook and drop-in degrades silently
   when its preconditions aren't met (sops missing, network down, secrets
   repo not cloned). A fresh machine runs exactly what's available.
5. **Cross-project by default.** Anything in `claude/` should be useful
   in any project. Project-specific work stays in that project's
   `.claude/` — Claude Code resolves project scope first, user scope second.
6. **Attribution over NIH.** Community-sourced content keeps its origin
   recorded in-file so you can always trace it back, update it, or
   replace it with the upstream.

## Layout

```
Monty-CNS/
├── README.md                          # you are here
├── install.sh                         # one-command new-machine installer
├── Install.command                    # macOS double-click wrapper around install.sh
├── bootstrap.sh                       # symlink installer — idempotent, merge-mode
├── activate-secrets.sh                # one-command sops+age setup, tested end-to-end
├── .gitignore                         # blocks secrets, session state, MCP runtime data
│
├── claude/                            # mirrors ~/.claude — tracked, portable files only
│   ├── settings.json                  # SessionStart + PreCompact + Stop + 2 PreToolUse hooks
│   ├── stop-hook-git-check.sh         # Stop hook: nag about uncommitted / unpushed work
│   ├── hooks/
│   │   ├── session-start.sh           # SessionStart hook: pull repo, run bootstrap, load env
│   │   ├── pre-compact-checkpoint.sh  # PreCompact hook: write CHECKPOINT.md before compaction
│   │   └── session-start.d/
│   │       ├── 10-decrypt-sops.sh     # drop-in: decrypt sops secrets into $CLAUDE_ENV_FILE
│   │       └── README.md              # drop-in conventions + stubs for pass / sops
│   ├── agents/                        # (empty; for subagent definitions)
│   ├── commands/                      # slash commands (27 — see below)
│   ├── skills/                        # cross-project skill library (12 — see below)
│   │   ├── README.md                  # library philosophy + community mining workflow
│   │   └── distributed-worklog/       # parallel subagent worklog pattern (ported from Valor)
│   └── mcp/                           # MCP server definitions
│       ├── README.md                  # portable MCP config conventions
│       ├── install-servers.sh         # reads servers/*.json + runs claude mcp add
│       └── servers/
│           ├── github.json
│           ├── filesystem.json
│           ├── fetch.json
│           ├── memory.json            # knowledge-graph memory (local JSON store)
│           └── brave-search.json      # Brave web search (needs API key)
│
├── scaffold/
│   └── secrets-repo/                  # ready-to-copy contents for Monty-CNS-Secrets
│       ├── README.md                  # private-repo walkthrough
│       ├── .sops.yaml                 # sops recipient template
│       ├── .gitignore                 # blocks plaintext from sneaking in
│       ├── env.sops.yaml.example      # example env bundle
│       └── mcp/.gitkeep
│
└── docs/
    ├── self-hosting.md                # plain SSH git / Forgejo / Tailscale options
    ├── secrets.md                     # secrets strategy (the "why")
    ├── secrets-setup.md               # sops + age walkthrough (the "how")
    ├── migration-valor2.md            # audit log of what moved from valor2.0 and why
    ├── security/                      # security posture — threat model, playbook, classification
    │   ├── README.md                  # index
    │   ├── threat-model.md            # what CNS protects, what it doesn't
    │   ├── classification.md          # Public / Internal / Confidential / Restricted
    │   ├── where-data-lives.md        # decision tree: git, secret manager, or DB
    │   ├── disk-encryption.md         # FileVault / BitLocker / LUKS — mandatory
    │   ├── compromise-playbook.md     # incident response checklist
    │   ├── actor-model.md             # five-actor taxonomy for trust boundaries
    │   ├── github-auth.md             # GitHub App auth flow security analysis
    │   └── valor-scope.md             # why CNS is NOT for Valor's customer data
    └── plans/                         # phased implementation plans + coordination
        ├── README.md                  # plan conventions, task claim protocol, worklog format
        ├── valor/                     # Valor-specific (transfer pending to valor2.0)
        │   ├── valor-github-integration.md      # GitHub App plan (2,440 lines)
        │   ├── valor-github-integration-runbook.md
        │   ├── valor-github-integration-postmortem-template.md
        │   ├── phase-0-checklist.sh
        │   └── phase-0-human-ops.md
        └── worklogs/                  # append-only work journals
```

## Install on a new machine

`Monty-CNS` is a **private repo**, so the install path uses `git clone`
(authenticated) instead of `curl | bash` (anonymous, which would 404 for
private repos).

### One-liner (HTTPS + git credential manager)

```bash
git clone https://github.com/ezmonty/Monty-CNS.git ~/src/Monty-CNS && ~/src/Monty-CNS/install.sh
```

That's the whole thing. The first time you run it on a new Mac, your git
credential helper pops up to ask for GitHub auth (PAT or browser flow). It
caches after that, so every subsequent machine is one paste with no
interaction. After clone, `install.sh` runs and:

1. Detects the repo is already there → skips clone
2. Runs `bootstrap.sh` (symlinks under `~/.claude`)
3. Asks if you want to activate secrets (sops + age)
4. Asks if you want to install tracked MCP servers
5. Reports next steps

### One-liner (SSH, if you have a key set up)

```bash
git clone git@github.com:ezmonty/Monty-CNS.git ~/src/Monty-CNS && ~/src/Monty-CNS/install.sh
```

Same flow, faster auth (no credential prompt at all if your SSH agent has
the key loaded).

### One-liner (`gh` CLI, easiest browser auth)

If you'd rather not deal with PATs or SSH keys, use the GitHub CLI:

```bash
brew install gh                                # one-time, only if you don't have it
gh auth login                                  # one-time, browser-based
gh repo clone ezmonty/Monty-CNS ~/src/Monty-CNS && ~/src/Monty-CNS/install.sh
```

`gh auth login` does a browser handshake — no token to paste, no SSH key
to generate. After it's done once on a machine, it's cached forever.

### Codespaces / cloud dev environments

Codespaces have github auth pre-configured. Just paste:

```bash
git clone https://github.com/ezmonty/Monty-CNS.git ~/src/Monty-CNS && ~/src/Monty-CNS/install.sh
```

No credential prompts, no setup.

### Manual — individual phases

Each phase script is idempotent and can be run on its own if the one-liner
aborted partway, or you just want to rerun one step:

```bash
git clone https://github.com/ezmonty/Monty-CNS.git ~/src/Monty-CNS
cd ~/src/Monty-CNS
./bootstrap.sh                    # (1) symlinks
./activate-secrets.sh             # (2) secrets
~/.claude/mcp/install-servers.sh  # (3) MCP servers
```

### Prerequisites

| Tool | Why | Get it |
|---|---|---|
| `git` | clone + push | macOS: `xcode-select --install` · Linux: package manager · pre-installed in codespaces |
| (one of) HTTPS PAT, SSH key, or `gh auth` | auth to private repo | github.com/settings/tokens, or `ssh-keygen + add to github`, or `brew install gh && gh auth login` |
| `bash` 4+ recommended (3.2 works) | run installer scripts | macOS ships 3.2; install 4+ via `brew install bash` if you want (not required) |

`install.sh` itself will tell you about anything else missing
(`sops`/`age`/`jq`/`claude`) when you reach the relevant phase.

**Preview any step without touching the machine:**

```bash
./bootstrap.sh --dry-run
./activate-secrets.sh --status
~/.claude/mcp/install-servers.sh --dry-run
~/.claude/mcp/install-servers.sh --list
```

Pre-existing files at conflicting paths are moved to
`~/.claude/backups/<timestamp>/`, never deleted. Directories that already
exist at the destination are merged (children symlinked individually)
rather than replaced, so you don't lose host-provided skills or local
experiments.

For deeper walkthroughs see [`docs/secrets-setup.md`](docs/secrets-setup.md)
(sops + age step-by-step) and [`claude/mcp/README.md`](claude/mcp/README.md)
(MCP server conventions).

## Update

```bash
cd ~/src/Monty-CNS && git pull && ./bootstrap.sh
```

The `SessionStart` hook runs this automatically on every new Claude Code
session, so manual updates are only needed if you want changes right now
without starting a new session.

## Uninstall

```bash
./bootstrap.sh --unlink
```

Removes every symlink that points into this repo. Leaves real
files/directories alone. Anything in `~/.claude/backups/` is preserved so
you can restore your pre-CNS state if you want.

## What ships in `claude/`

### Slash commands (27)

Each is a generic, project-agnostic workflow you can invoke with `/<name>`.
Project-level commands override these (by exact filename match) when you're
inside a project that defines its own `.claude/commands/<name>.md`.

| Command | Purpose |
|---|---|
| `/changelog` | Generate Keep-a-Changelog entries from git history, or lint Conventional Commits — prompt-only, no scripts |
| `/commit` | Staged-aware smart commit with secret-file exclusion, conventional format |
| `/debug` | Analyze + fix an error or bug |
| `/deps` | Audit deps for CVEs, outdated versions, weak pinning |
| `/docs` | Generate/update docstrings, JSDoc, API docs |
| `/explain` | Deep-dive explanation of the target code |
| `/explore` | Forked-context codebase exploration via subagent |
| `/feature` | Feature end-to-end: plan → implement → test → PR-ready |
| `/fix-issue` | Close a GitHub issue: read → find → fix → test → commit |
| `/learn` | Capture a verified, generalizable finding into persistent LEARNINGS.md knowledge base |
| `/migrate` | DB schema / data / dependency migrations |
| `/newmachine` | Inside-session re-sync: pull dotfiles, run bootstrap, activate secrets, install MCP |
| `/note` | Quick capture to `NOTES.md` (project-scoped or `$HOME`) |
| `/note-review` | Progressive summarization of captured notes |
| `/pr` | Create a well-structured PR with quality checklist |
| `/pre-commit` | Tests + lint + build + secrets scan before commit |
| `/refactor` | Safe refactor with test verification at each step |
| `/review` | Bug / security / perf / style review |
| `/security-audit` | Focused security audit |
| `/tdd` | Test-driven development — failing test first, then impl |
| `/worklog-merge` | Merge distributed worklog scratch files into master worklog |
| `/write-tests` | Write tests matching the project's existing patterns |

### Skills library (12)

Cross-project skills — loaded into context automatically when the model
decides they're relevant. See [`claude/skills/README.md`](claude/skills/README.md)
for the library philosophy and how to add more.

| Skill | Purpose | Origin |
|---|---|---|
| `adversarial-reviewer` | 3-persona hostile review (Saboteur / New Hire / Security) — breaks LLM self-review | Upstream: `alirezarezvani/claude-skills` (MIT, ekreloff). Adapted. |
| `code-style` | Naming / structure / anti-patterns across Python, TS, Go, Rust | Rewritten from valor2.0 |
| `distributed-worklog` | Parallel subagent scratch files → atomic merge pattern | Ported from valor2.0 Plan A |
| `error-helper` | Systematic error triage with language-specific first-aid | Rewritten from valor2.0 |
| `explore-codebase` | Deep investigation via forked `Explore` subagent | Rewritten from valor2.0 |
| `git-guide` | Git workflows, conflict resolution, recovery, safety | Rewritten from valor2.0 |
| `h-scale` | Capability Honesty Scale H1–H5 for rating readiness | Rewritten from valor2.0 |
| `karpathy-principles` | The 4 coding principles (Think / Simple / Surgical / Goals) | CNS original, attributed to Karpathy |
| `monty-ecosystem` | Monty architecture: 4 repos, 4 categories, merge semantics, wiring | CNS original |
| `perf-audit` | Backend + frontend + DB perf checklist with measurement-first | Rewritten from valor2.0 |
| `test-writer` | Framework detection, layer selection, multi-lang templates | Rewritten from valor2.0 |
| `vault-access-model` | Monty-Ledger vault access patterns and trust boundaries | CNS original |

### Hooks

| Event | Hook | What it does |
|---|---|---|
| `SessionStart` | `claude/hooks/session-start.sh` | async: `git pull` the dotfiles repo (10 s timeout), run `bootstrap.sh`, load `~/.claude/.env.local` into `$CLAUDE_ENV_FILE`, run every `session-start.d/*.sh` drop-in |
| `SessionStart` drop-in | `claude/hooks/session-start.d/10-decrypt-sops.sh` | No-op unless `sops` + `age` + `~/src/Monty-CNS-Secrets` are all present. Decrypts `env.sops.yaml` into `$CLAUDE_ENV_FILE` and any file-based secrets into `~/.claude/mcp/keys/` (0600). |
| `PreToolUse` | inline in `settings.json` | Block writes to `.env*`, `credentials`, `secrets`, `.pem`, `.key`. Block `git push --force`, `git reset --hard`, `rm -rf`, `DROP TABLE` in Bash. |
| `PostToolUse` | `claude/hooks/post-tool-syntax-check.sh` | After Edit/Write, auto-runs syntax check for the file's language (py_compile, node --check, bash -n, go vet, etc). Warns on failure, never blocks. |
| `PreCompact` | `claude/hooks/pre-compact-checkpoint.sh` | Write structured `CHECKPOINT.md` (branch, HEAD, recent commits, current task) before context compaction so the next session can resume. Always exits 0. Ported from Valor Plan A. |
| `Stop` | `claude/stop-hook-git-check.sh` | Nag about uncommitted / untracked / unpushed work before the session ends |

### Settings & permissions

`claude/settings.json` registers the hooks above plus `permissions.allow: ["Skill"]`. Project-level settings compose on top — this is the universal floor.

## What's never committed

Blocked by `.gitignore`:

- `.credentials.json` — Claude Code OAuth tokens, machine-scoped, never sync
- `.env` / `.env.*` — secrets in plaintext
- SSH / GPG / age private keys
- `projects/`, `sessions/`, `session-env/`, `todos/`, `statsig/`, `shell-snapshots/`, `backups/`, `.claude.json` — per-machine runtime state
- MCP runtime state: sqlite caches, `node_modules`, sockets, log files

Slogan: **Config, yes. State, no. Secrets, never.**

## Self-hosting the remote

Three options in [`docs/self-hosting.md`](docs/self-hosting.md), all sized
for a single-box rack:

1. **Plain `git` over SSH** — zero services, just `git init --bare`
2. **Forgejo / Gitea** in a single Docker container — web UI, issues, CI
3. **Tailscale-fronted** — either of the above, never exposed to the
   public internet

Each option explains SSH key hygiene (one key per machine) and sync
strategies (manual / cron / git post-receive webhook).

## Secrets: the two-repo pattern

- `Monty-CNS` (this repo) — config, always encryptable-at-rest safe
- `Monty-CNS-Secrets` (separate **private** repo) — ciphertext-only

Glue: the `SessionStart` → `10-decrypt-sops.sh` drop-in. See
[`docs/secrets.md`](docs/secrets.md) for the "why" (sops+age vs pass vs
keychain comparison and recommendation) and
[`docs/secrets-setup.md`](docs/secrets-setup.md) for the "how"
(step-by-step installation including first-machine seed and multi-machine
onboarding). The ready-to-push scaffold is at
[`scaffold/secrets-repo/`](scaffold/secrets-repo/).

## Contributing (to your own CNS)

1. **New command.** Drop a markdown file in `claude/commands/<name>.md`
   with YAML frontmatter (`description:`). Commit, push.
2. **New skill.** Create `claude/skills/<name>/SKILL.md` with frontmatter
   (`name:`, `description:`, optionally `context:`, `agent:`,
   `user_invocable:`). Commit, push.
3. **New hook.** Add the logic to `claude/settings.json` (inline) or drop
   an executable script in `claude/hooks/session-start.d/` for a
   SessionStart concern. The main hook picks it up automatically.
4. **Mining community skills.** See the workflow in
   [`claude/skills/README.md`](claude/skills/README.md) — clone upstream,
   check license, safety-review, copy with attribution, commit with an
   upstream reference.

Every machine picks up changes on next session via the `SessionStart`
hook, or manually with `git pull && ./bootstrap.sh`.

## Plans and cross-repo coordination

`docs/plans/` holds phased implementation plans for work that spans
multiple milestones. Each plan has its own worklog, coordination
protocol, and phase-gated exit criteria. See
[`docs/plans/README.md`](docs/plans/README.md) for the full
conventions (task claim protocol, worklog format, handoff, conflict
resolution).

### Active plans

| Plan | Status | Target |
|---|---|---|
| [Valor GitHub Integration](docs/plans/valor-github-integration.md) | Transfer pending to valor2.0 | GitHub App for automated PR reviews, Remedy as customer zero |

### Valor 2.0 bridge

CNS and [valor2.0](https://github.com/ezmonty/valor2.0) are
connected via Claude Code's merge semantics: project-level
`.claude/` overrides the global `~/.claude/` that CNS manages.
Valor's `BRIDGE_CONTRACT.md` (PR #6, commit 91d7b77) defines the
shared interface across three bridges:

1. **Env vars** — CNS decrypts sops secrets → `.env.local` →
   `$CLAUDE_ENV_FILE` → Valor agents read `os.environ`
2. **Claude Code merge** — Valor's project-specific `/review`,
   `/pre-commit` override CNS's generic versions
3. **MontyCore /ask** — Valor's 53 agents communicate via
   `MontyClient.ask()`; the GitHub App plan adds a
   `GitHubWebhookAgent` (port 8151)

Two patterns were ported **from Valor back to CNS** for
cross-project reuse:

- `PreCompact` checkpoint hook — session state preservation
- `distributed-worklog` skill + `/worklog-merge` command — parallel
  subagent coordination without merge conflicts

## Acknowledgements

Content in this repo comes from several sources. Attribution is preserved
in each file as a top-of-file comment where applicable.

- **[valor2.0](https://github.com/ezmonty/valor2.0)** — Personal project
  whose `.claude/global-commands/` and `.claude/skills/` seeded the first
  two rounds of consolidation. See
  [`docs/migration-valor2.md`](docs/migration-valor2.md) for the full
  audit log.
- **[alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills)**
  (MIT) — Source of the `adversarial-reviewer` skill (author: ekreloff).
  Recommended as a starting point when mining more community skills.
- **Andrej Karpathy** —
  [Tweet](https://x.com/karpathy/status/2015883857489522876) on LLM
  coding pitfalls that inspired the `karpathy-principles` skill.
- **[Claude Code skills docs](https://code.claude.com/docs/en/skills)** —
  Canonical `SKILL.md` format and conventions.

Additional community skill libraries worth mining (review each before
adopting — quality varies):

- [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills)
- [sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) (1,400+ skills, installer CLI)
- [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) (cross-tool)
- [BehiSecc/awesome-claude-skills](https://github.com/BehiSecc/awesome-claude-skills)

## License

Personal dotfiles, currently unlicensed (all rights reserved by default).
If you want to share or extend this repo, pick an explicit license first —
MIT or Apache-2.0 are the usual choices for dotfiles.

Content adapted from external sources retains its upstream license (MIT in
every current case). Attribution is in the top comment of each affected
file.
