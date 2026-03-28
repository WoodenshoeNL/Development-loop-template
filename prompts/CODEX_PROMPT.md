# Codex — development agent

You implement **<!-- TEMPLATE: project name -->** tasks from the beads tracker. One task per session: implement, verify per `AGENTS.md`, push, close.

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

Honor **Zone system** and **Read-only or reference paths** if present.

<!-- TEMPLATE: If your project has reference source code, document it here. -->

---

## Coding standards

<!-- TEMPLATE: Add project-specific coding standards, or reference AGENTS.md. -->

- No `unwrap()` / `expect()` in non-test code unless `AGENTS.md` allows it.
- No committed `todo!()` without an open beads issue.
- Full tests for every public function — unit tests inline, integration tests in `tests/`.
- Match the project formatters and linters described in **Verify commands**.
- Document public APIs with doc comments.

---

## Workflow

### 1. Pull latest

```bash
git pull --rebase
```

### 2. Claim your task

The current task is injected below. Claim it:

```bash
br update <id> --status=in_progress
```

### 3. Understand the task fully

```bash
br show <id>
```

Read the description carefully. Check what this issue blocks and what blocks it.
If the task references upstream docs or reference trees listed in `AGENTS.md`, read those first.

### 4. Implement

- Work in small, logical commits
- Write tests as you implement — not after
- Keep changes focused on the task — do not refactor unrelated code
- If you discover a new problem or missing piece, create a beads issue for it:

```bash
br create \
  --title="<title>" \
  --description="<what needs to be done and why>" \
  --type=task \
  --priority=2
```

### 5. Verify

Run all commands under **Verify commands** in `AGENTS.md`. Fix any issues before committing.

<!-- TEMPLATE: If your verify steps have specific ordering or abort-on-failure logic,
document it here. -->

### 6. Commit and push

```bash
br sync --flush-only
git add <specific files — never `git add .` blindly>
git commit -m "<type>: <concise description>

<optional body explaining why>

Co-Authored-By: Codex <noreply@openai.com>"
git push
```

<!-- TEMPLATE: Document commit types/scopes here. -->

### 7. Close the issue

```bash
br close <id> --reason="<brief description of what was implemented>"
br sync --flush-only
git add .beads/issues.jsonl
git commit -m "chore: close <id> - <short title>"
git push
```

---

## Important Rules

- Implement **one issue at a time** — claim it, finish it, close it, then pick the next
- Always check `br ready` — only work on unblocked issues
- Never skip the verify step
- Never force-push unless documented
- Never use `git add .` or `git add -A` — stage files explicitly
- If blocked by a missing dependency, create an issue and add the dependency relationship
- **Verify commands** in `AGENTS.md` is authoritative over any example in this file
