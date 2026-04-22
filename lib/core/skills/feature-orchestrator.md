---
name: feature-orchestrator
description: Trigger the feature-orchestrator agent to build or update a feature across Clean Architecture layers. Accepts an optional feature description — the agent handles all remaining intake.
user-invocable: true
tools: Agent
---

## Arguments

`$ARGUMENTS` — optional feature description provided at invocation time.

## Steps

1. Spawn `feature-orchestrator` with the following spawn prompt:

   > Feature description: <$ARGUMENTS>

   If `$ARGUMENTS` is empty, pass an empty feature description — the agent will collect intake interactively via its own Phase 0.
