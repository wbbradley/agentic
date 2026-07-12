---
name: find-bugs
description: Audit the codebase for bugs, inconsistencies, and other issues, then add findings to PLAN.md.
---

## Find Bugs Workflow

You are auditing the current project's codebase for bugs and other issues. The current user request
may provide focus areas or constraints. Your job is to find real issues and add them
to the project's `PLAN.md` as future work items.

### Step 1: Read PLAN.md

Read `PLAN.md` at the project root (if it exists) so you can pass its contents to the sub-agents as
context. This helps them avoid reporting issues that are already tracked.

### Step 2: Launch the discovery sub-agent

Launch a general-purpose sub-agent with the following instructions. If the harness does not support
delegation, perform this pass yourself before continuing.

> Read through the codebase methodically. Your goal is to identify real issues — bugs,
> inconsistencies, correctness problems, security concerns, performance pitfalls, data integrity
> risks, operational hazards, or sources of confusion that could cause problems downstream.
>
> **Scope:** If the user provided arguments, treat them as guidance on where to focus or what kinds
> of issues to prioritize. Include the relevant constraints from the current user request.
> If no arguments were provided, audit the full codebase with no particular bias.
>
> **Approach:**
> 1. Read source files, tests, configs, and documentation broadly before forming conclusions.
> 2. Do not assume bugs exist. Do not assume the code is bug-free. Simply read and evaluate.
> 3. For each issue found, provide:
>    - A short title
>    - The file(s) and line(s) involved
>    - A clear explanation of what is wrong and why it matters
>    - Severity: low, medium, or high
>    - Category: one of correctness, security, performance, data-integrity, consistency,
>      operational, or clarity
> 4. Do not report stylistic preferences, missing documentation, or hypothetical issues that
>    require unlikely preconditions. Focus on things that could actually cause harm or confusion.
>
> **Context — already-tracked work:**
> (Paste the contents of PLAN.md here, or "No PLAN.md exists." if it doesn't.)
>
> Return your findings as a numbered list. If you found nothing, say so.

### Step 3: Launch the review sub-agent

Take the discovery output and pass it to a second general-purpose sub-agent for review. If the
harness does not support delegation, perform a separate verification pass yourself. The review's
job is to filter out false positives.

> You are reviewing a list of potential bugs and issues found by another agent. Your job is to
> verify each finding and filter out anything that is not a genuine concern.
>
> For each reported issue:
> 1. Read the relevant source code yourself. Do not trust the first agent's characterization
>    blindly.
> 2. Determine whether the issue is real. Ask yourself: could this actually cause incorrect
>    behavior, confusion, security exposure, data corruption, performance degradation, or
>    operational problems? Or is it benign in practice?
> 3. Mark each issue as **keep** or **drop**, with a one-sentence justification.
>
> **Keep** issues that involve: correctness bugs, security vulnerabilities, data integrity risks,
> performance problems, operational hazards, meaningful inconsistencies, or genuine sources of
> confusion.
>
> **Drop** issues that are: stylistic nitpicks, hypothetical problems requiring implausible
> preconditions, already handled elsewhere in the code, or genuinely never going to be problematic.
>
> Return the filtered list — only the kept issues — using the same format as the input (numbered
> list with title, files, explanation, severity, and category). If nothing survives the filter,
> say so.

### Step 4: Update PLAN.md

Read `PLAN.md` again (it may have changed). For each surviving issue from the review sub-agent,
add it as a bullet under the "Next up" section. Use this format for each entry:

```
- **[category/severity] Title** — Explanation. (file:line)
```

If `PLAN.md` doesn't exist, create it with a top-level "Next Up" section, then add the items under
"Next Up".

If no issues survived the review, tell the user that no actionable issues were found and do not
modify `PLAN.md`.

### Step 5: Report

Tell the user:
- How many issues were found initially vs. how many survived review.
- A brief summary of what was found (or that nothing was found).
- Any patterns or themes worth noting.

Then stop and yield to the user.
