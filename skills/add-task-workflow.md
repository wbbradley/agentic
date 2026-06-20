## Add-Task Workflow

You are adding a new task to the project's `PLAN.md`. The user has described what they want via
`$ARGUMENTS`. Your job is to turn that into a well-defined, actionable task that could be handed
off to a strong junior SWE.

### Naming principle (no stage/phase ordinals)

Name tasks and the things they create by **what they are**, not where they fall in the
sequence. Sequence-position labels — `Stage N`, `Phase N`/`Phase X`, `Step N`, `(PLAN.md)`
back-pointers, "follow-up is Stage 4x" forward-pointers — are banned from task titles and from
any durable artifact the task will create: filenames, identifiers, run-id/dir prefixes, env
vars, doc titles/headings, commit scopes.

- Decompose by capability; name each sub-task for the feature it builds ("looked-at-block
  attribute head"), never its ordinal ("Stage 2").
- Express ordering structurally — list order and plain prose ("first… then…", "requires X
  first") — which stays true when items reorder; a number doesn't.
- Allowed: genuine domain terms that merely contain the words (a protocol "configuration
  phase", a numbered milestone that is the doc's actual subject). Judgment, not regex.

Ordinals are indices into a process snapshot: once the work lands the index points at nothing
the reader shares, and worse, it freezes into filenames and keys that can't be cleaned without
breaking references.

### Step 1: Delegate to a research sub-agent

Launch a sub-agent to do the exploration work. Before launching, read `PLAN.md` yourself so you can
pass its contents (or a sufficient summary) as context to the sub-agent along with the user's
`$ARGUMENTS`.

The sub-agent should:

1. Understand the request. Parse `$ARGUMENTS` for intent. If the request is ambiguous or
   underspecified, ask the user clarifying questions before proceeding — don't guess.

2. Explore the codebase and gather requirements. Read relevant source files, tests, configs,
   docs, or anything else needed to understand what this task should touch. Use web search if the
   request involves external APIs, libraries, or concepts that need research.

3. Check for overlap with existing tasks. Review the full `PLAN.md` for duplication or
   partial overlap. If the new work is already covered by an existing task, tell the user and
   suggest whether to merge, extend, or skip. If the new task would benefit from changes to
   other existing tasks, note those suggestions — but do **not** modify other tasks without
   explicit user approval.

4. Think big picture, then zoom in. Consider how this feature fits into the broader project:
   - Does it interact with or depend on other planned or completed work?
   - Are there inconsistencies, redundancies, or conflicts with the existing feature set?
   - What use-case scenarios does it enable? Are there edge cases worth calling out?
   - What risks or open questions should be flagged?

5. Work back and forth with the user to ensure you are aligned with their goals and opinions.

6. Draft the new task. Write a task entry that is concrete and actionable. It should make
   clear what files, modules, or systems are involved, what the expected behavior is, and what
   would need to be true for the task to be considered complete. Write it so that a competent
   developer and/or tech doc writer with access to the codebase — but no other context — could pick
   it up and execute.

The sub-agent should return the drafted task text and any suggestions about existing tasks.

### Step 2: Resolve open questions

If the sub-agent flagged any open questions or ambiguities, present them to the user as a numbered
list before writing anything to `PLAN.md`. Ask the user to answer or dismiss each one. Wait for
their response.

Once the user responds, incorporate their answers into the drafted task — refine scope, adjust
acceptance criteria, or add clarifying notes as appropriate. Drop any questions the user dismissed.

If there are no open questions, skip straight to Step 3.

### Step 3: Add the task to PLAN.md

Read the current `PLAN.md`. Insert the finalized task at the **$QUEUE_POSITION** of the "Next Up"
section. If `PLAN.md` doesn't exist yet, create it with a top-level "Next Up" section, and place
the new task under "Next Up".

If the sub-agent suggested modifications to other existing tasks, present those suggestions to the
user and only apply them with approval.

### Step 4: Retrospective

In the retrospective, only surface details if there are outstanding questions or concerns.
Otherwise, just say "The plan is ready."

Then stop and yield to the user.
