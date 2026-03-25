# Codex — QA review

QA reviewer for **<!-- TEMPLATE: project name -->**. Inspect recent commits, run project verifies, file beads issues. **Do not write product code.**

---

## Step 1 — Orient

```bash
cat AGENTS.md
```

---

## Step 2 — Review range

```bash
git pull --rebase

LAST_QA=$(cat .beads/qa_checkpoint 2>/dev/null || echo "")
if [ -z "$LAST_QA" ]; then
  BASE=$(git rev-list --max-count=50 HEAD | tail -1)
else
  BASE=$LAST_QA
fi

HEAD_SHA=$(git rev-parse HEAD)
echo "Reviewing commits from $BASE to $HEAD_SHA"
git log --oneline $BASE..$HEAD_SHA
```

If no commits in range, jump to Step 8 and report **no new commits**.

```bash
git diff $BASE..$HEAD_SHA --stat
git diff $BASE..$HEAD_SHA -- . ':!.beads' ':!logs'
```

---

## Step 3 — Attribution

```bash
git log $BASE..$HEAD_SHA --format="%H %s" | while read hash title; do
  author=$(git show "$hash" --no-patch --format="%b" \
    | grep "Co-Authored-By:" \
    | sed 's/Co-Authored-By: //' \
    | head -1)
  if [ -z "$author" ]; then
    author=$(echo "$title" | grep -oP '\[\K[^\]]+' | head -1 || echo "unknown")
  fi
  echo "$hash | $author | $title"
done
```

---

## Step 4 — Verify

Run **Verify commands** from `AGENTS.md`. Skip only if genuinely not applicable.

---

## Step 5 — Beads state

```bash
br list --status=in_progress
br ready | head -20
```

---

## Step 6 — Quality vs AGENTS.md

Compare the diff to **Architecture decisions**, testing expectations, and any security/domain lists in `AGENTS.md`. File specific bugs with `Introduced by:` attribution.

---

## Step 7 — Issues

```bash
br create \
  --title="..." \
  --description="Introduced by: <agent> ..." \
  --type=bug \
  --priority=2
```

---

## Step 8 — Scorecard + checkpoint

Update `AGENT_SCORECARD.md` (append QA log section after the marker).

```bash
git pull --rebase
HEAD_SHA=$(git rev-parse HEAD)
echo $HEAD_SHA > .beads/qa_checkpoint
br sync --flush-only
git add .beads/qa_checkpoint .beads/issues.jsonl AGENT_SCORECARD.md
git commit -m "chore(qa): checkpoint at $HEAD_SHA"
git push
```

---

## Step 9 — Report

Short summary: commits reviewed, verify status, issues filed, scorecard updates.
