# Claude — architecture review

Deep, stateless review of **<!-- TEMPLATE: project name -->**: you read the codebase as it exists now (not only the latest diff). **Do not write product code.** File beads issues and update `AGENT_SCORECARD.md` per your workflow.

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
git log --oneline -5   # just to know where HEAD is
```

---

## Step 2 — Map the Codebase

Get a full structural picture before reading any code. Use your Glob and Grep tools
directly — do not shell out to `find` or `grep` for these.

<!-- TEMPLATE: Replace with your project's source directories and file patterns.
Example for Rust:
- Glob `src/**/*.rs` to list all source files
- Glob `**/Cargo.toml` to find crate roots
- Grep `^pub ` in shared libraries to map the public API surface
-->

```bash
# TEMPLATE: replace 'src' with space-separated roots from AGENTS.md
find src -name '*.rs' 2>/dev/null | sort
find src -name '*.rs' 2>/dev/null | xargs wc -l 2>/dev/null | sort -rn | head -25
```

For each source file, mentally flag files whose names suggest they are
security-sensitive (`crypto`, `auth`, `session`, `key`, `handler`) or
structurally important (`main`, `lib`, `mod`, `router`, `config`).

Do not read any file contents yet — only build the map.

---

## Step 3 — Read Files Selectively

Using the map from Step 2, read files in priority order. Use your Read
tool for each file — do NOT cat everything in one shell loop.

**Tier 1 — always read in full:**
- Entrypoints (`main`, `lib`), config, and shared type definitions
- Any file whose name suggests security-sensitive code

**Tier 2 — read in full if they exist:**
- All remaining source modules (handlers, routers, listeners)
- Integration tests

**Tier 3 — skim (read first 60 lines, then full read only if something looks wrong):**
- Peripheral or utility modules

Work through tier 1 before tier 2. If a file is very large (>500 lines), read it in chunks
using offset/limit rather than all at once.

---

## Step 4 — Verify

Run **Verify commands** from `AGENTS.md`. Capture failures for the report.

<!-- TEMPLATE: If your verify has sub-steps with abort logic, document it here.
Example for Rust:

**Step 4a — type check first (abort if this fails):**
```bash
cargo check --workspace 2>&1
```

**Step 4b — run tests:**
```bash
cargo nextest run --workspace 2>&1
# fallback: cargo test --workspace 2>&1
```

**Step 4c — lint:**
```bash
cargo clippy --workspace -- -D warnings 2>&1
```
-->

Note every warning, error, and test failure.

---

## Step 5 — Deep Analysis

Work category by category. For each finding, note the file and line. **TEMPLATE:** Add domain-specific bullets under **Architecture decisions** or **Security notes** in `AGENTS.md`; use those here instead of hardcoded examples.

### 5a — Security

- Trust boundaries, authn/z, secret handling, unsafe input validation, logging of sensitive data.
- Integer overflow: are casts from untrusted data guarded?
- Denial of service: can untrusted input cause unbounded memory growth?
- Timing attacks: are secret comparisons done with constant-time equality?

<!-- TEMPLATE: Add project-specific security checks here (e.g. crypto correctness,
protocol-specific validation). -->

### 5b — Correctness and Invariants

- Business rules and protocols documented in `AGENTS.md` — violations or silent gaps.

<!-- TEMPLATE: Add protocol or domain-specific correctness checks here. -->

### 5c — Error Handling and Robustness

- `unwrap()` / `expect()` outside test code — each one is a potential panic in production
- `todo!()` / `unimplemented!()` without a corresponding open beads issue
- Errors swallowed with `let _ =` or `.ok()` in paths where the error matters
- Functions that return `Option`/`Result` but callers ignore the error silently
- Missing bounds on user-supplied sizes before allocation
- Resource leaks, unbounded queues, missing timeouts

### 5d — Architectural Drift

- Code diverges from **Architecture decisions** (frameworks, persistence, layering).

<!-- TEMPLATE: List your project's key architectural constraints here for easy reference. -->

### 5e — Test Coverage Blindspots

- Public functions with no test at all
- Happy-path-only tests with no error or edge case coverage
- Critical handlers tested in isolation but never in an end-to-end flow
- Authentication failure paths tested?

### 5f — Consistency and Cohesion

- Types defined in multiple places that should live in a shared module
- Duplicate logic across modules
- Similar implementations that handle the same concern differently with no good reason
- Shared state management: is it consistent? Any data races?
- Logging/observability: used consistently, or are there bare print statements?

### 5g — Completeness

- Stubs that return success without work; parsed config unused; dead feature flags.
- DB writes that are missing (state updated in memory but not persisted)
- Event/message producers or consumers with no counterpart

### 5h — Unimplemented Functionality

Look for parts of the codebase that are not yet implemented or only skeletally present:
- `todo!()` / `unimplemented!()` macros — each one represents missing functionality
- Empty or near-empty modules that are declared but have no real logic
- Enum variants or match arms that are stubbed with placeholder responses
- Features described in `AGENTS.md` or config schemas that have no corresponding code yet

For each, file a **task** issue (not a bug) describing what needs to be implemented and where.

---

## Step 6 — Attribute Findings to Agents

Before filing issues, determine which agent wrote the problematic code. Use a single
`git log` call per file rather than one `git show` per commit:

```bash
# For each file with a finding, get the last few commits and their authors in one call:
git log --format="%H | %s | %b" -5 -- path/to/file | grep -E "^|Co-Authored-By"
```

Or batch multiple files at once:

```bash
git log --format="%H %aN %s" -- file1 file2 file3 | head -20
```

Keep a mental tally per agent: how many findings, and of what category.

---

## Step 7 — File Issues for Everything Found

For each real finding, create a beads issue. **Always include the responsible agent** so the
scorecard can be updated accurately.

For **bugs and quality issues**:
```bash
br create \
  --title="<short, specific title>" \
  --description="Introduced by: <agent name>

