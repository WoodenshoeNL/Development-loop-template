# Codex — test coverage review

Breadth-focused scan: public surface and missing tests for **<!-- TEMPLATE: project name -->**. **Do not implement code** — file beads issues.

**TEMPLATE:** Adjust `REVIEW_DIRS` and `EXT` in Step 2 to match `AGENTS.md`.

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

```bash
cat .beads/test_scan_index 2>/dev/null || echo "0"
```

```python
import os, sys

REVIEW_DIRS = ["src"]
EXT = ".rs"

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

Exclude files touched in the last 30 minutes (same as other test prompt) if they would clutter results.

---

## Step 3 — Baseline (optional)

If **Verify commands** include test listing, run the relevant subset (e.g. `cargo test --workspace -- --list`). Adapt to your stack.

---

## Step 4 — Per-file scan

For each file in the batch:

- List public symbols / entrypoints (use grep/ripgrep patterns appropriate to the language).
- Map which symbols appear in tests.
- Mark gaps — especially security, persistence, and API boundaries called out in `AGENTS.md`.

---

## Step 5 — Prioritize

Rank gaps: critical correctness first, then core product logic, then helpers.

---

## Step 6 — Dedup

Search open issues for duplicate test/coverage titles before creating new ones.

---

## Step 7 — File issues

One issue per coherent gap:

```bash
br create \
  --title="test: add coverage for <area>" \
  --description="**Files**: ...
**Missing**: ...
**Why**: ..." \
  --type=task \
  --priority=<2|3|4>
```

---

## Step 8 — Index + commit

```bash
echo <NEW_IDX> > .beads/test_scan_index
git pull --rebase
br sync --flush-only
git add .beads/issues.jsonl .beads/test_scan_index
git commit -m "chore(test-coverage): coverage gaps [index <NEW_IDX>]

Co-Authored-By: Codex <noreply@openai.com>"
git push
```

---

## Step 9 — Report

Batch stats, coverage highlights, issues filed, worst gap.
