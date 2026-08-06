---
name: restack
description: "Restack the current branch, a named branch, or a GitHub PR onto the latest origin/main and resolve every conflict. Use only when the user explicitly invokes $restack, optionally with a branch name or PR number."
---

# Restack

Restack the requested branch and its ancestors through `git-stack`, resolving
conflicts until the entire operation succeeds and pushes.

## Establish the target

1. Run `git stack llms` and read its full output before changing anything.
2. Identify the repository containing the current working directory. Keep every
   lookup and operation in this repository.
3. Interpret the text following `$restack` as follows:
   - No argument: use the current branch and current worktree. Do not switch
     worktrees or infer a target from conversation context.
   - `#<number>`: resolve that PR with `gh pr view` in the current repository and
     use its head branch.
   - Anything else: treat the argument as the exact branch name.
4. For an explicit target, verify that the PR or branch belongs to the current
   repository. Resolve branches against local refs and `origin` refs; fetching
   `origin` first is allowed. If the named PR does not exist in the current
   repository, or its head branch cannot be found locally or on `origin`, stop
   and report that exact target as not found. Do not search another repository,
   guess a similarly named branch, create a new branch, or restack a fallback.

## Select a worktree

For an explicit target, inspect `git worktree list --porcelain` and match the
exact branch ref.

- If a worktree already has the target branch checked out, perform all further
  commands from that worktree.
- If no worktree has it checked out, create a linked worktree for the existing
  branch at a safe, collision-free path, following any repository or harness
  worktree convention. If only `origin/<branch>` exists, create a local branch
  that tracks that exact remote branch while adding the worktree.
- After changing directories, verify that the worktree has the same Git common
  directory as the starting repository and that `HEAD` is the exact target
  branch. Stop on either mismatch.

Do not move or remove an existing worktree. Do not delete a worktree created by
this workflow unless the user asks.

## Restack completely

1. Require a clean selected worktree. If tracked or untracked user changes are
   present, stop and report them; do not stash, discard, or commit them.
2. Run exactly:

   ```sh
   git-stack restack -afp
   ```

   The fetch must bring the stack onto the latest `origin/main`, the ancestor
   mode must process the target's parents from the trunk upward, and the push
   must update every successfully restacked branch.
3. If `git-stack` says the topology must be reconciled because a parent PR was
   merged or closed, run `git-stack sync`, re-check the target still exists,
   then retry `git-stack restack -afp`.
4. When a conflict pauses the operation, inspect the conflicting branch, its
   parent, the relevant diffs, and every conflict marker. Resolve the conflict
   to preserve the intent of both the upstream changes and the branch's own
   patch, remove all conflict markers, and stage every resolved path. Continue
   only with:

   ```sh
   git-stack restack --continue
   ```

5. Repeat conflict resolution and `--continue` until the saved ancestor plan
   finishes and all requested pushes succeed. Do not switch to raw `git am
   --continue`, `git rebase --continue`, or `git merge --continue`; do not skip
   or abort merely because a conflict is difficult.

Stop instead of guessing if a conflict cannot be resolved without a material
product decision. Report the branch and paths that require that decision while
leaving the recoverable restack state intact.

## Report

Report the target branch, the worktree used, which branches were restacked and
pushed, and any conflicts resolved. If stopped, give the exact blocker and do
not claim the branch is current.
