# Feature Completeness Review

<!-- TEMPLATE: Replace project name and adjust zone names/paths throughout. -->

You are doing a **feature completeness and integration review** of one or more zones in this
project. Your job is to answer: *what was promised, what exists, what's missing, and can the
zones actually work together?*

This is not a code quality review — that is the arch loop's job. You are not looking for
bugs, style issues, or test coverage. You are looking at **functionality**: is the right
thing built, is it complete, and does it connect correctly to adjacent zones?

**Do NOT write or modify any source code. Only create/update beads issues and report.**

The zone(s) you are reviewing are listed at the end of this prompt under **Zone Constraint**.

---

## Step 0 — Check for stop signal

```bash
if [ -f .stop ]; then echo "STOP signal detected. Exiting."; exit 0; fi
```

---

## Step 1 — Orient: read the spec

Read the project goals, architecture decisions, and design specs:

```bash
cat AGENTS.md
```

Pay attention to:
- The current active phase and its objectives
- The architecture decision table
- Any zone-specific sections and design specs

Also read any supplementary documentation if present:
```bash
ls docs/ 2>/dev/null
cat docs/*.md 2>/dev/null | head -200
```

---

## Step 2 — Load beads context for target zones

Pull the current issue state:

```bash
br list --status=open --json --limit 0
br list --status=in_progress --json --limit 0
```

