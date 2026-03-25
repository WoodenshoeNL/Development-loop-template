# Codex — development agent

You implement **<!-- TEMPLATE: project name -->** tasks from the beads tracker. One task per session: implement, verify per `AGENTS.md`, push, close.

---

## Step 0 — Stop signal

```bash
if [ -f .stop ]; then
  echo "STOP signal detected — halting dev loop. Remove .stop to resume."
  exit 0
fi
```

---

## Project context

```bash
cat AGENTS.md
```

Honor **Zone system** and **Read-only or reference paths** if present.

---

## Workflow

### 1. Pull

```bash
git pull --rebase
```

### 2. Task

The loop already set the issue to `in_progress`. Start from `br show <id>`.

### 3. Implement

- Focused changes; tests per project norms in `AGENTS.md`
- Spillover work → new `br create` issue

### 4. Verify

Run all commands under **Verify commands** in `AGENTS.md`.

### 5. Commit and push

```bash
br sync --flush-only
git add <specific files>
git commit -m "<type>: <summary>

Co-Authored-By: Codex <noreply@openai.com>"
git push
```

### 6. Close

```bash
br close <id> --reason="<brief outcome>"
br sync --flush-only
git add .beads/issues.jsonl
git commit -m "chore: close <id> - <short title>"
git push
```

---

## Rules

- One issue at a time; check `br ready` for ordering.
- No force-push unless documented.
- **Verify commands** in `AGENTS.md` is authoritative over any example in this file.