<file:line — what is wrong, why it matters, what the fix should be>" \
  --type=bug \
  --priority=<1 for security/crash, 2 for correctness, 3 for quality, 4 for polish>
```

For **unimplemented functionality** (from 5h):
```bash
br create \
  --title="impl: <what needs to be implemented>" \
  --description="<file:line — what is missing, what it should do, any relevant context from AGENTS.md or types>" \
  --type=task \
  --priority=<2 for core functionality, 3 for secondary features, 4 for nice-to-haves>
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

1. **Violation breakdown** — increment each agent's counts by category for findings from
   this review (unwrap/expect, missing tests, lint warnings, protocol errors, security,
   architecture drift, memory/resource leaks).

2. **Append a review log entry** at the bottom (after the `<!-- ... -->` marker):

```markdown
### Arch Review — YYYY-MM-DD HH:MM

| Agent | Findings | Categories | Notes |
|-------|---------|------------|-------|
| ... | N | ... | ... |

Overall codebase health: on track / drifting / concerning
Biggest blindspot: ...
```

Note: the arch review does not update *Tasks closed* or *Bug rate* — those are owned by the
QA loop which has the full commit history. Only update the violation breakdown counts and
append the log entry.

---

## Step 9 — Commit Everything

```bash
git pull --rebase
br sync --flush-only
git add .beads/issues.jsonl AGENT_SCORECARD.md
git commit -m "chore(arch-review): file findings and update agent scorecard"
git push
```

If `git push` fails: `git pull --rebase && git push`.

---

## Step 10 — Report

Write a concise summary covering:

1. **Codebase health**: overall impression (on track / drifting / concerning)
2. **Security posture**: anything that could be exploited or is incorrectly handled
3. **Biggest blindspot**: the single most dangerous gap you found
4. **Issues filed**: list each new beads ID with responsible agent and one-line description
5. **Agent quality**: based on findings this run, which agent is writing the best code?
6. **Recommendation**: what the dev agents should prioritize next

Do not pad the report. If nothing serious was found, say so and explain why you're confident.
