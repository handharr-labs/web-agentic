> Author: Puras Handharmahua · 2026-04-08
> Synced with: software-dev-agentic v3.21.0
> Related: Shared Agentic Submodule Architecture — Cross-Platform Scaling

## What is an Agentic Coding Assistant?

A coding assistant where Claude autonomously routes, decides, and executes based on natural language — without the user needing to know which tool, command, or workflow to invoke. The user describes intent. The assistant figures out the rest.

> No slash commands. No manual chaining. No context pollution.

---

## Core Design Principles

### 1. Natural Language as the Entry Point

There are two valid entry points into the agentic system:

**A — Natural language routing (default):** Users describe what they want; Claude matches the intent to an agent's description and spawns it automatically. No slash commands, no manual chaining.

**B — Trigger skill:** A user-invocable skill (`user-invocable: true`) that explicitly spawns an agent workflow. Use this when the entry point is a specific, named operation — not open-ended intent. The skill handles the invocation; the agent handles the work.

> Agent descriptions must be precise and use vocabulary developers naturally say. Routing is only as good as the description.

> Not every request needs an agent. If a change is simple and localized (rename a variable, fix a typo, add an import), act directly — the cost of delegation exceeds the task itself.

---

### 2. Agents = Brain (Decision-Maker)

Agents are intelligent specialists, not task executors. Each agent:

- Assesses context before acting (does this file exist? which pattern applies?)
- Decides which procedure to execute
- Handles edge cases and branching logic
- Knows *what* to do and *when*

Agents stay lean — they don't embed step-by-step instructions. That belongs in skills.

**Orchestrators — Multi-Worker Coordinators:**

Orchestrators coordinate multiple worker agents using the `agents` field in frontmatter. Key rules:

- Spawn only relevant workers — never all of them
- Pass file paths between phases, never file contents
- Use `isolation: worktree` unless phases share uncommitted files
- Validate each worker's `## Output` before proceeding — STOP if missing or paths don't exist
- Never read the codebase directly — workers own their own context reads

**Agent Scope — Core vs Platform-specific:**

Agents have a second axis — where they live and what they know.

- **Core** (`lib/core/agents/`) — platform-agnostic. Work on any platform. Add here when the behaviour is identical across all platforms.
- **Platform-specific** (`lib/platforms/<platform>/agents/`) — exist only when the workflow diverges enough from core to need its own agent. Examples: iOS `test-orchestrator` (knows `xcodebuild`), iOS `pr-review-worker` (knows Swift/UIKit conventions). Do not add a platform agent unless a core agent + platform skills cannot handle it.

> For the full agent roster, see [persona-builder.md](persona-builder.md).

**Agent Memory Governance:**

**What to remember:** Confirmed patterns, module-specific conventions not in reference docs, recurring mistakes, user-confirmed preferences.

**What NOT to remember:** Current task details, anything already in `CLAUDE.md` or `reference/`, unverified single-file observations, git history.

**Hygiene rules:** Keep `MEMORY.md` under 200 lines; use topic files for detailed notes; review and prune stale memories.

**Agent Naming Convention:**

| Type | Suffix | Example |
|---|---|---|
| Orchestrator | `-orchestrator` | `feature-orchestrator.md`, `pres-orchestrator.md` |
| Worker | `-worker` | `domain-worker.md`, `data-worker.md` |

Format: `<domain>-<role>.md`

> The filename suffix tells you the agent type instantly — no need to open the file.

---

### 3. Skills = Hands (Thin Procedures)

Skills are focused, reusable workflow procedures. Each skill:

- Does one thing only
- References architecture docs — never embeds them
- Has no branching logic — agent decides which skill to call

Target: under 30 lines per skill

> Naming: `<layer>-<action>-<target>`. Split by intent: `create-*` for new, `update-*` for existing. Keep `SKILL.md` under 500 lines. Skills are either **core-dependency** (same name on all platforms) or **platform-specific** (one platform only) — see [persona-builder.md](persona-builder.md).

