# <!-- TEMPLATE: Project name -->

<!-- TEMPLATE: One-line description of what this repository is for. -->

This repository includes a **unified agent loop** (`loop.py`), **session bootstrap** (`setup.sh`), optional **machine provisioning** (`install.sh`), and **prompts** for autonomous dev and review agents. Issue tracking uses [beads_rust](https://github.com/Dicklesworthstone/beads_rust) (`br`).

If you are adopting this repo from the template, begin with **[start.md](./start.md)** to fill in project-specific details.

---

## Requirements

### Core

- **Git**
- **`br`** (beads) — [install script](https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh):
  ```bash
  curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh" | bash
  ```

### Agent loops (optional)

- **Claude Code CLI** — dev / review loops with `--agent claude`
- **Codex CLI** — `--agent codex`
- **Cursor Agent CLI** (`agent`) — `--agent cursor`

### Project runtime and build tools

<!-- TEMPLATE: List languages, package managers, databases, etc. Example:

- **Rust** (stable) — [rustup](https://rustup.rs)
- **Node.js** (LTS) — for frontend tooling

-->

See **Verify commands** in [AGENTS.md](./AGENTS.md) for the canonical build/test/lint steps.

---

## Getting started

### New machine / new session

```bash
git clone <!-- TEMPLATE: git@github.com:you/your-repo.git -->
cd <!-- TEMPLATE: your-repo -->
./setup.sh
```

`setup.sh` is idempotent: it checks tools, syncs git when clean, aligns the beads issue prefix with this project, refreshes the local beads database from `.beads/issues.jsonl`, and prints example `loop.py` commands.

<!-- TEMPLATE: Optional — document extra first-time steps (DB migrate, env files, secrets). -->

### Optional: system-level install (servers / CI images)

On Debian/Ubuntu, `install.sh` installs declared OS packages and other global dependencies. Edit that script for your stack before relying on it.

```bash
sudo ./install.sh
```

---

## `loop.py` — unified agent loops

Single entrypoint for development and review loops. Logs go to `logs/`.

### Loop types

| `--loop` | Role | Default sleep (if `--sleep` omitted) |
|----------|------|-------------------------------------|
| `dev` | Claim beads tasks, implement, push | `0` between tasks (internal backoff when idle) |
| `qa` | Review commits since last QA checkpoint; file issues | 20 minutes |
| `arch` | Full-codebase architecture review | 120 minutes |
| `quality` | Test *quality* deep dive (prompt-driven) | 30 minutes |
| `coverage` | Test *coverage* breadth scan (prompt-driven) | 30 minutes |

### Agents

| `--agent` | CLI invoked |
|-----------|-------------|
| `claude` | `claude` |
| `codex` | `codex exec` |
| `cursor` | `agent` |

### Examples

```bash
./loop.py --agent claude --loop dev
./loop.py --agent claude --loop dev --zone main
./loop.py --agent codex  --loop dev --zone main
./loop.py --agent cursor --loop dev --zone main
./loop.py --agent claude --loop dev --sleep 0 --iterations 1
./loop.py --agent codex  --loop qa
./loop.py --agent claude --loop arch --sleep 120 --jitter 15
./loop.py --agent claude --loop quality --zone main
./loop.py --agent cursor --loop coverage --iterations 3
```

Use `--zone` only with keys defined in `loop.py` and [AGENTS.md](./AGENTS.md). Omit `--zone` to work across all zones.

### Stopping loops

Create a `.stop` file in the repo root; each pass checks it before continuing.

```bash
touch .stop
rm .stop
```

For a remote runner, commit and push `.stop` so shared agents observe it (see [AGENTS.md](./AGENTS.md)).

### Prompt mapping

| Prompt file | Used for |
|-------------|----------|
| `prompts/CLAUDE_DEV_PROMPT.md` | Claude `dev` |
| `prompts/CODEX_PROMPT.md` | Codex `dev` |
| `prompts/CURSOR_PROMPT.md` | Cursor `dev` |
| `prompts/CLAUDE_PROMPT.md` | `qa` (all agents for that loop type) |
| `prompts/CLAUDE_ARCH_PROMPT.md` | `arch` |
| `prompts/CLAUDE_TEST_PROMPT.md` | `quality` |
| `prompts/CODEX_TEST_PROMPT.md` | `coverage` |
| `prompts/CODEX_QA_PROMPT.md` | Alternative QA wording if you wire a second agent |
| `prompts/CODEX_ARCH_PROMPT.md` | Alternative arch wording if you wire a second agent |

---

## Issue tracker (beads)

```bash
br ready
br show <id>
br create --title="..." --description="..." --type=task --priority=2
br update <id> --status=in_progress
br close <id> --reason="done"
br sync --flush-only
```

---

## Repository layout

<!-- TEMPLATE: Adjust directory names and descriptions. -->

```
.
├── AGENTS.md              # Agent rules, architecture, verify commands, zones
├── start.md               # Bootstrap checklist for new projects from this template
├── loop.py                # Unified dev / QA / arch / test loops
├── setup.sh               # Session start + beads sync
├── install.sh             # Optional OS-level dependencies (edit for your stack)
├── prompts/               # Loop prompts (customize per project)
├── .beads/
│   └── issues.jsonl       # Tracked issue export (commit after br sync)
├── logs/                  # Loop logs (typically gitignored)
└── <!-- TEMPLATE: src/, crates/, apps/, etc. -->
```

---

## Operator notes

<!-- TEMPLATE: License, security contact, contribution policy, or remove this section. -->
