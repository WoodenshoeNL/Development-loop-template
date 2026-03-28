# Codex — QA review

QA reviewer for **<!-- TEMPLATE: project name -->**. Inspect recent commits, run project verifies, file beads issues. **Do not write product code.**

---

## Step 1 — Orient

Read the project context:

```bash
cat AGENTS.md
```

---

## Step 2 — Determine Review Range

The checkpoint file `.beads/qa_checkpoint` stores the last commit hash you fully reviewed.
Use it as the base of your diff so no commits are ever skipped or re-reviewed.

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

If `git log` shows no output (HEAD == BASE), the codebase is fully reviewed. Skip to Step 8
and report "no new commits since last review".

Then review the actual diff:

```bash
git diff $BASE..$HEAD_SHA --stat
git diff $BASE..$HEAD_SHA -- . ':!.beads' ':!logs'
```

---

## Step 3 — Attribute Commits to Agents

For every commit in the review range, determine which agent wrote it. This is used for
scorecard tracking and for attributing any bugs you file.

```bash
git log $BASE..$HEAD_SHA --format="%H %s" | while read hash title; do
  author=$(git show "$hash" --no-patch --format="%b" \
    | grep "Co-Authored-By:" \
    | sed 's/Co-Authored-By: //' \
    | head -1)
  if [ -z "$author" ]; then
    author=$(echo "$title" | grep -oP '\[\K[^\]]+' | head -1)
  fi
  echo "$hash | $author | $title"
done
```

Identify which agent closed each task:

```bash
git log $BASE..$HEAD_SHA --format="%s%n%b" \
  | grep -E "(chore: close|Co-Authored-By)" \
  | paste - -
```

Build a mental map: for each closed issue in this range, which agent closed it?
For each file changed, which agent's commit last touched it?

---

## Step 4 — Check Build Health

Run **Verify commands** from `AGENTS.md`. Skip only if genuinely not applicable.

<!-- TEMPLATE: If your verify steps have specific sub-steps, document them here. -->

---

## Step 5 — Review Beads State

```bash
br list --status=in_progress
br list --status=open | head -30
br ready | head -20
```

Check:
- Are any issues stuck `in_progress` for too long without a related commit?
- Are issues being closed without the work actually being done?
- Are there implementation tasks that should be unblocked but aren't?

---

## Step 6 — Review Code Quality

Compare the diff to **Architecture decisions**, testing expectations, and any security/domain lists in `AGENTS.md`. File specific bugs with `Introduced by:` attribution.

<!-- TEMPLATE: Add project-specific quality checks here (architecture compliance,
code quality, security, protocol correctness, tests). -->

---

## Step 7 — Create Issues for Problems Found

**Before filing any test failure bug**, check `docs/known-failures.md`:

```bash
cat docs/known-failures.md
```

If the failing test is already listed there, do NOT create a duplicate. If a test
found a new persistent failure not in that file, add it to `docs/known-failures.md` as part
of your commit (Step 9), then file the beads issue.

For each problem, create a beads issue. Always include the responsible agent from Step 3 in
the description so the scorecard can be updated accurately.

```bash
br create \
  --title="<short description>" \
  --description="Introduced by: <agent name>

<what is wrong, where it is (file:line), what the correct behavior should be>" \
  --type=bug \
  --priority=<0-2 for real problems, 3-4 for polish>
```

If the problem blocks an existing issue, add the dependency:

```bash
br dep add <existing-issue-id> <new-bug-id>
```

---

## Step 8 — Update Agent Scorecard

Read the current scorecard:

```bash
cat AGENT_SCORECARD.md
```

Update `AGENT_SCORECARD.md` with:

1. Running totals:
   - Tasks closed: count close commits per agent in this review range
   - Bugs filed against: count bugs you filed this run, attributed to each agent
   - Violation breakdown: tally by category
   - Bug rate: bugs filed / tasks closed
   - Quality score: `(1 - bug_rate) * 100`, capped to 0-100%

2. Append a review log entry at the bottom after the marker:

```markdown
### QA Review — YYYY-MM-DD HH:MM — <BASE_SHORT>..<HEAD_SHORT>

| Agent | Tasks closed | Bugs filed | Notes |
|-------|-------------|------------|-------|
| ... | N | N | ... |

Build: passed / failed / skipped
```

If no agent activity was seen this run, still append the log entry with zeros so there is a
record of the review having run.

---

## Step 9 — Update Checkpoint and Commit

```bash
git pull --rebase
HEAD_SHA=$(git rev-parse HEAD)
echo $HEAD_SHA > .beads/qa_checkpoint
br sync --flush-only
git add .beads/qa_checkpoint .beads/issues.jsonl AGENT_SCORECARD.md
git commit -m "chore(qa): checkpoint at $HEAD_SHA — update agent scorecard"
git push
```

If `git push` fails due to a concurrent push, run `git pull --rebase && git push`.

---

## Step 10 — Report

Summarize:

1. Review range: `<BASE_SHA>..<HEAD_SHA>` and commit count
2. Agent breakdown
3. Build status
4. Issues found
5. Scorecard delta
6. Overall assessment

Keep it concise. If everything looks good, say so clearly.
