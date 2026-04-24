# Stakeholder Deck — HTML Presentation Plan

> Primary source: `docs/stakeholder-brief.md`
> Supporting context: `docs/core-design-principles.md` · `docs/submodule-repo-structure.md`
> Output: `docs/deck/index.html`
> Status: Planning

---

## Source Docs — Role in the Deck

| Doc | What it covers | Role in the deck |
|---|---|---|
| `stakeholder-brief.md` | Non-technical narrative: problem, solution, AI team analogy, results, business outcomes | **Primary source** — almost all slide content comes from here |
| `core-design-principles.md` | Agent/persona conventions: roles (Orchestrator/Planner/Worker/Skill), knowledge rules, skill types, taxonomy, anatomy | **Background context** — informs "How It Works", "Meet the Team", and "Plan First" slides; not cited directly |
| `submodule-repo-structure.md` | Distribution mechanism: how the toolkit ships to downstream projects, folder layout, symlink architecture, setup scripts | **Background context** — informs the "One toolkit, every platform" differentiator; not cited directly |
| `persona/builder.md` | Builder anatomy: dual entry skills, planner phase (parallel sub-planners), feature-worker execution, layer-to-agent mapping | **Background context** — informs Slide 13 "In Action" walkthrough |
| `persona/detective.md` | Detective anatomy: scientific debugging method, step-to-agent mapping, tool isolation guarantee | **Background context** — informs "Meet the Team" detective row |

The brief is a deliberate translation of the principles docs into language a non-engineer can follow. The deck should stay at that level of abstraction.

---

## Decisions

| # | Question | Answer |
|---|---|---|
| 1 | Audience | Internal engineers + leadership. Basic IT literacy assumed. No external. |
| 2 | Framework | Vanilla HTML — single self-contained file, no dependencies |
| 3 | Platform scope | Yes — web (Next.js) included alongside iOS + Flutter |
| 4 | Branding | Mekari brand colors + engineering style (not exec-soft) |
| 5 | Delivery | Presented live — needs keyboard navigation (arrow keys) |

### One remaining question — Mekari brand colors

Do you have the exact hex codes handy? If not, I'll use the known Mekari palette as a baseline:
- Primary green: `#00C48C` (or confirm)
- Dark background for engineering feel: `#0F1117`
- Text: `#F5F5F5`

Confirm or correct before build starts.

---

## Proposed Slide Structure

| # | Slide Title | Notes |
|---|---|---|
| 1 | Cover — "We Gave Our Engineers an AI Team" | Tagline + date |
| 2 | The Problem (intro) | Frame: system problem, not people problem |
| 3 | Problem 1 — Bloated context | Code: bloated CLAUDE.md / agent file (Flutter/Dart) |
| 4 | Problem 2 — Knowledge not isolated | Code: fat agent body vs. Grep-first (Flutter/Dart) |
| 5 | Problem 3 — No shared agents | Code: duplicated agent dirs across Flutter projects |
| 6 | How We Solved It — The Architecture | Transition: 3 answers to 3 problems |
| 7 | Solution: Grep over Read | Code: Grep 12 lines vs Read 200 lines, token delta |
| 8 | Solution: Prompt Caching | Diagram: what gets cached, when, how much it saves |
| 9 | Solution: Shared Submodule | Symlink diagram: one file → all projects |
| 10 | What We Built | Not a chatbot. A 5-layer hierarchy of specialists. |
| 11 | How It Works — Anatomy | The full layer diagram: Trigger Skill → Orchestrator → Planner(s) → Worker → Skills |
| 12 | Plan First, Then Build | Planner decision rule: simple task → worker directly; complex/unknown → planner first |
| 13 | Meet the Team | Persona table: Builder, Detective, Auditor, Tracker, Installer — roles per persona |
| 14 | In Action — Leave Request | Full build walkthrough with planner phase (parallel sub-planners → approval → feature-worker) |
| 15 | Results | 34-file feature · 85% cost ↓ · 6.3→8.0 quality |
| 16 | Where We're Going | Android · Broader scope · Shorter feedback loops |
| 17 | Closing — One Sentence | Full-bleed quote slide |

Total: **17 slides** (+1 from adding the Planner decision slide; prior "How It Works" split into Anatomy + Plan First)

> **Cut option:** Slides 11 and 12 can be merged into a single "How It Works" slide if 17 feels long — show the anatomy diagram on the left, the Planner vs Worker rule on the right.

---

## Problem Slides — Deep Dive

### Slide 3 — Problem 1: Bloated Context

**Headline:** Every task loads knowledge that isn't needed

