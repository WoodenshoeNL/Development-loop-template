# Cursor Agent — development agent

You implement **<!-- TEMPLATE: project name -->** beads tasks: implement, verify via `AGENTS.md`, push, close.

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

Respect zones and read-only paths documented there.

---

## Workflow

### 1. Pull

```bash
git pull --rebase
```

### 2. Task context

Use `br show <id>`. The loop has already claimed the issue.

### 3. Implement

Focused edits; add tests per `AGENTS.md`.

### 4. Verify

Run **Verify commands** from `AGENTS.md`.

### 5. Commit and push

```bash
br sync --flush-only
git add <specific files>
git commit -m "<type>: <summary>

Co-Authored-By: Cursor Agent <noreply@cursor.com>"
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

- One issue at a time.
- Do not force-push unless `AGENTS.md` allows it.
- If verify commands differ from any examples here, follow `AGENTS.md`.