**Preloading skills:**

Agents load their procedure skills at startup via the `skills` field — full skill content is injected at startup. This gives agents full procedural knowledge without embedding it in their body. Same procedures are reusable across multiple agents. One definition, updated once.

**Token budget guideline:**
- Preload skills the agent needs in >50% of its invocations
- Load on demand (via `Read`) skills needed rarely or only in edge cases
- Monitor total preloaded size — if it exceeds ~500 lines, split the agent or move low-frequency skills to on-demand

**Invocation types:**

| Type | Config | Who triggers | Context cost | Use for |
|---|---|---|---|---|
| A — Internal procedure | `user-invocable: false` | Agent only | Zero | Standard build/update workflows |
| B — User-controlled | `disable-model-invocation: true` | User only | Zero | Destructive or side-effect operations |
| C — Default | *(no config)* | Both | Description always loaded | Intentionally avoided |

**Why no Type C:** Every default skill's description loads into the main session context. Type A and B both eliminate this overhead.

---

### 4. Taxonomy

#### Persona

A named group of related agents serving a coherent workflow.

Requirements:
- Lives in `lib/core/agents/<persona>/`
- Has at least one worker or orchestrator
- Agents within the group relate to and can depend on each other
- Requires a `.pkg` file for selective installation

Shared to all downstream projects via symlink. Current personas: `builder`, `detective`, `tracker`, `auditor`, `installer`.

> A persona is not just a folder. It represents a coherent workflow. Do not group unrelated agents into a persona subdirectory.

#### Agents — By Role

| Role | Subordinates | Can write files? | Has `agents` field? | Has `skills` field? |
|---|---|---|---|---|
| Orchestrator | Other orchestrators or workers | No — delegates all writes to workers | Yes | Typically no |
| Worker | Skills via `related_skills` | Yes | No | Yes — skills injected at startup |

> Orchestrators may spawn other orchestrators when the inner orchestrator represents a fully bounded sub-workflow. The outer orchestrator owns the top-level state file and final report. Example: `feature-orchestrator` spawns `pres-orchestrator` for the presentation+UI phase — `pres-orchestrator` skips state file writes when called as a sub-orchestrator.

#### Agents — By Scope

| Scope | Location | Ships downstream? |
|---|---|---|
| **Persona agent** | `lib/core/agents/<persona>/` | Yes — all platforms |
| **Platform agent** | `lib/platforms/<platform>/agents/` | Yes — matching platform only |
| **Project agent** | `.claude/agents.local/` | No — project-owned, not in this repo |

> Persona agents must be platform-agnostic — no platform paths, framework references, or language syntax in the body (Critical per P6).

#### Skills — By Invocation Type

| Type | Config | Who triggers | Use for |
|---|---|---|---|
| **A — Regular** | `user-invocable: false` | Worker (agent) only | Standard build/update procedures |
| **B — Destructive** | `disable-model-invocation: true` | User only | Destructive or side-effect operations |
| **T — Trigger** | `user-invocable: true` + uses `Agent` tool | User only | Entry point that spawns an agent workflow |
| **U — Utility** | `user-invocable: true`, no `Agent` tool | User only | Self-contained interactive tool — runs with model, does not spawn agents |

> **Type T vs Type U:** Both are user-invocable and model-run. Type T spawns an agent workflow (`agentic-perf-review` → `perf-worker`). Type U does its own work directly (`doctor`, `clear-runs`, `release`).
>
> **Type B vs Type U:** Both are user-only. Type B disables model invocation entirely (pure bash, no reasoning). Type U runs with model invocation for interactive behaviour.

**Why no Type C (default — both user and agent):** Every default skill's description loads into the main session context on every turn. Types A, B, T, and U all eliminate this overhead.

#### Skills — By Scope