**The pattern engineers hit:**
Agent files and `CLAUDE.md` grow over time — architecture docs, layer rules, platform conventions, examples all get pasted in directly. The agent "knows everything" but pays for it on every single call.

**Code example — bad (everything embedded):**
```
# CLAUDE.md
## Domain Layer Rules
- Entities must be pure Dart classes, no Flutter imports
- Use cases must extend UseCase<Params, Result>
- Repository interfaces live in domain/repository/
- Never import dio, hive, or any data layer package
- Always throw DomainException for business rule violations
[... 200 more lines of architecture rules ...]

## Data Layer Rules
- Response models must be annotated with @JsonSerializable
- Mappers must implement Mapper<RemoteModel, DomainEntity>
[... 150 more lines ...]

## BLoC / Presentation Layer Rules
...
```

**Code example — good (lean CLAUDE.md, knowledge in reference):**
```
# CLAUDE.md  (~1 page total)
## Stack
Flutter · Dart · BLoC · Clean Architecture

## Key Rules
- Domain layer: zero Flutter/package imports
- Naming: feature-orchestrator, domain-worker, data-worker
- Reference docs live in .claude/reference/ — agents load on demand
```

**Caption:** Bloated `CLAUDE.md` = tokens wasted on every turn, even when the agent is just creating a UI widget.

---

### Slide 4 — Problem 2: Knowledge Not Isolated

**Headline:** The agent reads everything. Even what it doesn't need.

**The pattern engineers hit:**
An agent that handles domain logic also embeds data layer patterns, BLoC conventions, and Dart code examples — all loaded upfront. Every invocation pays the full cost, regardless of what the task actually needs.

**Code example — bad (fat agent body, everything embedded):**
```markdown
# domain-worker.md

You are the domain layer specialist.

## Domain Rules
An entity is a pure Dart class. No Flutter imports.
Example:
  class LeaveRequest {
    final String id;
    final LeaveStatus status;
    const LeaveRequest({required this.id, required this.status});
  }

A use case implements UseCase<Params, Result>.
Example:
  class SubmitLeaveRequestUseCase implements UseCase<LeaveParams, void> { ... }

## Data Layer Patterns  ← ❌ not this worker's concern
Response models use @JsonSerializable. Mappers implement Mapper<R, D>.
Example:
  @JsonSerializable()
  class LeaveRequestResponse { ... }

## BLoC Patterns  ← ❌ belongs in presentation-worker
Events extend Equatable. States are sealed classes.
...
[450 lines total]
```

**Code example — good (lean worker + Grep-first reference):**
```markdown
# domain-worker.md  (~80 lines)

You are the domain layer specialist. You own domain/ only.
For layer contracts: Grep "^## Entity" in reference/contract/builder/domain.md

## Scope Boundary
Own:     domain/entities/, domain/usecases/, domain/repository/
Delegate data layer work      → data-worker
Delegate BLoC / UI work       → presentation-worker, ui-worker
```
```
# At runtime — worker only loads what it needs:
Grep("^## Entity", "reference/contract/builder/domain.md")
# → 15 lines loaded. Not 450.
```

**Caption:** Isolated context = agents only pay for the knowledge they actually use. This is the primary driver behind the 85% token reduction.

---

### Slide 5 — Problem 3: No Shared Agents

**Headline:** Three projects. Three copies. Three drift paths.

**The pattern engineers hit:**
Each project maintains its own `.claude/agents/` directory. When the xpnsio team improves `domain-worker`, that improvement stays on xpnsio. wehire never sees it. talenta-iOS diverges on its own. Six months later, the "same" agent behaves differently on every platform.

**Code example — bad (duplicated, diverging agents):**
```
xpnsio/                      ← Flutter project
  .claude/agents/
    domain-worker.md         ← updated last month, added BLoC rules by mistake
    data-worker.md           ← has project-specific hacks baked in

wehire/                      ← another Flutter project
  .claude/agents/
    domain-worker.md         ← copy-pasted from xpnsio 3 months ago, now drifted
    data-worker.md           ← different conventions

talenta-ios/
  .claude/agents/
    domain-worker.md         ← Swift/UIKit version, entirely separate evolution
```

**Code example — good (single source, symlinked):**
```
software-dev-agentic/            ← shared submodule
  lib/core/agents/builder/
    domain-worker.md             ← ONE file. Updated once, every project gets it.
    data-worker.md
  lib/platforms/flutter/skills/  ← Flutter knowledge lives here, not in the agent
  lib/platforms/ios/skills/      ← iOS knowledge lives here
  lib/platforms/web/skills/

xpnsio/.claude/agents/domain-worker.md       → symlink  ──┐
wehire/.claude/agents/domain-worker.md       → symlink  ──┤── same file
talenta-ios/.claude/agents/domain-worker.md  → symlink  ──┘
```

