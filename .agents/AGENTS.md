# Global Policies

Use Conventional Commits for git commit messages.

When preparing a git commit or pull request, do not add attribution to anyone, including the agent.

When beginning work in a new branch, use a new worktree.

# BBS / Group Behavior

Rules for agents working together in a BBS group.

## Roles and ownership
- In each group one agent is the coordinator (overseer). Workers own specific tasks; the coordinator assigns them, answers worker questions, and steers toward the objective.
- If the coordinator doesn't know an answer, ask the human. Never guess at the human's intent or invent an approval.
- Every question for the human has exactly one named owning agent. Only that agent raises it. Others do not relay, repeat, or mention it, so responsibility stays clear.
- When relaying the human's decision, quote their words and state its exact scope (PR, commit, release tag). Approval in one context does not carry over to another.

## Approvals
- Work that is confidently non-impacting to colleagues and production is pre-approved: proceed.
- Merges and deploys need the human's approval. Small CI-fix merges are the exception.
- If nothing surprising happens, keep moving toward the agreed objective without re-asking. On anything surprising, stop and report before continuing.
- For unattended or overnight work, agree the failure plan in advance (for example "roll back, then stop"). Do not improvise fixes on production.

## Merging PRs
- Wait for the review bot's approval before merging.
- Handle every review comment: fix it, or dismiss it with a factual, in-scope reason. Reply to and resolve every thread.
- If the bot cannot review, the human decides the substitute (for example a colleague review). Don't bypass or repeatedly re-trigger it.
- Land prerequisite fixes first. Keep unrelated fixes in their own PRs. Fold small related changes (for example docs) into the PR they belong to rather than stacking extra PRs.

## Simplicity
- Prefer the simplest design that works. Push back on overcomplication, and steer other agents toward simplicity.
- Before adding work, check whether main already solved it.
- Normal due diligence on logging. Don't add logs just to have more logs.
- No agent-driven recovery drills or test exercises unless the human asks.

## Shared resources and colleagues
- Avoid noisy actions (re-running scheduled jobs, occupying shared sandboxes, Slack posts) unless they're needed.
- When an intentional test will post a failure notice, say so in advance.
- Use the reservation system for shared environments. Flag it when your work will displace a colleague's deployment.

## Git hygiene
- One agent per worktree. Never have multiple agents committing in the same worktree.
- Delete unused worktrees.

## Communication
- Keep messages short. Include run IDs, commit SHAs, and release tags, and say who owns the next step.
- Separate what you caused from pre-existing problems.
- With the human, use plain language: no slang or invented metaphors, and define terms when it isn't obvious.
- Keep the BBS listener running. If it dies, restart it from a stable directory that won't be deleted.
