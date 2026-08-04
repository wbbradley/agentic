---
name: babysit-pr
description: "Continuously watch a GitHub PR until every required check is green and every new review/issue comment has been addressed and replied to. Use when asked to babysit, watch, monitor, or nurse a PR to green, or to keep handling incoming PR feedback until it's merge-ready."
---

# Babysit a PR

Watch one PR in a loop. Each cycle: pull the latest CI state and comments, fix failing **required** checks, respond to any **new** comments, push, and repeat. This runs **indefinitely** and autonomously on the PR branch — the whole point is that the user walks away. This skill does **not** self-complete: keep the monitor armed and keep handling events until the user explicitly tells you to stop (see *There is no stop condition* below). Green CI with all comments answered is a milestone to report, not a reason to stop.

## Identify the PR

- Default to the current branch's PR: `gh pr view --json number,url,headRefName,baseRefName`.
- If the user named a PR number or URL, use that. Derive `OWNER/REPO` with
  `gh repo view --json nameWithOwner -q .nameWithOwner`.

## The loop

Drive everything through the GitHub API with `gh api` (and thin `gh` wrappers). Do **not** depend on any MCP or helper tool — the skill must work in any session with only `gh` authenticated.

Resolve the identifiers once, and refresh `SHA` after every push (a push creates a new head commit, and checks are keyed on the SHA):

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
N=<pr-number>
SHA=$(gh pr view "$N" --json headRefOid -q .headRefOid)
BRANCH=$(gh pr view "$N" --json headRefName -q .headRefName)
```

Each cycle:

1. **Checks — read BOTH sources** (a required context can be either a check-run or a legacy commit status; one endpoint misses the other):
   - `gh api repos/$REPO/commits/$SHA/check-runs --paginate -q '.check_runs[] | "\(.name)\t\(.status)\t\(.conclusion)"'`
   - `gh api repos/$REPO/commits/$SHA/status -q '.statuses[] | "\(.context)\t\(.state)"'`
   - Optional aggregated view of the same data: `gh pr checks $N`.
2. **Comments — read ALL THREE endpoints** (different APIs; missing one drops feedback):
   - Review (inline on code): `gh api repos/$REPO/pulls/$N/comments --paginate`
   - Issue (general discussion): `gh api repos/$REPO/issues/$N/comments --paginate`
   - Review **summaries** (top-level review bodies, NOT inline): `gh api repos/$REPO/pulls/$N/reviews --paginate` — **this is a distinct third source that inline+issue queries both miss.** Devin (and humans) post a review with a top-level body on every push (e.g. `**Devin Review** found N new potential issues`); those bodies live here, not under `pulls/comments` or `issues/comments`. A review body with `state=="CHANGES_REQUESTED"` is also a merge gate.
   - **Actually READ the bodies every cycle — do not shortcut to "count new top-level IDs".** Comparing `max(id)` to a last-seen id catches a brand-new top-level thread but silently misses (a) a new **reply** on an existing thread (a human answering your reply), (b) a new **review summary** on `pulls/reviews`, and (c) an edited body. Each cycle, pull all three endpoints and read what changed, then decide per item. Enumerate unaddressed inline threads structurally (below); for issue comments and review summaries, read each body and confirm it has your Claude-signed reply (issue-comment replies are new issue comments; review-summary replies are a new issue comment referencing it).
   - **NEVER filter the enumeration by author.** Human reviewers matter most, and bots are not the only source. Do not `select(.user.login=="…bot…")` — that silently drops every human comment. List them all, then decide per comment.
   - **A comment under your own account is NOT necessarily yours.** Your `gh` token may post under the *same* GitHub identity a human reviewer uses (e.g. both appear as `wbbradley`), so login can't tell your replies from their comments. Distinguish structurally, not by author: **your** replies are the ones signed as Claude and sitting in a reply thread (`in_reply_to_id != null`); an **unaddressed** comment is a top-level review comment (`in_reply_to_id == null`) with no Claude-signed reply beneath it. Enumerate outstanding threads that way: `gh api repos/$REPO/pulls/$N/comments --paginate -q '.[] | select(.in_reply_to_id==null) | "\(.id)\t\(.user.login)\t\(.path):\(.line)"'` then cross off any whose thread already has your Claude-signed reply.
3. **Merge state** — `gh pr view $N --json mergeable,mergeStateStatus`. If it is `CONFLICTING`/`DIRTY` (or `BEHIND` when the repo requires the branch be up to date), the base branch moved and the PR needs to be restacked before it can land — see *Merge conflicts*. `UNKNOWN` means GitHub is still computing; re-poll.
4. Act on anything **new** since last cycle (track handled comment IDs; only respond once per comment).
5. Push fixes, then re-read `SHA`. A push starts new checks → next cycle waits on them.

### Waiting between cycles — a GLOBAL monitor, interpreted by you (never by bash)

**Do not wait for the whole check suite to finish before reacting.** A single
slow job (a 30–90 min KVM/e2e run) must never delay your response to a check that
has *already* failed. `gh pr checks --watch` blocks until *every* check settles,
so on its own it will sit for an hour while reds pile up unaddressed — **do not
use it as your only signal.** (This burned a real run: 12 e2e shards failed while
the watcher blocked on a still-running KVM job, and the user found the reds first.)

Use the **Monitor tool** (it re-invokes you per emitted line), but the monitor's
only job is to tell you **something on the PR changed** — nothing more. It MUST be
**global**: it fires on *any* change to the PR (a check flips state, a new comment,
merge state changes), and it MUST NOT classify, filter, threshold, or decide
"red"/"settled"/"pass" in bash. All interpretation happens in your head, in
context, on the full state — not in `awk`/`jq` conditionals.

**Err on the side of TOO MANY updates.** Frequent wake-ups are cheap; a missed
event is not. Every queued→in_progress→completed transition is fine to surface —
bring **every** PR event into context and handle it there. Do **not** get clever
with the projection to cut notification volume: never coarsen it to "completed
checks only", never debounce, never suppress the start-up churn. If the monitor
fires every 30s during ramp-up, that is working as intended — glance at the state,
note "nothing actionable", and move on. When in doubt, emit and interpret in
context. The one and only thing you may exclude from the hash is volatile
timestamps (below), because a timestamp tick is not a state change at all.

Emit one line whenever a cheap snapshot of the PR's state changes (hash-diff only —
that is change *detection*, not filtering). **Hash only state fields, never volatile
timestamps.** `gh pr view --json statusCheckRollup,...,updatedAt` carries per-run
`startedAt`/`completedAt` and `updatedAt`, which tick every poll on a long-running
suite — hashing those makes the monitor fire every 30s on non-events (a KVM job
still running is not an event). Project to just each check's `name|status|
conclusion`, the legacy statuses, comment IDs, and merge state, then hash that.
Dropping timestamps is not filtering *events* — a timestamp tick is not an event;
a status/conclusion transition is:

```bash
REPO=<owner/repo>; N=<pr>
prev=""
while true; do
  SHA=$(gh pr view "$N" --json headRefOid -q .headRefOid 2>/dev/null)
  checks=$(gh api "repos/$REPO/commits/$SHA/check-runs" --paginate -q '.check_runs[] | "\(.name)|\(.status)|\(.conclusion // "-")"' 2>/dev/null | sort)
  statuses=$(gh api "repos/$REPO/commits/$SHA/status" -q '.statuses[] | "\(.context)|\(.state)"' 2>/dev/null | sort)
  comments=$(gh api "repos/$REPO/issues/$N/comments" --paginate -q '.[].id' 2>/dev/null; gh api "repos/$REPO/pulls/$N/comments" --paginate -q '.[].id' 2>/dev/null; gh api "repos/$REPO/pulls/$N/reviews" --paginate -q '.[] | "\(.id)|\(.state)"' 2>/dev/null)
  merge=$(gh pr view "$N" --json mergeable,mergeStateStatus -q '"\(.mergeable)|\(.mergeStateStatus)"' 2>/dev/null)
  cur=$(printf '%s\n%s\n%s\n%s\n%s' "$SHA" "$checks" "$statuses" "$comments" "$merge" | shasum | cut -d' ' -f1)
  [ "$cur" != "$prev" ] && { echo "PR #$N state changed"; prev="$cur"; }
  sleep 30