| Scope | Location | Ships downstream? |
|---|---|---|
| **Toolkit skill** | `lib/core/skills/` | Yes — all platforms. Platform-agnostic, intended for use in downstream projects. |
| **Platform-contract skill** | `lib/platforms/<platform>/skills/contract/` | Yes — matching platform. Same name across all platforms; each implements for its syntax — called by persona workers. Lands flat in `.claude/skills/<name>/` downstream. |
| **Platform-only skill** | `lib/platforms/<platform>/skills/` (flat) | Yes — matching platform only. Called by platform agents. |
| **Project skill** | `.claude/skills.local/` | No — project-owned, not in this repo. |
| **Repo skill** | `skills/` (root) | No — internal tooling only. Used by this repo's internal agents; never symlinked to downstream projects. |

> "Core-dependency skill" used in earlier sections of this doc refers to platform-contract skills — skills all platforms must implement under the same name (`domain-create-entity`, `data-create-mapper`, etc.).

#### Skills — Valid Type × Scope Combinations

Not all combinations are meaningful. Use this as the decision gate when adding a new skill:

| Scope | A — Regular | B — Destructive | T — Trigger | U — Utility |
|---|---|---|---|---|
| Toolkit | — | — | ✓ | ✓ |
| Platform-contract | ✓ | — | — | — |
| Platform-only | ✓ | ✓ | — | — |
| Project | ✓ | ✓ | ✓ | ✓ |
| Repo | ✓ | — | ✓ | ✓ |

> Toolkit skills are always user-facing (Type T or U) — agents don't call them, workers call platform-contract skills instead. Platform-contract skills are always Type A — they're called by workers programmatically, never by users directly.

---


### 5. Context Isolation = Efficiency

Every agent runs in its own isolated context window — completely separate from the main session. This is the primary mechanism for token efficiency.

From the official docs:
> *"Preserve context by keeping exploration and implementation out of your main conversation"*

When a worker reads reference docs, scans existing files, and writes code — none of that touches your main session context. The main session only sees the result.

---

### 6. Knowledge Architecture

**Three-tier structure:**

| Tier | Location | What goes here |
|---|---|---|
| 1 | `CLAUDE.md` | Universal rules applying to every task — naming, principles, build command. ~1 page max |
| 2 | Agent body | Decision logic for that agent only — what to do, when to do it |
| 3 | `.claude/reference/` | Shared deep reference — patterns, examples, conventions. Loaded on demand via Grep-first |

> Folder structure for reference docs: see [shared-submodule-arch.md](shared-submodule-arch.md).

**Placement decision rule — reference vs agent body:**

| Put it in reference if… | Keep it in the agent body if… |
|---|---|
| It is a fact true regardless of who reads it | It is an instruction specific to this agent's workflow |
| It is an invariant, contract, or architectural principle | It is a decision: when to run, what to check, what to do on failure |
| Multiple agents need the same knowledge | Only this agent needs it |
| Removing it from the agent would lose shared truth | Removing it from the agent would lose execution behavior |

> One-line test: can you state it as a rule without saying "you"? If yes — reference. If it only makes sense addressed to the agent — agent body.

**Enforcement — Search Protocol (decision gate):**

Before any `Read` call, workers answer: "Do I need the full file, or just a specific symbol/section?"

| What you need | Tool |
|---|---|
| A specific class, function, or type | `Grep` for the name |
| A section of a reference doc | `Grep` for the section heading |
| The full file structure (style-matching a new file) | `Read` — justified |
| Whether a file exists | `Glob` |

Read a full file only when: (a) you need its complete structure to write a new matching file, or (b) Grep returned no results. Check `reference/index.md` first if uncertain which file covers a topic.

> Read:Grep ratio should stay below 3. A ratio above 6 is a P6 violation.

---



### 7. Fail-Fast Precondition Validation

Agents validate preconditions before executing procedures — they never guess or proceed with assumptions.

**Workers check on entry (`## Input`):**
- Are all required spawn parameters present? — return `MISSING INPUT: <param>` immediately if not
- Is the task within this worker's layer scope? — STOP and name the correct worker if not

