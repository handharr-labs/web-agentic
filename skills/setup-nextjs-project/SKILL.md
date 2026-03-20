# /setup-nextjs-project

Wire a freshly cloned Next.js project to consume the `nextjs-arch` starter kit as a git submodule, then guide the user through filling in project-specific details.

---

## When to use

Invoke this skill when the user says:
- "Set up this project with the starter kit"
- "Wire the nextjs-arch submodule"
- "Initialize `.claude/` for this project"
- `/setup-nextjs-project`

---

## Steps

### 1 — Confirm the repo URL

Ask the user (or use the default):
> "Which starter-kit repo should I use? Default: `https://github.com/handharr-labs/nextjs-arch`"

If the user says "default" or provides no URL, use `https://github.com/handharr-labs/nextjs-arch`.

### 2 — Add submodule

```bash
git submodule add <STARTER_KIT_URL> .claude/starter-kit
```

### 3 — Create symlinks

```bash
cd .claude
ln -s starter-kit/agents     agents
ln -s starter-kit/docs       docs
ln -s starter-kit/hooks      hooks
ln -s starter-kit/nextjs-arch nextjs-arch
ln -s starter-kit/skills     skills
cd ..
```

### 4 — Make hooks executable

```bash
chmod +x .claude/starter-kit/hooks/*.sh
```

### 5 — Copy and prompt for CLAUDE.md

```bash
cp .claude/starter-kit/CLAUDE-template.md CLAUDE.md
```

Tell the user:
> "I've created `CLAUDE.md` from the template. Please fill in the placeholders:
> - `[AppName]` — your project name
> - `[One-line description...]` — what the app does
> - `[Database]`, `[ORM]`, `[Auth]`, `[UI library]`, `[Test framework]` — your chosen stack
> - `src/features/{auth,[feature-a],...}` — your actual feature names"

### 6 — Create project-specific agent overrides stub

Create `.claude/agents.local/arch-reviewer.local.md`:

```markdown
# arch-reviewer — project-specific rules

> Additive rules for this project. The baseline is in `.claude/starter-kit/agents/arch-reviewer.md`.

<!-- Add project-specific audit rules below -->
```

Also add to `CLAUDE.md` (before the closing line):

```markdown
## Project-specific agent rules
`.claude/agents.local/` — additive rules on top of the shared starter-kit agents.
```

### 7 — Stage and summarize

```bash
git add .gitmodules .claude/ CLAUDE.md
```

Tell the user what was done:
- `.claude/starter-kit/` — submodule pointing to the starter kit repo
- `.claude/{agents,docs,hooks,nextjs-arch,skills}` — symlinks into the submodule
- `CLAUDE.md` — copied from template (needs placeholder fill-in)
- `.claude/agents.local/arch-reviewer.local.md` — stub for project-specific arch rules

---

## Updating the starter kit later

```bash
cd .claude/starter-kit && git pull && cd ../..
git add .claude/starter-kit
git commit -m "chore: bump nextjs-arch starter kit"
```
