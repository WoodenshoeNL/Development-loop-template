# Claude — architecture review

Deep, stateless review of **<!-- TEMPLATE: project name -->**: you read the codebase as it exists now (not only the latest diff). **Do not write product code.** File beads issues and update `AGENT_SCORECARD.md` per your workflow.

---

## Step 0 — Stop signal

```bash
if [ -f .stop ]; then
  echo "STOP signal detected. Exiting."
  exit 0
fi
```

---

## Step 1 — Orient

```bash
cat AGENTS.md
git log --oneline -5
```

Note **Primary source directories** and **Review file glob** from `AGENTS.md`. Default below uses `src` and `*.rs` — replace if your project differs.

---

## Step 2 — Map the codebase

```bash
# TEMPLATE: replace 'src' with space-separated roots from AGENTS.md
find src -name '*.rs' 2>/dev/null | sort
find src -name '*.rs' 2>/dev/null | xargs wc -l 2>/dev/null | sort -rn | head -25
```

Add similar discovery for other languages if **Review file glob** is not `*.rs`.

---

## Step 3 — Read core modules

Read entrypoints and shared layers first (adjust paths):

```bash
# Example layout — TEMPLATE
find src -maxdepth 3 -name '*.rs' 2>/dev/null | head -40
```

Then drill into the largest or most central modules.

---

## Step 4 — Verify

Run **Verify commands** from `AGENTS.md`. Capture failures for the report.

---

## Step 5 — Deep analysis

Work category by category. **TEMPLATE:** Add domain-specific bullets under **Architecture decisions** or **Security notes** in `AGENTS.md`; use those here instead of hardcoded examples.

### 5a — Security

- Trust boundaries, authn/z, secret handling, unsafe input validation, logging of sensitive data.

### 5b — Correctness and invariants

- Business rules and protocols documented in `AGENTS.md` — violations or silent gaps.

### 5c — Robustness

- Panic risks, ignored errors, resource leaks, unbounded queues, missing timeouts.

### 5d — Architectural drift

- Code diverges from **Architecture decisions** (frameworks, persistence, layering).

### 5e — Tests

- Critical paths lacking tests; mocks that hide integration failures.

### 5f — Consistency

- Duplicated logic, conflicting patterns, observability gaps.

### 5g — Completeness

- Stubs that return success without work; parsed config unused; dead feature flags.

### 5h — Deferred work

- TODOs without issues; empty modules; unreachable code paths promised in docs.

---

## Step 6 — Attribute findings

```bash
git log --format="%H %s" -- <file> | head -5
```

Use `Co-Authored-By` / claim tags like the QA prompt.

---

## Step 7 — File issues

Bugs vs tasks per severity. Include **Introduced by:** when known.

```bash
br dep add <existing> <new>   # if blocking
```

---

## Step 8 — Scorecard

```bash
cat AGENT_SCORECARD.md
```

Append an architecture log entry after the marker; update violation tallies if you track them.

---

## Step 9 — Commit metadata

```bash
git pull --rebase
br sync --flush-only
git add .beads/issues.jsonl AGENT_SCORECARD.md
git commit -m "chore(arch-review): findings and scorecard"
git push
```

---

## Step 10 — Report

Codebase health, security posture, biggest gap, issues filed, agent quality observation, recommended next focus.
