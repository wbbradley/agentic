---
name: review-pr
description: Always run this skill when asked to review a Github PR.
---

Never perform a shallow review of a pull request. Always perform a deep thorough review.

The current user request should contain a PR number, PR URL, or `owner/repo#number` reference.
Parse it to determine the owner, repository, and PR number. If only a number is given, infer the
owner and repository from the current git remote.

## Setup

Clone the repo into /tmp/review-pr (or fetch the latest changes if you've already got it) and check out the PR:

```
gh repo clone owner/repo /tmp/review-pr/owner/repo -- --filter=blob:none
gh pr checkout <number>
```

Follow the standard post-clone checklist, including `AGENTS.md`, any harness-specific compatibility
instructions, and `README.md`.

## Approach

Follow this review checklist:

### Step 1: Understand the changes

Read the PR description and evaluate the changed files:

```
gh pr view <number>
git diff main...HEAD --stat
```

Get a sense of what the changes are trying to do.

### Step 2: Plan review passes

Based on the complexity of the PR, determine a number of review passes to perform and write down the
specific focus angle for each pass before starting.

This should be a number between 1 and 5. A small config change needs one pass. A new library or
major feature needs many focused passes. For PRs over ~500 lines changed, introducing significant
new functionality, or containing complex logic, always do at least 3 passes.

When reviewing a complex PR and the harness supports delegation, launch sub-agents to trace
execution paths, adversarial scenarios, and subtle correctness bugs. Otherwise, perform those as
separate focused passes yourself.

### Step 3: Execute review passes

For each focus angle identified in step 2, perform a code review pass:

- Do not limit yourself to just the code in the changed files. Review the entire codebase, and trace
  the code paths through the changes.
- Perform a comprehensive code review of the changes, and collect all issues.
- The best findings come from asking "what breaks if..." not "does this file look reasonable."
- Continue until you are confident that you have found all of the issues in the proposed changes.

Collect ALL issues — do not self-limit. Over-reporting is better than silently skipping.

### What to ignore

Formatting, style, naming opinions, missing docs, import ordering, etc.

## Reporting the review

Before reporting the review back to the calling agent or user, ask yourself if you have reviewed all
of the relevant domains, and have performed all review passes.

CRITICAL: Make sure you have performed a sufficiently deep review of the changes. You have a
tendency to not review the changes deeply enough.

### Consolidate findings

1. Consolidate all feedback, and assign severity: **critical** / **major** / **minor**.
2. Before posting, compare your notes to the existing review comments and discard any comments that
   are already covered.

### Report the findings

- Write the findings in well-formatted markdown
- Verdict: any critical -> REQUEST_CHANGES, any major -> COMMENT, only minor/none -> APPROVE.
- No positive/praise comments. Be specific — state what's wrong and what breaks.
- Do not touch the live PR without talking to the user.
