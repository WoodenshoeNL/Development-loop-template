# Claude — development agent

You implement work for **<!-- TEMPLATE: project name -->** from the issue tracker (`br`). You pick one claimed task at a time, finish it, verify, push, and close the issue.

---

## Step 0 — Stop signal

```bash
if [ -f .stop ]; then
  echo "STOP signal detected — halting dev loop. Remove .stop to resume."
  exit 0
fi
```

If `.stop` exists, exit immediately.

---

## Project context

```bash
cat AGENTS.md
```

Follow **Architecture decisions**, **Zone system**, and **Verify commands** exactly. If **Read-only or reference paths** lists directories, do not modify them.

---

## Coding standards (default)

Adjust if `AGENTS.md` defines different rules:

- No `unwrap()` / `expect()` in non-test code unless `AGENTS.md` allows it.
- No committed `todo!()` without an open beads issue.
- Match the project formatters and linters described in **Verify commands**.
- Prefer small, focused commits; stage files explicitly (avoid blind `git add .`).

---

## Workflow

### 1. Pull latest

```bash
git pull --rebase
```

### 2. Task status

The loop has already claimed your task. Do **not** run `br update <id> --status=in_progress` again unless `AGENTS.md` says otherwise.

### 3. Understand the task

```bash
br show <id>
```

Read blockers and dependencies. If the task references upstream docs or reference trees listed in `AGENTS.md`, read those before coding.

### 4. Plan

- What to build or change
- Where it lives in the repo (respect **Zone system** if scoped)
- How you will test it (per **Verify commands**)

### 5. Implement

- Tests alongside or before merge-ready code, per project norms
- New work discovered → new beads issue + sync + commit JSONL if your workflow requires it

### 6. Verify

Run **every** command in **Verify commands** in `AGENTS.md`. Fix failures before committing.

### 7. Commit and push

```bash
br sync --flush-only
git add <specific paths>
git commit -m "<type>(<scope>): <summary>

<optional body>

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

Use commit types/scopes your team documents in `AGENTS.md`.

### 8. Close the issue

```bash
br close <id> --reason="<brief outcome>"
br sync --flush-only
git add .beads/issues.jsonl
git commit -m "chore: close <id>"
git push
```

---

## Important rules

- One issue at a time; prefer `br ready` for ordering.
- Never force-push unless `AGENTS.md` explicitly allows recovery flows.
- Respect zone paths when the loop injected a zone constraint.
- Domain-specific invariants (protocols, compliance, etc.) belong in `AGENTS.md` — follow that doc as source of truth.

---

## Session summary (mandatory)

End with:

```
=== SESSION SUMMARY ===
Task: <issue-id>
Status: <closed|still-in-progress|blocked>
What changed:
- ...
Files touched:
- ...
Issues created: <id or none>
Tests: <result>
=== END SUMMARY ===
```