For each target zone, build a picture of:
- What work is actively planned (open issues with `zone:<name>` label)
- What is currently in flight (in_progress)
- What has recently been closed (gives signal on what's been built)

```bash
# recently closed, for context
br list --status=closed --json --limit 100
```

You will cross-reference this in Step 5 to avoid filing duplicate issues.

---

## Step 3 — Map planned features per zone

For each target zone, extract the *intended* feature set from AGENTS.md:

- What does the spec say this zone should do?
- What commands/endpoints/capabilities are listed?
- What integration points are mentioned (what does it connect to)?
- What is the stated status (e.g. "Production", "Phase 2a", "Active")?

Build a mental checklist: **planned feature → source of truth** (which section of AGENTS.md).

If the spec for a zone is thin or ambiguous, note that — it is a finding in itself (Step 8).

---

## Step 4 — Inventory the actual implementation

For each target zone, read the source code to understand what is actually built.

**Be selective — do not read everything. Focus on:**
- Entry points (e.g. `main.rs`, `lib.rs`, `main.py`, `index.ts`)
- Public API surface (exported functions, REST routes, handlers)
- Capability lists (match arms on command enums, registered routes/handlers)

<!-- TEMPLATE: Adjust search commands for your language. Examples below are for Rust; adapt
     for Python (grep `^def \|^class `), TypeScript (grep `^export `), etc. -->

```bash
# Get a structural picture first
# (use Glob and Grep tools — do not shell out to find/grep)
```

- Glob `<zone_path>/src/**/*.<ext>` to list all source files
- Grep public API surface patterns in zone source
- For route/handler registrations: grep relevant registration patterns
- For stubs: grep `todo!\|unimplemented!\|pass  #\|raise NotImplementedError` in zone source

Read files selectively — entry points and route/handler registrations first, implementation
details only when needed to assess completeness.

---

## Step 5 — Gap analysis per zone

For each zone, compare Step 3 (planned) against Step 4 (actual). Produce a completeness
assessment with one of these statuses for each planned feature:

| Status | Meaning |
|--------|---------|
| ✅ Complete | Fully implemented and wired up |
| 🔨 Partial | Exists but stubbed, incomplete, or missing sub-features |
| ❌ Missing | Nothing in the code corresponds to this planned feature |
| ❓ Unclear | Hard to tell — spec or code is ambiguous |

For every **Partial** or **Missing** item, note:
- What specifically is missing
- Which file/module it belongs in
- Whether an open beads issue already covers it

Do not file issues yet — collect all findings first.

---

## Step 6 — Multi-zone integration analysis

*Skip this step if only one zone was specified.*

When multiple zones are in scope, analyse the **boundaries between them**. For each pair
of adjacent zones, work through these questions:

### Interface contracts

What does Zone A expose that Zone B depends on?

<!-- TEMPLATE: Replace these examples with the actual zone pairs and interface types in
     your project. Examples:
     - Zone A ↔ Zone B: Does the REST API expose every endpoint Zone B requires?
     - Zone A ↔ Zone C: Do shared types come from a common module or are they duplicated?
     - Any zone ↔ common/shared: Are shared types used at both ends, or do zones define
       their own parallel copies? -->

To check: grep for the relevant type/function names on both sides of the boundary.

### Integration gaps

Features where code exists on both sides but the pieces don't connect:

<!-- TEMPLATE: List the kinds of integration gaps relevant to your architecture.
     Examples:
     - An API endpoint that exists in the backend but the CLI has no corresponding command
     - An event emitted by service A that service B never subscribes to
     - A config option that service A reads but service B never writes -->

### Missing glue

Features that require pieces in *multiple* zones but at least one zone has nothing at all:

<!-- TEMPLATE: Describe the kinds of multi-zone data flows to trace. Example:
     "User submits request → backend queues job → worker executes → result returned →
     client displays" — trace it zone by zone and find where it breaks. -->

---

## Step 7 — Assess spec and roadmap clarity

This loop is opinionated. If you find problems with the spec or roadmap itself, say so.
You will report these as observations (Step 9) rather than beads issues, since they need
a human decision before any dev work can start.

Ask yourself:
- **Gaps in AGENTS.md**: Is any zone's intended scope unclear or contradictory?
- **Stale spec**: Does AGENTS.md describe something that has clearly evolved in a different
  direction in the code? (The spec may need updating.)
- **Missing spec**: Is there a zone or feature with no design spec at all, leaving dev
  agents to guess at the implementation?
- **Phase goal drift**: Are the current active-phase objectives still accurate given what
  has been built? Is the project ahead or behind on them?
- **Ordering problems**: Are there planned features being built in the wrong order
  (wrong dependencies, building layer N+1 before layer N is solid)?

Do not update AGENTS.md yourself. List these observations clearly in the report so the
human can address them with Claude Code directly.

---

## Step 8 — Deduplicate and prepare issues

Before filing anything, search for existing coverage:

```bash
br search "<key phrase>"
```

For each gap found in Steps 5 and 6, decide:

- **Already covered by an open issue** → note the existing ID; consider whether it needs
  a description update or a follow-up sub-issue for the *next* step
- **Partially covered** → update the existing issue with missing detail, or create a
  follow-up linked with `br dep add`
- **Not covered** → create a new issue

**Issue sizing rule**: each issue should be completable by a dev agent in one session
(~300 lines / 3 files max). Split large features into ordered sub-issues.

---

## Step 9 — File and update issues

### Updating an existing issue

```bash
br update <id> --description="<improved description with file:line and grep term>"
```

Only update if you are adding meaningful precision (exact file path, function name,
what to grep for). Don't update just to reword.

### Creating a new issue

Search for duplicates first:
```bash
br search "<key phrase from title>"
```

Then:
```bash
br create \
  --title="<impl|feat|fix>(<zone>): <short description>" \
  --description="**Spec source**: AGENTS.md §<section> / beads <id if follow-up>

**File**: \`<path/to/file>\` (or \`<path/to/module/>\` for new files)
**Location**: \`<fn or struct name>\` (grep: \`<search term>\`) ~line <N>
(omit location for brand-new files)

**What is missing**:
<clear description of what needs to exist>

**What it should do**:
<behaviour, interface, expected output — be specific>

**Why it matters**:
<which phase goal or integration point this unblocks>" \
  --type=task \
  --priority=<1 for blockers, 2 for core functionality, 3 for secondary, 4 for nice-to-haves> \
  --labels=zone:<zone>
```

For integration gap issues that span two zones, label both:
```bash
br update <id> --add-label zone:<second-zone>
```

Link ordered sub-issues:
```bash
br dep add <later-issue> <earlier-issue>
```

<!-- TEMPLATE: Replace this zone-to-path mapping with your actual zones -->
Zone derivation from path:
`src/` → main (adjust per AGENTS.md Zone table)

### Verify every created issue

```bash
for id in <id1> <id2> ...; do
  br show "$id" >/dev/null 2>&1 && echo "$id ok" || echo "$id MISSING"
done
```

Never report an ID that failed verification.

---

## Step 10 — Commit beads changes

Only if you created or updated issues:

```bash
br sync --flush-only
git pull --rebase --quiet
git add .beads/issues.jsonl
git diff --cached --quiet || git commit -m "chore(feature-review): completeness pass [$(date +%Y-%m-%d)]"
git push
```

If `git push` fails: `git pull --rebase && git push`.

---

## Step 11 — Report

Write a structured report covering:

### Completeness matrix

For each zone reviewed, a table:

| Feature | Status | Notes / Issue ID |
|---------|--------|-----------------|
| ...     | ✅/🔨/❌/❓ | ... |

### Integration gaps (multi-zone only)

List each gap with: which zones are involved, what's missing, issue ID filed or existing
issue ID already covering it.

### Spec and roadmap observations

List any issues with AGENTS.md or the current phase goals — unclear scope, stale spec,
ordering problems, missing design decisions. These are for human review, not dev loop tasks.

### Issues filed / updated

| ID | Action | Title | Zone |
|----|--------|-------|------|
| ...| created/updated | ... | ... |

### Summary

2–3 sentences: overall completeness picture, most important gap, most important integration
risk. Be direct — if the project is behind or a zone is in poor shape, say so.
