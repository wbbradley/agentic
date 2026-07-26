---
name: handoff
description: Stop the current work immediately and prepend a concise continuation handoff to PLAN.md for an agent with a fresh context window. Use when the user asks to hand off, reset context, preserve in-progress work, or invoke $handoff.
---

Stop work immediately. Do not investigate, edit, test, clean up, or commit anything else.

Prepend a compact handoff to `PLAN.md` (create it if absent) without altering existing content.
Include only what a fresh agent needs to resume: the objective, current state, relevant changes and
files, key decisions or constraints, verification already run, and the exact next action or blocker.
Prefer terse bullets; omit narrative history and anything recoverable by reading the files.

Report that the handoff was saved, then stop.
