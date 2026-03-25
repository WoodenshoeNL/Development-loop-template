# Agent instructions

<!-- Everything below marked TEMPLATE should be replaced during project design. See start.md. -->

## Goal

<!-- TEMPLATE: One paragraph — what this codebase is for and what "done" looks like for agents. -->

## Onboarding (new environment)

1. **Install `br`**:
   ```bash
   curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh" | bash
   ```
2. **Clone and run `./setup.sh`** — imports issues from `.beads/issues.jsonl` as needed.
3. **Verify**: `br ready` shows actionable work when issues exist.

## Architecture decisions

<!-- TEMPLATE: Replace with a real decision log. Remove unused rows. -->

| Concern | Decision |
|---------|----------|
| **Languages / runtime** | <!-- e.g. Rust 2024, Python 3.12 --> |
| **Repo layout** | <!-- e.g. `src/`, `crates/foo` --> |
| **Build / package** | <!-- e.g. cargo workspace, npm workspaces --> |
| **Tests** | <!-- unit vs integration, required coverage expectations --> |
| **Config / secrets** | <!-- where config lives; never commit secrets --> |
| **Logging / observability** | <!-- tracing, structured logs, metrics --> |

## Verify commands

<!-- TEMPLATE: Exact commands run before commit / in CI. Agents and prompts should match this list. -->

```bash
# Example (Rust) — replace if your stack differs:
# cargo check --workspace
# cargo test --workspace
# cargo clippy --workspace -- -D warnings
# cargo fmt --check
true
```

## Primary source directories (for review loops)

<!-- TEMPLATE: Top-level directories that contain production code (not vendored). Used by prompts for `find`/scans. Default template uses `src`. -->

- `src/`

**Review file glob** (for find/grep in prompts): <!-- TEMPLATE e.g. `*.rs`, `*.py` --> `*.rs`

## Zone system

Dev loops can scope work with `--zone <name>`. Each zone maps to path prefixes **that must match `ZONES` in `loop.py`.**

<!-- TEMPLATE: Edit zones and paths. Example for a single crate/repo: -->

| Zone | Paths | Beads label |
|------|-------|-------------|
| `main` | `src/` | `zone:main` |

### Zone rules

When `--zone` is set, only modify files under allowed paths for that zone. If work spans zones, open a beads issue with the appropriate `zone:<name>` label instead of editing outside the zone.

```bash
br create --title="..." --description="..." --type=task --priority=2
# then attach beads label zone:main per your br version (e.g. br update <id> --add-label zone:main)
```

## Read-only or reference paths

<!-- TEMPLATE: Optional — e.g. vendored reference code agents must not edit. Delete if not applicable. -->

*(None — document paths here if you add reference trees.)*

---

## Stopping a dev loop

Loops check for `.stop` at the repo root before each pass.

**Local:**

```bash
touch .stop
rm .stop
```

**Remote / shared:**

```bash
touch .stop && git add .stop && git commit -m "chore: stop dev loop" && git push
```

**Resume:** remove `.stop`, commit/push if you use it as a shared signal.

The `.stop` file is intentionally not gitignored so it can be pushed when needed.

<!-- br-agent-instructions-v1 -->

---

## Beads workflow integration

This project uses [beads_rust](https://github.com/Dicklesworthstone/beads_rust) (`br`/`bd`). Issues live under `.beads/` and sync via git.

### Essential commands

```bash
br ready
br list --status=open
br show <id>
br search "keyword"
br create --title="..." --description="..." --type=task --priority=2
br update <id> --status=in_progress
br close <id> --reason="Completed"
br sync --flush-only
br sync --status
```

### Session checklist (before end of session)

```bash
git status
git add <files>
br sync --flush-only
git commit -m "..."
git push
```

<!-- end-br-agent-instructions -->

---

## Landing the plane (session completion)

When ending work that should land on the remote:

1. File issues for follow-ups.
2. Run the **Verify commands** above if code changed.
3. Close or update beads issues.
4. Push:
   ```bash
   git pull --rebase
   br sync --flush-only
   git push
   git status
   ```
5. Hand off context for the next session if useful.

**Rule:** Do not declare the session done until required commits are pushed (or explicitly not applicable).
