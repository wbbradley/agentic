---
name: next-task
description: Execute the next task/phase of the PLAN.md — plan, implement, test, commit, and update PLAN.md.
---

## Next Task Workflow

You are driving the project forward one task (or phase) at a time. Follow these steps in order.

Keep the implementation, verification, commit, and plan-update steps visible in the working plan so
the workflow survives harness context transitions.

### Step 1: Determine what to work on

Read `PLAN.md` at the project root. Identify the first incomplete task under "Next Up". If the
current user request identifies a different item, treat that as guidance instead. Summarize
the task to the user in 1-2 sentences. If it is highly ambiguous as to what the next item is, then
pause to confirm your next task with the user; in most cases you should be able to just continue
without confirmation. If the top item is large (likely to consume more than 120k tokens for an LLM),
please break it into smaller sub-tasks first, update the PLAN.md, then proceed as per these
instructions but on a unit of work that will fit.

### Step 2: Plan

Use the harness's plan mode or plan-tracking tool when available. Otherwise, maintain the plan in
the conversation. Do not create a separate plan file unless the user asks for one.

Explore the codebase thoroughly to understand the current state — read the relevant source files,
tests, and any related code. Produce a detailed, concrete implementation plan that:

- Lists every file to create or modify
- Includes key code snippets or signatures where helpful
- Identifies test cases to add, and — when possible — prioritizes writing failing tests first,
  giving concrete goals to achieve in fixing the tests (TDD as appropriate)
- Calls out risks or open questions discovered during exploration

Critical: At the end of your plan, include a section titled `## Post-Plan Execution Steps`
containing the following verbatim instructions so they survive the context transition:

```markdown
## Post-Plan Execution Steps

Execute these steps in order:

### Implement
Execute the plan above. Work methodically and use task lists to track progress. Prefer editing
existing files over creating new ones. Follow all project conventions from `AGENTS.md` and any
harness-specific compatibility instructions.

**Naming gate:** before creating any file, identifier, run-id, or env var, ask "would this name
make sense to someone who never read the plan?" If it encodes a sequence position (`Stage N` /
`Phase N` / `stepN`), rename it now — cheap before a checkpoint or downstream reference pins it.

### Verify

1. Run the project's build/lint command (Rust: `cargo clippy`, Haskell: `cabal build`, etc.).
2. Run the project's test suite (Rust: `cargo nextest run`, Haskell: `cabal test`, etc.).
3. If tests fail, fix them before proceeding.
4. If test coverage for the new work is insufficient, add tests.

### Commit

Follow the project's commit message style (see `git log --oneline`). If there are pre-existing
modified files and they don't look harmful, go ahead and commit them, too.

### Update PLAN.md

Read `PLAN.md`. **Remove** the completed task entirely from the "Next Up" section — do not leave
it in place with a [DONE] tag, strikethrough, or any other marker. The task and its related
subsections should no longer appear in PLAN.md at all. PLAN.md should not have any sort of "Done"
section. Then append a new entry to `COMPLETED.md` with two parts, in this order:

1. A brief summary, written now, of what was actually implemented.
2. The **full text of the PLAN.md entry as it existed before work began**, verbatim — headings,
   sub-bullets, notes, and acceptance criteria included, not paraphrased — so the original task
   spec is preserved and not lost to git history archaeology.

If upcoming PLAN.md items need modifications due to a change during this plan's implementation
then update those. If new future work items were discovered, add them. Leftover compiler warnings
count as future work items unless they would naturally be handled by existing future work. If
PLAN.md or COMPLETED.md are ignored, don't force add them, otherwise commit them with other changes.
```

After recording the plan, proceed with execution without asking for confirmation unless a material
ambiguity or risky choice requires user input.

### Steps 3-7 (post-plan)

Carry these steps forward in the active plan (see `Post-Plan Execution Steps` above), then follow
them through completion.