done
```

The projection lists *every* check with its full status/conclusion — that is what
keeps it global (any check's transition, any new comment, any merge-state change
emits). It just excludes fields that change without an event. Re-reading `SHA` each
loop also means the monitor survives a push (new head) without needing a re-arm.

- Every emitted line pulls you back. When it does, **read the full state yourself**
  — checks (both `check-runs` and `status` endpoints), comments (all three
  endpoints: `pulls/comments`, `issues/comments`, `pulls/reviews`), and merge
  state — and decide what changed and what to do. Do not rely on the
  monitor to have pre-selected the important event; it only says "look again."
- Act the moment a required check is red (diagnose/fix or re-run per *Fixing
  checks*) without waiting for slow jobs still running.
- You — not the monitor — evaluate the *Stop condition* each time you're pulled
  back. There is no `ALL_SETTLED` sentinel; you judge settledness from the state.
- The monitor runs until you stop it (`TaskStop`) or it times out; re-arm it after
  each push (a push changes nothing about the monitor, but keep it alive across the
  session). Running this skill under `/loop` also works.

## Responding to comments

- **Respond to EVERY comment** — every review (inline) comment and every issue
  (discussion) comment, from humans and bots alike. No comment goes unanswered.
  This is autonomous: reply as part of the loop; do not wait for a go-ahead.
- **Human comments especially.** Bot findings are often the easy majority; do not let
  them crowd out a human reviewer's terse note (`"this is weird code structure"`,
  `"time all file operations on juicefs"`). Those are real, actionable review
  feedback — address them in code and reply, same as any bot finding.
- **Sign every reply as Claude.**
- **NEVER resolve a thread.** Leave all threads open for the human reviewer to
  resolve — replying is your job, resolving is theirs.
- **Address valid code feedback in code first**, then reply pointing at the fix.
  "Address" means change the code — a reply alone is not addressing it.
  - Reply to a review comment: `gh api repos/OWNER/REPO/pulls/<N>/comments/<COMMENT_ID>/replies -f body='...'`
  - Reply to an issue comment: `gh api repos/OWNER/REPO/issues/<N>/comments -f body='...'`
- For feedback you're **not** acting on (false positive, out of scope, disagree),
  still reply — with the reasoning — rather than staying silent.
- Track which comment IDs you've answered so you reply exactly once per comment.
- Automated reviewers (e.g. Devin) post on every PR — reply to all of them:
  act on the valid points, briefly explain the non-actionable ones.

## Fixing checks

- Only fix **required** checks. Ignore advisory / non-required bots (still reply
  to their comments, but don't chase their status).
- If a required check is red because it's stale or flaky, **re-run failed jobs
  first** (`gh run rerun <run-id> --failed`) before assuming it's your bug.
- Pull failing logs: get the run id from the failing check-run's `details_url`
  (or `gh run list --branch $BRANCH --limit 15`), then `gh run view <run-id> --log-failed`.
  Diagnose, fix minimally, push.

## Restack conflicts

When the PR goes `CONFLICTING`/`DIRTY` (or `BEHIND` under a require-up-to-date branch rule), use `git-stack sync && git-stack restack -afp` to bring this PR up to date, you are responsible for fixing all conflicts in the process. This may be tricky if a parent branch is in a worktree. I own git-stack. Its sources live in `~/src/git-stack` if you need to inspect it or report bugs.

## There is no stop condition — babysitting never self-completes

**Babysitting NEVER ends on its own.** A PR is never "done": a reviewer can push a new comment, request a change, or the base can move and re-block the branch at any moment — including hours after CI goes green. Reaching green CI with every comment answered is a **milestone to report, not a reason to stop.** Do **not** stop the monitor, do **not** treat "merge-ready" as terminal, and do **not** wind down the loop yourself. Keep the global monitor armed and keep handling every event until **the user explicitly tells you to stop** (or the session ends). The **one** genuine terminal state is the PR itself closing: once `state` is `MERGED` or `CLOSED`, there is no branch left to babysit — stop the monitor and report. Nothing short of that (green CI, approval, merge-ready) ends the loop.

**Merge-ready milestone** — when all of these hold across a fresh cycle, report it
(and push a notification), then **keep watching**:
- Every required check is green (and no non-required workflow is failing), and
- The PR is mergeable (not `CONFLICTING`/`DIRTY`), and
- **Every comment — from every author, across all THREE endpoints (`pulls/comments`
  inline, `issues/comments`, `pulls/reviews` summaries) — has been addressed and has
  been replied to and resolved.**

Do the enumeration fresh each time — a green check suite with unanswered human review comments is **not** even at the milestone. Report the milestone with: final check status, comments handled, commits pushed, and what it's now waiting on (e.g. human CODEOWNERS approval). Do **not** merge — merging needs CODEOWNERS approval and human-resolved threads. Then stay in the loop: the next new comment or check flip pulls you right back in.

## Guardrails

- **The moment any required check turns red, act on it immediately** — never let a slow, still-running check delay your response to one that has already failed.
- **Monitors must be global and dumb, and err toward too-frequent.** A monitor may only detect "the PR changed" and pull you back; it must never filter to specific events or classify pass/fail/settled in bash. Interpret every event yourself, in context, against the full PR state. No `awk`/`jq`/`grep` conditionals that decide which events matter. Never coarsen or debounce the projection to reduce notification volume — bring **every** event into context and handle it there; frequent quiet wake-ups are the intended cost.
- Never close the PR. Never merge unless explicitly asked.
- If a fix needs a non-obvious design decision or changes behavior/scope, **pause and ask** — autonomy covers mechanical fixes and clear-cut feedback, not ambiguous product calls.
- Surface a short status line each cycle so the user can follow along; push a notification when you hit the stop condition or get blocked.
