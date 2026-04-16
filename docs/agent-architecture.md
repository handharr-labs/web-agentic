# Agent Architecture

Understanding the three-layer model is critical before adding any agent or skill.

```
Core Orchestrators  (lib/core/agents/builder/)
      │  coordinate
      ▼
Core Workers        (lib/core/agents/builder/)
      │  call
      ▼
Platform Skills     (lib/platforms/<platform>/skills/)
```

---

## Agents

Agents are differentiated by two axes: **role** and **scope**.

### By Role

**Orchestrators** — coordinate agents in the right sequence. Never write files directly.
Use `agents:` frontmatter to declare sub-agents they spawn.

**Workers** — domain specialists. Execute skills and write files.
End with an Extension Point so downstream projects can inject extra instructions.

### By Scope

**Core** (`lib/core/agents/`) — platform-agnostic. Work on any platform.
Add here when the behaviour is identical across all platforms.

**Platform-specific** (`lib/platforms/<platform>/agents/`) — exist only when the workflow
diverges enough from core to need its own agent.
Examples: iOS `test-orchestrator` (knows `xcodebuild`), iOS `pr-review-worker` (knows Swift/UIKit conventions).
**Do not add a platform agent unless core agent + skills cannot handle it.**

### Combined Matrix

| | Orchestrator | Worker |
|---|---|---|
| **Core** | `feature-orchestrator`, `pres-orchestrator` | `domain-worker`, `data-worker`, `presentation-worker`, `ui-worker`, `test-worker` |
| **Platform** | iOS `test-orchestrator` | iOS `pr-review-worker` |

---

## Skills

Skills are platform-specific execution instructions — code templates + step-by-step generation steps.
Each skill lives in `lib/platforms/<platform>/skills/<skill-name>/SKILL.md`.

### By Caller

**Core-dependency skills** — called by core workers or orchestrators.
Must be implemented by **every platform** that wants core agent support.
Same name across platforms, different syntax per platform.

| Skill name | Called by | Must exist in |
|---|---|---|
| `domain-create-entity` | `domain-worker` (core) | all platforms |
| `domain-create-repository` | `domain-worker` (core) | all platforms |
| `domain-create-usecase` | `domain-worker` (core) | all platforms |
| `data-create-mapper` | `data-worker` (core) | all platforms |
| `data-create-datasource` | `data-worker` (core) | all platforms |
| `data-create-repository-impl` | `data-worker` (core) | all platforms |
| `pres-create-stateholder` | `presentation-worker` (core) | all platforms |
| `pres-create-screen` | `ui-worker` (core) | all platforms |
| `test-create-domain` | `test-worker` (core) | all platforms |
| `test-create-data` | `test-worker` (core) | all platforms |
| `test-create-presentation` | `test-worker` (core) | all platforms |

**Platform-specific skills** — called by platform agents only.
Implemented only by the platform that owns the calling agent.
Examples: iOS `review-pr` (called by iOS `pr-review-worker`), iOS `arch-check-ios` (called by iOS workers).

---

## Decision Rules

| Situation | Where it goes |
|-----------|--------------|
| New CLEAN-layer behaviour, same on all platforms | Core worker |
| New orchestration flow, same on all platforms | Core orchestrator |
| New code generation pattern for one platform | Platform skill (core-dependency) |
| Workflow too platform-specific for any core agent | Platform agent + platform skill |
| Architecture reference knowledge | `lib/platforms/<platform>/reference/` |

---

## Example: Flutter domain entity creation

```
feature-orchestrator   (core orchestrator)
  └─ domain-worker     (core worker)       ← knows the rules
        └─ domain-create-entity            ← flutter skill, knows the syntax
             lib/platforms/flutter/skills/domain-create-entity/SKILL.md
```

The worker knows the rules (no framework imports, single responsibility).
The skill knows the syntax (Dart, `@freezed`, file naming).

## Example: iOS PR review

```
pr-review-worker       (iOS platform worker)   ← iOS-specific workflow
  └─ review-pr         (iOS platform skill)    ← Swift/UIKit conventions
       lib/platforms/ios/skills/review-pr/SKILL.md
```

`review-pr` is not a core-dependency skill — only the iOS platform worker calls it,
so it only needs to exist for iOS.
