# Claude — test quality review

You evaluate **test design and quality** for **<!-- TEMPLATE: project name -->** (not only coverage counts). **Do not write production code.** File beads issues for gaps.

Your focus is **test quality and design**, not raw coverage numbers:
- Are tests actually verifying the right things?
- Would these tests catch real bugs?
- Are edge cases and error paths covered?
- Are test names clear about what scenario they test?

**TEMPLATE:** If primary roots are not `src/`, update `REVIEW_DIRS` in Step 2 and path filters throughout.

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
git log --oneline -3
```

---

## Step 2 — Determine Which Files to Review This Run

You use a rotating scan index to ensure you cover the whole codebase systematically over
multiple runs, rather than always starting from the same place.

### 2a — Read the current index

```bash
cat .beads/test_scan_index 2>/dev/null || echo "0"
```

### 2b — Get the full sorted file list

<!-- TEMPLATE: Replace 'src' with your project's source directories. -->

```bash
find src -name '*.rs' 2>/dev/null | sort
```

If no source files exist yet, there is nothing to review. Skip to Step 7
and report "no source files found".

### 2c — Compute your batch using Python

Select 10 files starting from the current index (wrapping around). This ensures every
part of the codebase gets visited over successive runs.

```python
import os, sys

REVIEW_DIRS = ["src"]  # TEMPLATE
EXT = ".rs"            # TEMPLATE: set to match AGENTS.md Review file glob

index_file = ".beads/test_scan_index"
try:
    with open(index_file) as f:
        idx = int(f.read().strip())
except Exception:
    idx = 0

files = sorted({
    os.path.join(root, fname)
    for d in REVIEW_DIRS
    for root, _, fnames in os.walk(d)
    for fname in fnames
    if fname.endswith(EXT) and f"{os.sep}target{os.sep}" not in root
})

if not files:
    print("NO_FILES")
    sys.exit(0)

batch_size = 10
batch = [files[(idx + i) % len(files)] for i in range(min(batch_size, len(files)))]
new_idx = (idx + batch_size) % len(files)

print(f"BATCH_START={idx}")
print(f"BATCH_NEW_IDX={new_idx}")
print(f"TOTAL_FILES={len(files)}")
for f in batch:
    print(f"FILE:{f}")
```

Note the new index value — you will write it back at the end.

### 2d — Exclude files actively being worked on

Check which files have been modified in the last 30 minutes (dev agents are likely
still working on them — avoid creating conflicting issues):

```bash
git log --since="30 minutes ago" --name-only --pretty=format: | sort -u
```

Also check in-progress task descriptions for file paths:

```bash
br list --status=in_progress --json 2>/dev/null | python3 -c "
import json, sys, re
try:
    issues = json.load(sys.stdin)
    for issue in issues:
        desc = issue.get('description', '') or ''
        # Extract anything that looks like a file path ending in a source extension
        for match in re.findall(r'[\w/]+\.\w+', desc):
            print(match)
except Exception:
    pass
"
```

Remove any files from your batch that appear in either list. If the entire batch is
excluded, skip to Step 6 and note "all selected files are under active development".

---

## Step 3 — Read the Selected Files

For each file in your batch (after exclusions), read it fully. Also check for its
corresponding test file (if it is not already a test file):

- Inline `#[cfg(test)]` module at the bottom of the file
- External test files in `tests/` directories
- Any test file that imports from that module

---

## Step 4 — Deep Test Quality Analysis

For each file you reviewed, assess the following. Take notes as you go — you will
create beads issues at the end.

### 4a — Test existence

- Does the file have *any* tests at all? (inline or external)
- Are all public functions covered by at least one test?

### 4b — Test meaningfulness

For each test that *does* exist, ask:
- Does it contain at least one assertion? A test with no assertions is useless.
- Does it test behavior or just call the function and ignore the result?
- Does it verify the *specific* thing the function is supposed to do?

### 4c — Error path coverage

