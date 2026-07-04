---
name: list-tasks
description: List remaining phases/tasks from PLAN.md as a concise numbered list.
disable-model-invocation: true
---

## List Tasks Workflow

You are summarizing the remaining work in the project's `PLAN.md`.

### Step 1: Delegate to a sub-agent

Launch a sub-agent (subagent_type: "Haiku") with the following instructions:

> Read `PLAN.md` at the project root. Identify all incomplete phases under "Next Up" and "Future
> Work". For each phase, produce a single line with a short slogan-style title and a one-sentence
> description of the change. Return the results as a numbered list, in the order they appear in
> PLAN.md. If `PLAN.md` does not exist or has no remaining phases, say so.

### Step 2: Present the results

Print the sub-agent's output directly to the user. Do not add commentary, suggestions, or
follow-up questions — just show the list with a short title above it (e.g., "Remaining tasks:").
