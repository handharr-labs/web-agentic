# Changelog — Core Design Principles

**v39 — 2026-04-19 · software-dev-agentic v3.21.0**
- P7: `lib/core/reference/clean-arch/` now holds two kinds of files — universal theory (existing: `layer-contracts.md`, `domain-purity.md`, `di-containers.md`, `contract-schema.md`) and per-layer canonical templates (new: `domain.md`; `data.md`, `presentation.md` in progress). Both kinds preserved as `clean-arch/` subdir downstream (`.claude/reference/clean-arch/<name>.md`)
- P7: Platform `reference/contract/` files now carry syntax only — conceptual definitions stripped to the corresponding `clean-arch/<layer>.md` template. Files retain canonical `##` headings; pointer header added at top of each file
- P7: "Reference subdir rule" added — all reference source subdirs preserved downstream (not flattened); agents reference `reference/clean-arch/<name>.md` and `reference/contract/<name>.md` using downstream paths, never source paths
- Setup scripts: `link_reference` / `copy_reference` made generic — all subdirs preserved (previously only `contract/` was); core call updated to `lib/core/reference` so `clean-arch/` is picked up as a preserved subdir

**v38 — 2026-04-19 · software-dev-agentic v3.21.0**
- P3/P7: Contract expanded from 6 to 8 files — `error-handling.md` and `utilities.md` added to all three platforms; `lib/core/reference/clean-arch/contract-schema.md` added as the canonical keyword registry
- P7: Heading structure normalized across all 24 contract files: `#` platform+topic title, `##` canonical keyword sections, `###` subsections — agents now grep with `^## Keyword` for deterministic lookup without depth guessing
- All skills and agents updated to replace `§N.N` section references with canonical `## Heading` names; legacy numbered headings removed from all reference files

**v37 — 2026-04-19 · software-dev-agentic v3.21.0**
- P3: Platform-contract skills moved to `lib/platforms/<platform>/skills/contract/` subfolder — makes the mandatory cross-platform contract explicit in folder structure; platform-only skills remain flat; both land flat in `.claude/skills/<name>/` downstream (transparent at runtime)
- P3: Reference doc organization updated — `lib/platforms/<platform>/reference/contract/` introduced for six cross-platform standard files (domain, data, presentation, navigation, di, testing); preserved as `contract/` subdir downstream (`.claude/reference/contract/<name>.md`); platform-specific refs remain flat
- P7: Reference doc organization note expanded with three-tier breakdown: `lib/core/reference/clean-arch/`, `lib/platforms/<platform>/reference/contract/`, and flat platform-specific refs
- Taxonomy Skills by Scope: Platform-contract skill location updated to `lib/platforms/<platform>/skills/contract/`; downstream behavior noted (lands flat); Platform-only clarified as flat
- Decision Rules: Architecture reference knowledge split into two rows — contract/ for cross-platform, flat for platform-specific; platform-contract skill row updated with `contract/` path

**v36 — 2026-04-18 · software-dev-agentic v3.20.0**
- P8: Orchestrator step 3 updated — `platform` parameter now gathered in Phase 0 and passed to every worker spawn; step 4 updated — `isolation: worktree` conditional, not universal; step 6 added — orchestrator validates worker `## Output` (section exists + paths on disk) before proceeding; P8 table updated: model row changed from haiku/sonnet split to sonnet default; isolation row clarified with exception note
- P10: Fail-Fast expanded into four structured gates — Input (worker entry), Preconditions (before writing), Output (before returning), Orchestrator (after each spawn)
- P15: Convention table updated — Model assignment row updated (sonnet default); Orchestrators row: `isolation: worktree` exception noted, output validation added (Critical); Workers: four new required sections added (`## Input`, `## Scope Boundary`, `## Task Assessment`, `## Skill Execution`) and `## Output` Glob+Grep verification promoted to Critical

**v35 — 2026-04-17 · software-dev-agentic v3.19.0**
- `pres-orchestrator` promoted to sub-orchestrator of `feature-orchestrator` — `feature-orchestrator` now delegates Phase 3 entirely to `pres-orchestrator` instead of spawning `presentation-worker`/`ui-worker` directly
- `feature-orchestrator`: `agents:` field updated (removed `presentation-worker`, `ui-worker`; added `pres-orchestrator`); Phase 3 rewritten; Phase 4 (UI) removed; Phase 5 renumbered to Phase 4
- `pres-orchestrator`: dual-mode added — standalone (full gather + state file) vs sub-orchestrator (Grep provided paths, skip state file); P8 Combined Matrix updated to show `feature-orchestrator → pres-orchestrator` hierarchy
- Taxonomy: orchestrator-of-orchestrators note updated with concrete example

