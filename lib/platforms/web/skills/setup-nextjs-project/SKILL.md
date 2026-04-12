---
name: setup-nextjs-project
description: Configure a Next.js project that has already wired the software-dev-agentic submodule. Copies the web CLAUDE-template.md, prompts for placeholder values, and creates an agents.local stub.
user-invocable: false
tools: Read, Bash
---

Configure a freshly wired Next.js project for software-dev-agentic. Called by `setup-worker`.

## Steps

### 1 — Confirm the repo URL

Ask the user:
> "Which software-dev-agentic repo should I use? Default: `https://github.com/handharr-labs/software-dev-agentic`"

If the user says "default" or provides no URL, use `https://github.com/handharr-labs/software-dev-agentic`.

### 2 — Add submodule

```bash
git submodule add <STARTER_KIT_URL> .claude/software-dev-agentic
```

### 3 — Run the setup script

```bash
.claude/software-dev-agentic/scripts/setup-packages.sh --platform=web
```

This creates `.claude/agents/` and `.claude/skills/` as symlink-only directories, makes hooks executable, and copies `settings-template.json` → `.claude/settings.local.json`. Re-running is safe.

### 4 — Copy CLAUDE-template.md

```bash
cp .claude/software-dev-agentic/lib/platforms/web/CLAUDE-template.md CLAUDE.md
```

### 5 — Prompt for placeholder values

Tell the user:
> "I've created `CLAUDE.md` from the web template. Please fill in:
> - `[AppName]` — your project name
> - `[One-line description...]` — what the app does
> - `[Database]`, `[ORM]`, `[Auth]`, `[UI library]`, `[Test framework]` — your chosen stack
> - `src/features/{auth,[feature-a],...}` — your actual feature names"

### 6 — Create agents.local stub

Create `.claude/agents.local/extensions/arch-review-worker.md`:

```markdown
# arch-review-worker — project-specific rules

> Additive rules for this project. Baseline: `.claude/software-dev-agentic/lib/core/agents/auditor/arch-review-worker.md`.

<!-- Add project-specific audit rules below -->
```

### 7 — Stage and summarize

```bash
git add .gitmodules .claude/ CLAUDE.md
```

Tell the user what was done:
- `.claude/software-dev-agentic/` — submodule pointing to the starter kit repo
- `.claude/{agents,skills,hooks}` — symlinks into the submodule
- `CLAUDE.md` — copied from template (fill in all `[placeholder]` values before starting work)
- `.claude/agents.local/extensions/arch-review-worker.md` — stub for project-specific arch rules