**Caption:** One improvement to `domain-worker` ships to all three products simultaneously. No copy-paste. No drift.

---

## Solution Slides — Deep Dive

### Slide 6 — Transition: How We Solved It

**Headline:** Three problems. Three architectural answers.

| Problem | Solution |
|---|---|
| Bloated context | Lean agents + tiered knowledge architecture |
| Knowledge not isolated | Grep over Read — load only what's needed |
| No shared agents | Git submodule — one file, symlinked everywhere |

*(This slide is a pivot — from "here's what's broken" to "here's the system we built")*

---

### Slide 7 — Solution: Grep over Read

**Headline:** Don't read the book. Look up the page.

**The principle (from `core-design-principles.md` — Search Protocol):**
Before any `Read`, workers answer: "Do I need the full file, or just a specific section?"

**Code example — bad (reading the whole reference file):**
```
# Agent reads entire domain reference doc
Read("reference/contract/builder/domain.md")
# → 200 lines loaded into context
# → Costs tokens on every invocation, even for a 5-line entity
```

**Code example — good (Grep for exactly the section needed):**
```
# Agent greps only the section it needs
Grep("^## Entity", "reference/contract/builder/domain.md")
# → 15 lines loaded. The rest: zero cost.

Grep("^## UseCase", "reference/contract/builder/domain.md")
# → 18 lines loaded. Only when creating a use case.
```

**Token impact table:**
| Operation | Lines loaded | Tokens (est.) |
|---|---|---|
| Read full domain.md | 200 lines | ~1,800 |
| Grep `## Entity` | 15 lines | ~135 |
| Savings per call | — | **~93%** |

**Rule enforced in the system:** Read:Grep ratio must stay below 3. Above 6 is a convention violation — caught by the internal arch-reviewer before it reaches any project.

**Caption:** At scale, across 34 files and 5 layers, this compounds — and it's why the system dropped from 737k tokens to 103k per session.

---

### Slide 8 — Solution: Prompt Caching

**Headline:** Pay once. Reuse many times.

**What prompt caching is:**
Claude caches the stable part of a context (system prompt, preloaded skills, agent file) after the first call. Subsequent calls within the same session reuse the cache at significantly reduced cost.

**What the architecture is designed to cache:**
```
┌─────────────────────────────────────┐  ← stable — cached after first call
│  Agent system prompt                │    (agent file content)
│  Preloaded skills (SKILL.md files)  │    (injected at startup via `skills:`)
│  CLAUDE.md                          │    (universal project rules)
└─────────────────────────────────────┘
         ↓ cache boundary ↓
┌─────────────────────────────────────┐  ← dynamic — not cached
│  Current task / user message        │
│  Grepped reference snippets         │
│  Worker output from prior phases    │
└─────────────────────────────────────┘
```

**Why the architecture maximises cache hits:**
- Agent files are stable → cache hit on every subsequent worker spawn in a session
- Preloaded skills are injected once at startup → cached for the whole session
- Reference snippets are small (Grep-first) → low cost even on cache miss
- CLAUDE.md is short (~1 page) → small stable prefix, high cache efficiency

**Key insight:** In a 5-worker feature build, the stable prefix is paid for once. Workers 2–5 reuse it from cache. The more workers in a session, the more the savings compound.

**Caption:** Lean agents + Grep-first + caching = the cost curve bends down as usage goes up, not up.

---

## New / Updated Slides — Deep Dive

### Slide 11 — How It Works: Anatomy

**Headline:** Five layers. Each one knows exactly its job.

**Visual:** HTML/CSS tree diagram, top-to-bottom flow:

```
User
 │
 ▼
Trigger Skill        — routes the request, pre-loads run context, builds the spawn prompt
 │
 ▼
Orchestrator         — coordinates phases in order; zero file writes
 │
 ▼
Planner(s)           — explore the codebase; produce a reviewable plan; zero source writes
 │
 ▼
Worker               — reads the approved plan; executes skills; validates every artifact
 │
 ▼
Skills               — concrete platform code (Swift, Dart, TypeScript)
```

**Key callout (right panel or annotation):**
- Each layer has one job — it cannot reach into another
- Planner reads; Worker writes — never mixed
- Skills are the only platform-aware layer — everything above is platform-agnostic

**Caption:** Not a monolith. A chain of specialists — each accountable for its own scope.

---

### Slide 12 — Plan First, Then Build

