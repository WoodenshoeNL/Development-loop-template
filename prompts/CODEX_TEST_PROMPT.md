# Codex — test coverage review

Breadth-focused scan: public surface and missing tests for **<!-- TEMPLATE: project name -->**. **Do not implement code** — file beads issues.

Your focus is **coverage breadth**: find every public function that has no test, every module
with no test module, every crate with no integration tests. Be systematic and thorough.

**TEMPLATE:** Adjust `REVIEW_DIRS` and `EXT` in Step 2 to match `AGENTS.md`.

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

You use a rotating scan index to ensure you cover all source files over successive runs,
never always starting from the same place.

### 2a — Read the current index

```bash
cat .beads/test_scan_index 2>/dev/null || echo "0"
```

### 2b — Get the full sorted file list and compute your batch

```python
import os, sys

REVIEW_DIRS = ["src"]   # TEMPLATE
EXT = ".rs"             # TEMPLATE

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
    if fname.endswith(EXT)
    and f"{os.sep}target{os.sep}" not in root
    and f"{os.sep}tests{os.sep}" not in root
    and not fname.startswith("test_")
})

if not files:
    print("NO_FILES")
    sys.exit(0)

batch_size = 12
batch = [files[(idx + i) % len(files)] for i in range(min(batch_size, len(files)))]
new_idx = (idx + batch_size) % len(files)

print(f"BATCH_START={idx}")
print(f"BATCH_NEW_IDX={new_idx}")
print(f"TOTAL_FILES={len(files)}")
for f in batch:
    print(f"FILE:{f}")
```

Note the new index value — you will write it back at the end.

### 2c — Exclude files actively being worked on

```bash
# Files touched in the last 30 minutes by dev agents
git log --since="30 minutes ago" --name-only --pretty=format: | sort -u
```

```bash
# File paths mentioned in in-progress task descriptions
br list --status=in_progress --json 2>/dev/null | python3 -c "
import json, sys, re
try:
    issues = json.load(sys.stdin)
    for issue in issues:
        desc = issue.get('description', '') or ''
        for match in re.findall(r'[\w./]+\.\w+', desc):
            print(match)
except Exception:
    pass
"
```

Remove any matching files from your batch. If the entire batch is excluded, skip
to Step 6 and note "all selected files are under active development".

---

## Step 3 — Get a Coverage Baseline

Before diving into individual files, get a high-level picture:

<!-- TEMPLATE: Adjust these commands to your project's test framework. -->

```bash
# Count test functions across the codebase
grep -rn '#\[test\]' src 2>/dev/null | wc -l

# List integration test files
find src -path '*/tests/*' 2>/dev/null | sort

# Run test list (names only, no execution) if the project compiles
# cargo test --workspace -- --list 2>/dev/null | grep '::' | head -50
```

---

## Step 4 — Systematic Coverage Scan for Each File

For each file in your batch (after exclusions), do the following:

### 4a — Count public functions

List each public function by name and line number (use grep or language-appropriate tools).

### 4b — Find tests that reference this file's functions

Search for test calls to each function:
- Inline tests in the same file
- External integration tests

Build a simple table per file:

| Function | Line | Has test? | Test type |
|----------|------|-----------|-----------|
| `fn foo` | 42 | Yes | unit |
| `fn bar` | 87 | No | — |

### 4c — Check for a test module at all

If the file has zero test coverage (no inline test module, no external test files
referencing it), mark the entire file as "no test coverage".

### 4d — Check test results if available

Run or reference the test suite output. Note any test failures.

---

## Step 5 — Prioritize Coverage Gaps

After scanning all files in your batch, rank the gaps by importance:

**P2 — Critical (must test)**:
- Any public function in security-critical paths
- Authentication and session management functions
- Database write operations

**P3 — Important (should test)**:
- Public functions in business logic
- Error constructors and conversion functions
- Route handler functions

**P4 — Quality (nice to have)**:
- Internal helper functions that are complex enough to warrant tests
- Functions with many branches

---

## Step 6 — Check for Duplicate Issues

```bash
br list --status=open --json 2>/dev/null | python3 -c "
import json, sys
try:
    issues = json.load(sys.stdin)
    for i in issues:
        t = i.get('title', '')
        if any(w in t.lower() for w in ['test', 'coverage', 'unit test', 'integration']):
            print(i['id'], '|', t)
except Exception:
    pass
"
```

Skip creating an issue if an existing open issue already covers the same function.

---

## Step 7 — Create Beads Issues for Coverage Gaps

Create one issue per logical unit of missing coverage. Do not create one giant issue
for an entire file — break it down by function group or concern.

```bash
br create \
  --title="test: add <unit|integration|round-trip> tests for <module/function>" \
  --description="**File**: <path>
**Functions with no tests**:
- \`fn <name>\` (line <N>) — <one-line description of what it does>

**Why this matters**: <specific bug that could go undetected without these tests>

**Minimum test scenarios needed**:
1. Happy path: <input → expected output>
2. Error path: <invalid input → expected error>
3. Edge case: <boundary condition>" \
  --type=task \
  --priority=<2|3|4>
```

Aim for 4–10 issues per run, one per distinct coverage gap. Be specific: name the
exact functions, not just the file.

---

## Step 8 — Advance the Rotation Index and Commit

```bash
echo <NEW_IDX> > .beads/test_scan_index
```

```bash
git pull --rebase
br sync --flush-only
git add .beads/issues.jsonl .beads/test_scan_index
git commit -m "chore(test-coverage): coverage gaps [scan index advanced to <NEW_IDX>]

Co-Authored-By: Codex <noreply@openai.com>"
git push
```

If `git push` fails: `git pull --rebase && git push`.

---

## Step 9 — Report

Summarize your findings:

1. **Files scanned**: N files (positions M–N of total P)
2. **Public functions found**: N total, N with tests, N without
3. **Coverage rate for this batch**: N% (functions with tests / total public functions)
4. **Issues filed**: list each new beads ID, function(s) affected, and priority
5. **Worst coverage gap**: the file or function with the most critical missing tests
6. **Trend**: compared to what you know, is coverage improving or stagnating?

If a file in your batch has complete coverage, explicitly note it as "well-tested".
