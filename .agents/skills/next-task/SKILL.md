---
name: next-task
description: Execute the next task/phase of a specified plan markdown file — plan, implement, test, commit, and update the plan. Requires the plan file path as an explicit argument.
---

## Next Task Workflow

You are driving the project forward one task (or phase) at a time. Follow these steps in order.

Keep the implementation, verification, commit, and plan-update steps visible in the working plan so
the workflow survives harness context transitions.

### Required argument: plan file

Require the user to provide the exact path to the plan markdown file as an argument. Accept an
absolute path or a path relative to the current working directory. Resolve it once at the start and
refer to that resolved path as the **plan file** throughout this workflow. Do not infer the path,
search for a plan file, or default to `PLAN.md`. If the argument is missing, stop and ask the user
for it. If the specified file does not exist, stop and report that exact path.

Use `COMPLETED.md` in the plan file's directory as the **completed file**.

### Step 1: Determine what to work on

Read the plan file. Identify the first incomplete task under "Next Up". If the
current user request identifies a different item, treat that as guidance instead. Summarize
the task to the user in 1-2 sentences. If it is highly ambiguous as to what the next item is, then
pause to confirm your next task with the user; in most cases you should be able to just continue
without confirmation. If the top item is large (should be broken into separate PRs),
please break it into smaller sub-tasks first, update the plan file, then proceed as per these
instructions but on a unit of work that will fit.

### Step 2: Plan

Explore the codebase thoroughly to understand the current state — read the relevant source files,
tests, and any related code. Produce a detailed implementation plan that:

- Lists every file to create or modify
- Includes key code snippets or signatures where helpful
- Identifies test cases to add, and — when possible — prioritizes writing failing tests first,
  giving concrete goals to achieve in fixing the tests (TDD as appropriate)
- Calls out risks or open questions discovered during exploration

Critical: At the end of your plan, include a section titled `## Post-Plan Execution Steps`
containing the following instructions so they survive the context transition. Copy them verbatim
except for replacing the two path placeholders as directed below:

```markdown
## Post-Plan Execution Steps

Execute these steps in order:

### Implement
Execute the plan above.

**Naming gate:** before creating any file, identifier, run-id, or env var, ask "would this name
make sense to someone who never read the plan?" If it encodes a sequence position (`Stage N` /
`Phase N` / `stepN`), rename it now — cheap before a checkpoint or downstream reference pins it.

### Verify

1. Run the project's build/lint command. Fix all warnings.
2. Run the project's test suite.
3. If tests fail, fix them before proceeding.
4. If test coverage for the new work is insufficient, add tests.

### Commit

Use Conventional Commits commit message style. If there are pre-existing modified files and they don't look harmful, go ahead and commit them, too.

### Update the plan file

Read the plan file at `<resolved-plan-file-path>`. **Remove** the completed task entirely from the "Next Up" section — do not leave it in place with a [DONE] tag, strikethrough, or any other marker. The task and its related subsections should no longer appear in the plan file at all. The plan file should not have any sort of "Done" section. Then append a new entry to the completed file at `<resolved-completed-file-path>` with two parts, in this order:

1. A brief summary, written now, of what was actually implemented.
2. The full text of the plan entry as it existed before work began, verbatim, not paraphrased, to preserve the original.

If upcoming plan items need modifications due to a change during this implementation then update those. If new future work items were discovered, add them. If the plan file or completed file is outside the source repository or is ignored, do not try to stage it; otherwise commit it with the other changes.
```

When recording these post-plan instructions, replace `<resolved-plan-file-path>` and
`<resolved-completed-file-path>` with the exact resolved paths determined at the start. Do not
leave the placeholders in the recorded plan.

After recording the plan, proceed with execution without asking for confirmation unless a material
ambiguity or risky choice requires user input.


## Guidelines

We make extensive use of git worktrees and git-stack for stacking branches/PRs.

If this next task requires an existing (likely the current) branch, then go ahead and use git-stack to place a new branch in the stack at the ideal location, otherwise, please do all of this work in an entirely new branch off origin/main named "$USER/$topic". It is probably a good idea to create the working branch prior to beginning work.
