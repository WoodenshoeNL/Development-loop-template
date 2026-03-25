# Codex — architecture review

Independent architecture pass on **<!-- TEMPLATE: project name -->**. No feature code — issues + scorecard updates only (plus the commit in Step 9).

---

## Step 0 — Stop

```bash
test ! -f .stop || { echo "STOP"; exit 0; }
```

---

## Step 1 — Orient

```bash
cat AGENTS.md
git log --oneline -5
```

Use **Primary source directories** from `AGENTS.md` in the commands below (template uses `src/`).

---

## Step 2 — Map

```bash
find src -name '*.rs' 2>/dev/null | sort
find src -name '*.rs' 2>/dev/null | xargs wc -l 2>/dev/null | sort -rn | head -20
```

---

## Step 3 — Read hot spots

Read the most central or largest modules in full when practical.

---

## Step 4 — Verify

Run all **Verify commands** in `AGENTS.md`.

---

## Step 5 — Findings

Cover security, drift from `AGENTS.md`, error handling, tests, duplication, stubs, and missing functionality. **Add domain-specific checks only if they appear in `AGENTS.md`.**

---

## Step 6 — Attribution

Identify introducer per file via `git log -- <path>`.

---

## Step 7 — Issues

Create beads issues with clear repro/location; set priorities; link dependencies.

---

## Step 8 — Scorecard

Update `AGENT_SCORECARD.md` (arch section / append log).

---

## Step 9 — Commit

```bash
git pull --rebase
br sync --flush-only
git add .beads/issues.jsonl AGENT_SCORECARD.md
git commit -m "chore(arch-review): file findings and update agent scorecard"
git push
```

---

## Step 10 — Report

Health summary, top risks, IDs filed, next actions.
