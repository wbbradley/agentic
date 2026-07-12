---
name: list-tasks
description: List remaining phases/tasks from PLAN.md as a concise numbered list.
---

## List Tasks Workflow

You are summarizing the remaining work in the project's `PLAN.md`.

### Step 1: Read the plan

Read `PLAN.md` at the project root. Identify all incomplete phases under "Next Up" and "Future
Work". For each phase, produce a single line with a short title and a one-sentence description of
the change. Preserve their order. If `PLAN.md` does not exist or has no remaining phases, say so.

### Step 2: Present the results

Print the result directly to the user. Do not add commentary, suggestions, or follow-up questions;
show only the list with a short title such as "Remaining tasks:".