**Headline:** Scope first. Code second. No rework.

**The decision rule (two-column layout):**

| Work profile | Path |
|---|---|
| Single artifact, known location | Worker directly — planning overhead exceeds the benefit |
| Cross-layer feature, uncertain existing state | Planner first → Worker — exploration is front-loaded |
| Targeted edit to existing file | Worker directly with key symbols from context |
| Complex change, unknown conventions | Planner first — sub-planners explore in parallel |

**Visual — parallel planner phase:**
```
feature-planner
  │         │         │
  ▼         ▼         ▼
domain-   data-    pres-
planner   planner  planner    ← all three run simultaneously
  │
  │  [findings aggregated → plan.md written → user approves]
  │
  ▼
feature-worker               ← executes the plan; one artifact at a time
```

**Caption:** Planners front-load the thinking cost so the worker executes without guessing. Parallel sub-planners mean exploration is as fast as the slowest layer — not the sum of all three.

---

### Slide 13 — Meet the Team

**Headline:** Five personas. Each a coherent specialist workflow.

**Table (updated — Planner now a distinct role column):**

| Persona | Entry | Orchestrator | Planner(s) | Worker(s) | What it does |
|---|---|---|---|---|---|
| Builder | `/feature-orchestrator`, `/plan-feature` | `feature-orchestrator` | `feature-planner` + 3 layer planners | `feature-worker`, layer workers | Full CLEAN feature build — domain → data → presentation |
| Detective | Natural language | `debug-orchestrator` | — | `debug-worker`, `debug-log-worker` | Root cause investigation via scientific debugging |
| Auditor | Natural language | `arch-review-orchestrator` | — | `arch-review-worker` | Convention compliance review before code reaches consumers |
| Tracker | Natural language | — | — | `issue-worker` | GH issue + branch + backlog row creation |
| Installer | Natural language | — | — | `setup-worker` | Project onboarding — symlinks, platform detection, orientation |

---

### Slide 14 — In Action: Leave Request (updated walkthrough)

**Headline:** From intent to 34 files — with a plan in between.

**Full flow (condensed tree, Flutter):**

```
/plan-feature "leave request"
 │
 ▼
feature-orchestrator
 │
 ▼
feature-planner
  ├── domain-planner   ← finds existing entities, naming conventions
  ├── data-planner     ← finds existing mappers, datasource pattern
  └── pres-planner     ← finds StateHolder structure, event cases
 │
 │  plan.md written → engineer reviews → approves
 │
 ▼
feature-worker
  ├── domain-create-entity      → LeaveRequest.dart
  ├── domain-create-usecase     → GetLeaveRequestListUseCase.dart
  ├── data-create-mapper        → LeaveRequestMapper.dart
  ├── data-create-datasource    → LeaveRequestRemoteDataSource.dart
  ├── pres-create-stateholder   → LeaveRequestBloc.dart
  └── pres-create-screen        → LeaveRequestScreen.dart
```

**Key numbers alongside:** 34 files total · each artifact Glob+Grep validated · state.json checkpointed after each · resumable if interrupted

**Caption:** The planner explores once, in parallel. The worker executes with zero guesswork. The engineer reviews the plan — not 34 individual files.

---

## Design Direction

- **Background:** Dark (`#0F1117`) — engineering credibility
- **Accent:** Mekari primary green (confirm hex)
- **Body font:** Inter or system sans-serif
- **Code/tree blocks:** Monospace, slightly lighter background panel
- **Navigation:** Arrow keys (left/right) — full-screen slide-per-section layout
- **File:** Single `index.html`, zero dependencies, works offline

---

## Technical Approach

Single HTML file with:
- Full-viewport `<section>` slides
- CSS scroll-snap or JS `currentSlide` index for keyboard nav
- Inline `<style>` + `<script>` — no external files
- Arrow key listeners: `ArrowRight` / `ArrowLeft` (also `ArrowDown` / `ArrowUp`)

---

## Content Decisions

- [x] Platform scope: web included — Leave Request walkthrough mentions TypeScript alongside Swift/Dart
- [x] Planner taxonomy: added as a first-class layer in the anatomy diagram and its own "Plan First" slide
- [ ] Token cost numbers: show both percentage (85%) AND absolute (737k → 103k)? Or percentage only?
- [ ] Slide 16 "Where We're Going" — Android listed as next. Should web also appear here since it's already active, or is web's inclusion in the main slides sufficient?
- [ ] Slide count: 17 — cut option is to merge Slides 11 + 12 into one "How It Works" slide (anatomy left, Planner decision right). Down to 16.
