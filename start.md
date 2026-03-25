# New project — design and bootstrap

Use this file at the **start** of a new repo (or right after copying this template). Paste sections into your coding agent as one multi-step brief, or work through them in order yourself.

Markers elsewhere in the template use one of:

- `TEMPLATE:` — replace with project-specific values
- `<!-- TEMPLATE: ... -->` — same, in Markdown-only files

After customization, you can trim this file or keep it as internal onboarding doc.

---

## 1 — Identity

Answer briefly (the agent will copy into `README.md` and `AGENTS.md`):

1. **Project name** (human-readable): <!-- TEMPLATE: e.g. "My Service" -->
2. **One-line pitch**: <!-- TEMPLATE: what it does -->
3. **Git remote URL** (for README clone example): <!-- TEMPLATE -->
4. **`br` issue prefix** (kebab-case, stable, e.g. `my-app` — used in `setup.sh`, `loop.py`, and Codex ID normalization): <!-- TEMPLATE -->

**Prompt for agent:**

> Fill in sections marked `TEMPLATE` at the top of `README.md`, `AGENTS.md`, `setup.sh` (EXPECTED_PREFIX), and `loop.py` (PROJECT_ISSUE_PREFIX and ZONES). Use the same beads prefix everywhere.

---

## 2 — Stack and architecture

**Prompt for agent:**

> Replace the Goal, Architecture Decisions, Repository layout, Zone System, and Read-only paths in `AGENTS.md` with decisions for this project. Remove any rows that do not apply. Add a **Verify commands** subsection with the exact shell commands developers must run before committing (test, lint, format — match the real stack, not only Rust).

---

## 3 — Loops and zones

**Prompt for agent:**

> In `loop.py`, set `ZONES` so each key is a zone label and each value is a list of path prefixes under the repo root (trailing slash). Keys must stay in sync with the Zone System table in `AGENTS.md`. Dev loops use `--zone <key>`; omit `--zone` to allow all paths.

---

## 4 — Install and setup scripts

**Prompt for agent:**

> Edit `install.sh` for production/server dependencies (packages, services, optional toolchains). Mark sections you do not need with comments or remove them. Edit `setup.sh` so optional steps (e.g. `scripts/install-toolchains.sh`) are only run when that script exists. Align `EXPECTED_PREFIX` with `PROJECT_ISSUE_PREFIX` in `loop.py`.

---

## 5 — Prompts

**Prompt for agent:**

> Open every file under `prompts/`. Remove remaining Red-Cell-C2 / Havoc references if any. Where prompts say "primary directories" or use `src` / `*.rs`, align with `AGENTS.md` (layout + language). If the project is not Rust, replace `cargo …` checks in review prompts with the commands from **Verify commands** in `AGENTS.md`. For domain-specific security or protocol review bullets, add a short checklist under **Architecture Decisions** or **Security notes** in `AGENTS.md` and point the arch prompts at that list instead of hardcoding examples.

---

## 6 — Scorecard and QA checkpoint

**Prompt for agent:**

> Ensure `AGENT_SCORECARD.md` exists and matches the structure expected by `prompts/CLAUDE_PROMPT.md` (and Codex QA). Create `.beads/qa_checkpoint` only when the QA loop first runs, or leave absent for bootstrap review.

---

## 7 — Issue tracker

**Prompt for agent:**

> Install `br`, run `br config set issue_prefix <same-as-setup>`, import or create `.beads/issues.jsonl`, run `br sync --import-only`, then seed 3–5 epics/tasks that match the architecture in `AGENTS.md`.

---

## 8 — README and polish

**Prompt for agent:**

> Update README project structure tree and any links. Remove this template’s filler where it no longer applies. Run `./setup.sh` locally to verify.

---

## Optional — single message you can paste into an agent

```text
We are bootstrapping a new repo from the development-loop template.

1. Read start.md and AGENTS.md.
2. Apply the user’s answers for project name, pitch, git URL, and beads prefix everywhere marked TEMPLATE (README, AGENTS, setup.sh, loop.py).
3. Fill AGENTS.md with real architecture, zones, verify commands, and optional domain/security checklists.
4. Sync loop.py ZONES with AGENTS.md.
5. Generalize prompts/ (paths, language, verify commands) and install.sh if needed.
6. Confirm AGENT_SCORECARD.md exists; adjust if QA/arch prompts require it.
7. Do not leave references to Red-Cell-C2, Havoc, or the old project.

User inputs:
- Name:
- Pitch:
- Git URL:
- Beads prefix:
- Stack (languages, frameworks):
- Main source directories (for reviews/zones):
```