Functions that return `Result` or `Option` have two meaningful paths. Check:
- Is the error/failure path tested, not just the success path?
- Are error variants meaningfully different — are they all tested?

### 4d — Edge cases and boundary conditions

- Off-by-one: for functions handling lengths/sizes/ranges, are boundary values tested?
- Empty inputs: what happens with empty collections, empty strings, zero-length buffers?
- Large/overflow inputs: what happens near integer overflow boundaries?

### 4e — Serialization and round-trips

<!-- TEMPLATE: Adjust for your project's serialization format. -->

For any code that parses or serializes data:
- Is there a round-trip test (encode → decode → compare original)?
- Are malformed/truncated inputs tested to ensure they return errors, not panics?

### 4f — Test isolation and design quality

- Do tests depend on external state (files, network, time) without properly controlling it?
- Are tests too large — covering many behaviors in one test function?
- Are test names descriptive? `test_parse_packet_with_wrong_magic_returns_error` is
  good. `test1` or `test_parse` is not.
- Is there significant test setup duplication that should be in a helper?

### 4g — Integration test coverage

- Are there integration tests that cover end-to-end flows?
- Are critical paths tested end-to-end, or only in isolation?
- Are authentication/authorization failure paths tested at the integration level?

---

## Step 5 — Check for Duplicate Issues

Before creating new issues, first check `docs/known-failures.md` for already-tracked
test failures:

```bash
test -f docs/known-failures.md && cat docs/known-failures.md
```

Then check what test-related issues are already open:

```bash
br list --status=open --json 2>/dev/null | python3 -c "
import json, sys
try:
    issues = json.load(sys.stdin)
    for i in issues:
        t = i.get('title', '')
        if any(w in t.lower() for w in ['test', 'coverage', 'assert', 'unit test', 'integration test']):
            print(i['id'], '|', t)
except Exception:
    pass
"
```

Do not create a duplicate issue if one already exists for the same function or gap.
It is fine to create an issue for a different aspect of the same file.

---

## Step 6 — Create Beads Issues for Gaps Found

For each meaningful gap, create a beads issue. Prioritize as follows:
- **P2** — missing tests for security-critical code
- **P3** — missing tests for core business logic, error paths, or round-trip coverage
- **P4** — test quality improvements (better names, reduced duplication, missing edge cases)

Use type `task` for all test coverage issues.

```bash
br create \
  --title="test: <specific description of what is missing>" \
  --description="**File**: <path>
**Gap type**: <existence | error path | edge case | round-trip | quality>

<What is missing and why it matters. Be specific: name the function(s), describe
the scenario(s) that are not covered, and explain what kind of bug could slip through
without this test.>

**Suggested test approach**:
<Brief sketch of what the test should do — input, action, expected outcome.>" \
  --type=task \
  --priority=<2|3|4>
```

Aim for 3–8 issues per run. Quality over quantity — a vague issue like "add tests for
foo" is not actionable. Be specific about the function, the scenario, and why it matters.

---

## Step 7 — Advance the Rotation Index and Commit

Write the new scan index so the next run picks up where you left off:

```bash
echo <NEW_IDX> > .beads/test_scan_index
```

Then commit and push everything:

```bash
git pull --rebase
br sync --flush-only
git add .beads/issues.jsonl .beads/test_scan_index
git commit -m "chore(test-review): test quality issues [scan index advanced to <NEW_IDX>]

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

If `git push` fails: `git pull --rebase && git push`.

---

## Step 8 — Report

Summarize your findings concisely:

1. **Files reviewed**: list the files you analyzed this run (N of M total)
2. **Scan position**: index before → after (shows progress through the codebase)
3. **Issues filed**: list each new beads ID with a one-line description
4. **Most critical gap**: the single most dangerous test blindspot you found
5. **Overall test quality**: what is the general state of testing in the files you reviewed?

If all files in your batch had solid test coverage, say so clearly and explain why
you are confident.
