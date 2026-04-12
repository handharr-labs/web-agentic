---
name: arch-check-conventions
description: Audit a set of agent or skill files against software-dev-agentic conventions and journey/01-token-optimization.md fixes. Returns structured findings per file.
user-invocable: false
tools: Read, Glob, Grep
---

Audit the provided files against the conventions below. Return findings grouped by file.

## Agent Checklist

For each `.md` agent file:

**Frontmatter (required fields)**
- [ ] `name` present
- [ ] `description` present and specific enough for routing
- [ ] `model` present — `haiku` for mechanical workers (domain, data, test), `sonnet` for orchestrators and reasoning-heavy workers
- [ ] `tools` present

**Orchestrators** (files with `agents:` frontmatter field)
- [ ] `agents:` field lists only workers it actually spawns
- [ ] Constraints section contains `isolation: worktree`
- [ ] Body passes only file path lists between phases — never file contents
- [ ] No Phase 2 codebase reads on behalf of workers

**Workers** (files without `agents:` frontmatter field)
- [ ] `## Search Rules` section present with Grep-before-Read rule
- [ ] `## Extension Point` section present at end of file
- [ ] No reference doc reads that say "Read ... completely"
- [ ] All `Reference:` lines use Grep-first pattern

**Core agents** (files under `core/agents/`) — Platform-Agnosticism
- [ ] Body contains no hardcoded platform-specific file paths — no `src/domain/`, `src/data/`, `src/presentation/`, `Talenta/Module/`, `lib/`, `app/`
- [ ] Body contains no platform framework references used as rules — no `React`, `Next.js`, `RxSwift`, `UIKit`, `BLoC`, `axios`, `next-safe-action`
- [ ] Body contains no platform language-specific syntax used as rules — no `'use client'`, `'use server'`, `readonly` (TypeScript), `BehaviorRelay`
- [ ] Platform-specific knowledge is delegated to a skill (`related_skills` field), not embedded inline

How to check: `Grep` the file for any of the above patterns. A match in the body (outside of a `related_skills` reference or a comment acknowledging the skill) is a Critical violation.

> **Why:** Core agents are consumed by all platforms via symlink. Platform-specific rules embedded in a core worker silently mislead workers on other platforms (iOS, Flutter) that call the same agent.

**All agents**
- [ ] Filename follows `<domain>-orchestrator.md` or `<domain>-worker.md` convention
- [ ] If in a persona subdir (`builder/`, `detective/`, `tracker/`, `auditor/`), the persona assignment is correct

## Skill Checklist

For each `SKILL.md` skill file:

**Frontmatter (required fields)**
- [ ] `name` present
- [ ] `description` present
- [ ] `user-invocable: false` present (or omitted only for user-facing skills)

**Reference doc reads**
- [ ] No step says `Read .claude/reference/... completely`
- [ ] Any step reading a reference doc uses `Grep` for section keyword first
- [ ] All referenced file paths match actual filenames in `platforms/<platform>/reference/` or `core/reference/`

**Naming**
- [ ] Skill directory name follows `<layer>-<action>-<target>` convention
- [ ] Layer prefix matches the agent that calls it (`domain-`, `data-`, `pres-`, `test-`, `debug-`, `review-`)

## Severity Levels

- **Critical** — missing required frontmatter field, broken reference path, "Read completely" violation, orchestrator missing `isolation: worktree`, platform-specific content in a `core/agents/` file
- **Warning** — wrong model for worker type, missing Search Rules, missing Extension Point
- **Info** — naming convention deviation, description could be more specific

## Output Format

Return raw findings — do not format into a report. `arch-generate-report` handles formatting.

```
FILE: <path>
  [CRITICAL] <rule> — <specific violation>
  [WARNING]  <rule> — <specific violation>
  [INFO]     <rule> — <specific violation>
PASS: <path>  (no findings)
```