**Workers check before writing (`## Preconditions`):**
- Does the target file/module exist? (before `update-*` skills)
- Does the target file/module NOT exist? (before `create-*` skills — avoid overwriting)
- Are required dependencies available?

**Workers check before returning (`## Output`):**
- Does each created file exist on disk? (`Glob`)
- Does each file contain the expected primary class or function? (`Grep`)
- Only list paths that pass both checks

**Orchestrators check after each worker spawn:**
- Does the worker response contain an `## Output` section?
- Do all listed paths exist on disk?
- If either check fails: STOP — do not proceed to the next phase

When any check fails: return a clear, actionable message — never partially execute or silently continue.

---


### 8. Official Docs Compliance

Every design decision must comply with Claude Code's official documentation.

**Compliance checklist:**
- Skill directories follow `.claude/skills/<name>/SKILL.md` convention
- Agent files follow `.claude/agents/<name>.md` convention
- Frontmatter fields use only documented keys
- Memory scopes and permission modes use documented values

Known undocumented but functional fields: `agents` field — empirically verified to work; not in official spec. Use with awareness that it may change.

---


### 9. Convention Enforcement — Self-Auditing Architecture

The agentic system enforces its own conventions through automated review — the same principle applied recursively.

**The internal convention system** (root `agents/` and `skills/` — NOT symlinked to downstream projects):

**What `arch-check-conventions` enforces:**

| Category | Rule | Severity |
|---|---|---|
| Frontmatter | `name`, `description`, `model`, `tools` required | Critical |
| Model assignment | `sonnet` for all workers; `haiku` only for truly mechanical leaf tasks with no architectural judgment | Warning |
| Orchestrators | `isolation: worktree` inline with each Spawn directive — omit only when phases share uncommitted files (e.g. `pres-orchestrator` contract handoff) | Critical |
| Orchestrators | File paths only between phases | Critical |
| Orchestrators | Writes state file after each phase | Warning |
| Orchestrators | No Phase 2 codebase reads | Critical |
| Orchestrators | After delegation flag set, no direct Edit or Write — all file changes through workers | Critical |
| Orchestrators | Explicit output validation after each worker spawn — STOP if `## Output` missing or paths don't exist on disk | Critical |
| Workers | `## Input` section — required params table + `MISSING INPUT` STOP condition | Critical |
| Workers | `## Scope Boundary` section — owned layer + delegation table for out-of-scope tasks | Warning |
| Workers | `## Task Assessment` section — skill vs direct edit decision gate | Warning |
| Workers | `## Skill Execution` section — platform path resolution + Read SKILL.md + follow | Critical |
| Workers | `## Search Protocol` section with decision gate table | Warning |
| Workers | `## Output` section — Glob + Grep verification before listing paths | Critical |
| Workers | `## Extension Point` section at end | Warning |
| Workers | No "Read ... completely" | Critical |
| Core agent platform-agnosticism | No hardcoded platform paths, framework refs, or language syntax in `lib/core/agents/` body | Critical |
| Fix F | Multi-file `Reference:` lines mention `reference/index.md` | Warning |
| Fix G | Template files: code hints only, no explanatory comments | Warning |
| Naming | `-orchestrator`/`-worker.md`; skill dirs `<layer>-<action>-<target>` | Info |
| Prompt Clarity | No ambiguous scope ("create the X" without specifying interface vs implementation); no instructions spanning two CLEAN layers without a stop condition; no contradicting rules; failure paths specified. Run `prompt-debug-worker` for deeper runtime reasoning analysis. | Warning |

**Platform-agnosticism rule:**
> `lib/core/` agents are consumed by ALL platforms via symlink. Platform-specific rules embedded in a core worker silently mislead workers on other platforms. Any match of platform paths, framework names, or language syntax in a `lib/core/agents/` body is a Critical violation.

**The two distinct reviewers:**