**v33 — 2026-04-17 · software-dev-agentic v3.15.0**
- Taxonomy gaps closed: Type U (Utility) skill added — user-invocable, model-run, self-contained, no agent spawning; `doctor`, `clear-runs`, `release` classified as Type U
- Repo skill scope added — root `skills/` internal tooling, never ships downstream; `arch-check-conventions`, `arch-generate-report`, `docs-identify-changes` classified here
- Skill Type × Scope intersection matrix added — decision gate for valid combinations when adding new skills
- Toolkit skill scope clarified: ships downstream, intended for use in downstream projects (not this repo's internal operations)
- `release` skill description fixed: was "software-dev-agentic starter kit" specific, now generic downstream-project release tool

**v32 — 2026-04-17 · software-dev-agentic v3.15.0**
- Taxonomy section added — replaces the minimal "Agent & Skill Hierarchy" table with full formal definitions
- Agents by Role: Orchestrator / Worker with subordinate clarification; orchestrator-of-orchestrators constraint added
- Agents by Scope: Persona agent / Platform agent / Project agent formally named
- Persona: formal definition — coherent workflow requirement, `.pkg` file requirement, minimum one worker/orchestrator
- Skills by Invocation Type: Type T (Trigger) formalized — `user-invocable: true` + `Agent` tool, distinct from Type B; `agentic-perf-review` cited as canonical example
- Skills by Scope: Toolkit skill / Platform-contract skill / Platform-only skill / Project skill named; "core-dependency skill" cross-referenced as alias for platform-contract skill

**v31 — 2026-04-17 · software-dev-agentic v3.14.0**
- `prompt-debug-worker` added to `lib/core/agents/detective/` — diagnoses why an agent underperformed by analyzing its system prompt against the trajectory from a perf-worker report; surfaces ambiguous instructions, missing context, and contradicting rules
- `perf-worker` updated: new Step 5 flags low D1–D7 scores and points to `prompt-debug-worker` with the exact agent file path to debug
- P15 `arch-check-conventions`: Prompt Clarity Check category added (Warning severity) — flags ambiguous scope, missing stop conditions, contradicting rules, undefined failure paths
- Agent Count Summary updated: detective workers 1→2 (total core workers 13→14)
- P8 Combined Matrix updated: `prompt-debug-worker` added to Core workers
- Execution Example Case 14 added: agent prompt debugging flow

**v30 — 2026-04-16 · software-dev-agentic v3.4.6**
- P3: "By Caller" skill dependency classification added — core-dependency skills (must exist on all platforms) vs platform-specific skills (platform-agent-only); explicit table mapping skill → caller → platform coverage required
- P8: Agent Scope (Core vs Platform-specific) added with rule "Do not add a platform agent unless a core agent + skills cannot handle it"; Combined Matrix (Role × Scope) added
- Decision Rules table added (before Execution Examples)
- Execution Examples: Cases 12 (Flutter entity creation) and 13 (iOS PR review) added

**v29 — 2026-04-14 · software-dev-agentic v3.4.6**
- P15 arch-check-conventions table — Orchestrators row updated: `isolation: worktree` in Constraints → `isolation: worktree` inline with each Spawn directive (Critical); new Critical rule added: After delegation flag set, no direct Edit or Write — all file changes through workers

**v28 — 2026-04-13 · software-dev-agentic v3.0.1**
- P7: "Search Rules" bullet replaced with Search Protocol decision gate table
- P8: Added steps 7–8 — orchestrator writes state file; `presentation-worker` writes StateHolder contract to handoff file
- P15 arch-check-conventions: Workers row updated; Orchestrators row updated

**v27 — 2026-04-12 · software-dev-agentic v3.0.0**
- `lib/` boundary introduced; all path references updated

**v26 — 2026-04-12 · software-dev-agentic v2.1.0**
- `installer/` persona group added; `setup-ios-project` skill added

**v25 — 2026-04-12 · software-dev-agentic v2.0.0**
- `docs-sync-worker` + `docs-identify-changes` added to internal tooling

**v24 — 2026-04-12 · software-dev-agentic v2.0.0**
- Principle 15 added: Convention Enforcement — self-auditing architecture

**v23 — 2026-04-12 · software-dev-agentic v1.2.x**
- `core/agents/` grouped into persona subdirectories

**v22 and earlier** — See git history in the software-dev-agentic repository.
