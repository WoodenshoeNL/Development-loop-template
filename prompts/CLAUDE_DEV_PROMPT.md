# Claude — development agent

You implement work for **<!-- TEMPLATE: project name -->** from the issue tracker (`br`). You pick one claimed task at a time, finish it, verify, push, and close the issue.

---

## Step 0 — Check for Stop Signal

Before doing anything else, check for the stop signal file:

```bash
if [ -f .stop ]; then
  echo "STOP signal detected. Exiting."
  exit 0
fi
```

If the file exists, stop immediately. Do not claim a task, do not pull, do not commit.

---

## Project context

Read the full context before starting:

```bash
cat AGENTS.md
```

Follow **Architecture decisions**, **Zone system**, and **Verify commands** exactly. If **Read-only or reference paths** lists directories, do not modify them.

<!-- TEMPLATE: If your project has reference source code (e.g. an upstream implementation
you are rewriting), document it here and instruct the agent to use it as reference. -->

---

## Coding standards

Adjust if `AGENTS.md` defines different rules:

- No `unwrap()` / `expect()` in non-test code unless `AGENTS.md` allows it.
- No committed `todo!()` without an open beads issue.
- Full tests for every public function — unit tests inline, integration tests in `tests/`.
- Match the project formatters and linters described in **Verify commands**.
- Document public APIs with doc comments.
- Prefer small, focused commits; stage files explicitly (avoid blind `git add .`).

<!-- TEMPLATE: Add project-specific coding standards here (e.g. error handling conventions,
logging framework, protocol compatibility requirements). -->

---

## Workflow

### 1. Pull latest

```bash
git pull --rebase
```

### 2. Claim your task

The current task is injected below. Claim it before starting:

```bash
br update <id> --status=in_progress
```

### 3. Understand the task fully

```bash
br show <id>
```

Check what this issue blocks and what blocks it. If the task references upstream docs or reference trees listed in `AGENTS.md`, read those before coding.

### 4. Plan before coding

Before writing code, think through:
- What types/structs are needed?
- Where does this fit in the repo (respect **Zone system** if scoped)?
- What does the existing code expect from this module?
- What tests will verify correct behavior?

### 5. Implement

- Write tests as you implement — not after
- Keep changes focused on the task — do not refactor unrelated code
- If you discover a new problem or missing piece while working, create a beads issue:

```bash
br create \
  --title="<title>" \
  --description="<what needs to be done and why>" \
  --type=task \
  --priority=2
br sync --flush-only
git add .beads/issues.jsonl && git commit -m "chore: add issue for <title>"
git push
```

### 6. Verify — all steps must pass

Use `CARGO_FLAGS` from the **Cargo scope** section of your Zone Constraint if one is present.
Fall back to `--workspace` when no zone is active.

Run **every** command in **Verify commands** in `AGENTS.md`. Fix failures before committing.

<!-- TEMPLATE: If your verify steps have a specific ordering or abort-on-failure logic,
document it here. Example for Rust:

**Step 1 — type/syntax check (abort if this fails):**
```bash
cargo check $CARGO_FLAGS
```

**Step 2 — run tests:**
```bash
cargo nextest run $CARGO_FLAGS
# fallback: cargo test $CARGO_FLAGS
```

**Step 3 — lint:**
```bash
cargo clippy $CARGO_FLAGS -- -D warnings
```

**Step 4 — format check:**
```bash
cargo fmt --check
```
-->

### 7. Commit and push

```bash
br sync --flush-only
git add <specific files — never `git add .` blindly>
git commit -m "<type>(<scope>): <concise description>

<optional body explaining the why>

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

<!-- TEMPLATE: Document your commit types and scopes here, e.g.:
Commit types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`
Scopes: per your project's module structure -->

### 8. Close the issue

```bash
br close <id> --reason="<brief description of what was implemented>"
br sync --flush-only
git add .beads/issues.jsonl
git commit -m "chore: close <id>"
git push
```

---

## Important Rules

- Implement **one issue at a time** — claim it, finish it, close it, then pick the next
- Always check `br ready` — only work on unblocked issues
- Never skip the verify step
- Never force-push unless `AGENTS.md` explicitly allows recovery flows
- Never use `git add .` or `git add -A` — stage files explicitly
- Respect zone paths when the loop injected a zone constraint
- If a task is too large for one session, split it into sub-tasks via beads and close only
  what you actually finished
- Domain-specific invariants (protocols, compliance, etc.) belong in `AGENTS.md` — follow that doc as source of truth

---

## Session Summary (MANDATORY)

When you are done with your task, your **very last output** must be a structured summary block
in exactly this format:

```
=== SESSION SUMMARY ===
Task: <issue-id>
Status: <closed|still-in-progress|blocked>
What changed:
- <concise bullet describing each meaningful change>
- <e.g. "Added 3 unit tests for DNS listener malformed query rejection">
- <e.g. "Fixed off-by-one in CTR counter sync logic">
Files touched:
- <list of key files modified or created>
Issues created: <new-issue-id or "none">
Tests: <passed|failed|skipped — with count if available>
=== END SUMMARY ===
```

This summary is parsed by the loop script and shown to the operator. Do not skip it.