| Reviewer | Reviews | Location |
|---|---|---|
| `agents/arch-review-worker.md` | Agent/skill files in *this repo* for convention compliance | Root `agents/` — internal only |
| `lib/core/agents/auditor/arch-review-worker.md` | Application code in *downstream projects* for CLEAN violations | Symlinked to all platforms |

**Doc sync system:** Design docs are synced manually after sessions that change structure or conventions. `docs-sync-worker` accepts a session delta description, verifies repo state, and applies targeted section updates. `docs-identify-changes` maps delta topics to stale sections. This enforces the principle: fix implementation first, then sync design docs.

---


## Decision Rules

| Situation | Where it goes |
|---|---|
| New CLEAN-layer behaviour, same on all platforms | Core worker |
| New orchestration flow, same on all platforms | Core orchestrator |
| New code generation pattern for one platform | Platform-contract skill (same name, platform implements) → `lib/platforms/<platform>/skills/contract/` |
| Workflow too platform-specific for any core agent | Platform agent + platform skill → `lib/platforms/<platform>/skills/` (flat) |
| Architecture reference knowledge (cross-platform standard) | `lib/platforms/<platform>/reference/contract/` — same filename on every platform; accessible as `.claude/reference/contract/<name>.md` downstream |
| Architecture reference knowledge (platform-specific) | `lib/platforms/<platform>/reference/` (flat) |

> For execution examples and the current agent roster, see [persona-builder.md](persona-builder.md).

---

## Folder Design Rationale

| Decision | Why |
|---|---|
| All workers in `lib/core/agents/` | DI at skill level — platform-agnostic brains |
| Persona subdirectories | Workflow cohesion; selective installation; self-documenting |
| `perf-worker.md` stays flat | No persona peers yet |
| Root `agents/` and `skills/` | Internal tooling — not downstream API surface |
| `lib/` boundary | Explicit distributable surface — everything under `lib/` ships, everything outside is tooling |
| `arch-review-worker` platform-agnostic (P6) | Core workers must not embed platform knowledge |
| `docs-sync-worker` in root `agents/` | Maintains this repo's design docs — not relevant to downstream consumers |
| `setup-worker` in `lib/core/agents/installer/` | Platform-agnostic setup logic; delegates mechanical steps to platform skills |

---

## Why This Architecture

| Goal | How it's achieved |
|---|---|
| Token efficiency | Isolated context; Search Protocol decision gate; Haiku for mechanical workers; file paths only between phases; orchestrator state files prevent mid-run re-reads |
| Modular knowledge | Skills preloaded, not embedded |
| Single source of truth | `reference/` Grep-accessed, never duplicated |
| Safe destructive operations | `disable-model-invocation: true` on Type B |
| Reusability | Same skill preloaded into multiple workers |
| Maintainability | Update one skill → all workers get the update |
| Multi-platform scalability | Add `lib/platforms/<platform>/skills/` — no agent changes |
| Selective installation | Persona `.pkg` files |
| Self-enforcing conventions | Internal arch-reviewer catches violations before downstream consumers |
| Design doc fidelity | `docs-sync-worker` keeps Confluence in sync after every structural session |
| Clear distributable boundary | `lib/` = ships downstream; everything outside = internal tooling |
| Agent prompt quality | `prompt-debug-worker` surfaces ambiguous instructions when perf scores flag low D1–D7 |

---

## Official Documentation

| Topic | URL |
|---|---|
| Subagents | https://code.claude.com/docs/en/sub-agents |
| Skills | https://code.claude.com/docs/en/skills |
| Context window | https://code.claude.com/docs/en/context-window |
| Agent Teams | https://code.claude.com/docs/en/agent-teams |
| Hooks | https://code.claude.com/docs/en/hooks |
| MCP | https://code.claude.com/docs/en/mcp |
| Memory & CLAUDE.md | https://code.claude.com/docs/en/memory |
| Settings | https://code.claude.com/docs/en/settings |
| Permissions | https://code.claude.com/docs/en/permissions |

---

## Changelog

See [changelog-core-design-principles.md](changelog-core-design-principles.md).
