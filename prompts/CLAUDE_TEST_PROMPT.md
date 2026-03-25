# Claude — test quality review

You evaluate **test design and quality** for **<!-- TEMPLATE: project name -->** (not only coverage counts). **Do not write production code.** File beads issues for gaps.

**TEMPLATE:** If primary roots are not `src/`, update `REVIEW_DIRS` in Step 2 and path filters throughout.

---

## Step 0 — Stop

```bash
test ! -f .stop || { echo "STOP"; exit 0; }
```

---

## Step 1 — Orient

```bash
cat AGENTS.md
git log --oneline -3
```

---

## Step 2 — Rotation batch

### 2a — Index

```bash
cat .beads/test_scan_index 2>/dev/null || echo "0"
```

### 2b — File list (Python)

Use roots from **Primary source directories** in `AGENTS.md` (default `src`):

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

### 2c — Exclude active files

```bash
git log --since="30 minutes ago" --name-only --pretty=format: | sort -u
```

Remove overlapping paths from your batch; if nothing left, report **all selected files under active development**.

---

## Step 3 — Read files

Read each batch file completely. Locate its tests (inline modules, `tests/`, etc.) per project conventions in `AGENTS.md`.

---

## Step 4 — Quality analysis

Per file:

- **Existence** — are behaviors covered at all?
- **Assertions** — tests must assert meaningful outcomes, not just run.
- **Error paths** — failures and edge cases, not only happy path.
- **Boundaries** — empty, max, malformed inputs where relevant.
- **Domain** — serialization, auth, persistence: add checks from `AGENTS.md` when applicable.
- **Isolation** — flaky shared state, unclear test names, duplicated setup.

---

## Step 5 — Duplicates

```bash
test -f docs/known-failures.md && cat docs/known-failures.md
```

Avoid filing duplicates; scan open issues mentioning tests.

---

## Step 6 — File issues

```bash
br create \
  --title="test: <specific gap>" \
  --description="**File**: <path>
**Gap**: ...

**Suggested approach**: ..." \
  --type=task \
  --priority=<2|3|4>
```

---

## Step 7 — Advance index + commit

```bash
echo <NEW_IDX> > .beads/test_scan_index
git pull --rebase
br sync --flush-only
git add .beads/issues.jsonl .beads/test_scan_index
git commit -m "chore(test-review): test quality issues [index <NEW_IDX>]

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

---

## Step 8 — Report

Files reviewed, index progress, issues filed, worst gap, overall assessment.
