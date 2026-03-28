# Codex — architecture review

Independent architecture pass on **<!-- TEMPLATE: project name -->**. No feature code — issues + scorecard updates only (plus the commit in Step 9).

---

## Step 0 — Check for Stop Signal

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

---

## Step 2 — Map the Codebase

<!-- TEMPLATE: Replace 'src' and '*.rs' with your project's source roots and file patterns. -->

```bash
find src -name '*.rs' 2>/dev/null | sort
find src -name '*.rs' 2>/dev/null | xargs wc -l 2>/dev/null | sort -rn | head -20
```

---

## Step 3 — Read Core Files

Read entrypoints, shared type definitions, and security-sensitive modules in full first.
Then read remaining source files and integration tests.

<!-- TEMPLATE: List your tier-1 files here for quick reference. -->

---

## Step 4 — Build and Test

Run all **Verify commands** in `AGENTS.md`.

<!-- TEMPLATE: If your verify has sub-steps with abort logic, document them here. -->

Note every warning, error, and test failure.

---

## Step 5 — Deep Analysis

For each finding, note the exact file and line.

### 5a — Security

- Trust boundaries, authn/z, secret handling, input validation, logging of sensitive data.
- Integer overflow: are casts from untrusted data guarded?
- Denial of service: can untrusted input cause unbounded memory growth?
- Timing attacks: are secret comparisons constant-time?

<!-- TEMPLATE: Add project-specific security checks here. -->

### 5b — Correctness and Invariants

- Business rules and protocols documented in `AGENTS.md` — violations or silent gaps.

<!-- TEMPLATE: Add protocol-specific correctness checks here. -->

### 5c — Error Handling and Robustness

- `unwrap()` or `expect()` outside tests
- `todo!()` or `unimplemented!()` without an open beads issue
- Errors swallowed with `let _ =` or `.ok()`
- Ignored `Option` or `Result` in important paths
- Missing bounds on user-supplied sizes

### 5d — Architectural Drift

Compare code to `AGENTS.md` **Architecture decisions** — frameworks, persistence, layering.

<!-- TEMPLATE: List key architectural constraints here. -->

### 5e — Test Coverage Blindspots

- Public functions with no tests
- Happy-path-only tests
- Critical handlers never exercised end to end
- Authentication failure paths not tested

### 5f — Consistency and Cohesion

- Types duplicated instead of shared
- Duplicate logic across modules
- Similar implementations diverging without reason
- Shared state misuse
- Bare print statements instead of structured logging

### 5g — Completeness

- Handlers that return success without doing work
- DB writes missing while memory state changes
- Event bus producers or consumers with no counterpart
- Config fields parsed but never used

### 5h — Unimplemented Functionality

- `todo!()` / `unimplemented!()` macros
- Empty or near-empty modules
- Enum variants stubbed with placeholders
- Features described in `AGENTS.md` with no corresponding code

For each, file a **task** issue describing what needs to be implemented and where.

---

## Step 6 — Attribute Findings to Agents

For each finding, determine which agent wrote the code:

```bash
git log --format="%H %s" -- path/to/file | head -5 | while read hash title; do
  agent=$(git show "$hash" --no-patch --format="%b" \
    | grep "Co-Authored-By:" | sed 's/Co-Authored-By: //' | head -1)
  echo "$hash | ${agent:-unknown} | $title"
done
```

Keep a tally per agent by category.

---

## Step 7 — File Issues for Everything Found

For each real finding, create a beads issue and include the responsible agent:

```bash
br create \
  --title="<short, specific title>" \
  --description="Introduced by: <agent name>

<file:line — what is wrong, why it matters, what the fix should be>" \
  --type=bug \
  --priority=<1 for security/crash, 2 for correctness, 3 for quality, 4 for polish>
```

If the finding blocks existing work:

```bash
br dep add <existing-issue-id> <new-issue-id>
```

---

## Step 8 — Update Agent Scorecard

Read the current scorecard:

```bash
cat AGENT_SCORECARD.md
```

Update `AGENT_SCORECARD.md` with:

1. Violation breakdown per agent by category
2. Append a review log entry after the marker:

```markdown
### Arch Review — YYYY-MM-DD HH:MM

| Agent | Findings | Categories | Notes |
|-------|---------|------------|-------|
| ... | N | ... | ... |

Overall codebase health: on track / drifting / concerning
Biggest blindspot: ...
```

The arch review does not update Tasks closed or Bug rate. Only update the violation
breakdown counts and append the log entry.

---

## Step 9 — Commit Everything

```bash
git pull --rebase
br sync --flush-only
git add .beads/issues.jsonl AGENT_SCORECARD.md
git commit -m "chore(arch-review): file findings and update agent scorecard"
git push
```

If `git push` fails, run `git pull --rebase && git push`.

---

## Step 10 — Report

Summarize:

1. Codebase health
2. Security posture
3. Biggest blindspot
4. Issues filed
5. Agent quality
6. Recommendation

Be concise. If nothing serious was found, say so and explain why.
