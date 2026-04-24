---
name: plan-feature
description: Plan then build a feature — invokes feature-planner for reviewable planning, then hands off to feature-orchestrator for execution.
allowed-tools: Bash, Read, Agent
---

1. Spawn `feature-planner` using the Agent tool. Pass no arguments — it gathers intent interactively.

2. After it completes, find the context file it just wrote:
   ```bash
   ls -t "$(git rev-parse --show-toplevel)/.claude/agentic-state/runs"/*/context.md 2>/dev/null | head -1
   ```

3. Read that `context.md` and the `state.json` in the same directory.

4. Spawn `feature-orchestrator` using the Agent tool with the following prompt, substituting actual file contents:

   > Approved plan ready. Pre-loaded context below — do not re-read context.md or state.json.
   >
   > **context.md**
   > <content>
   >
   > **state.json**
   > <content>
   >
   > Proceed directly to the first pending phase.
