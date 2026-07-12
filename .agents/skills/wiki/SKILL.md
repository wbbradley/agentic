---
name: wiki
description: Extract key learnings from the current thread and file them into the user's personal wiki at ~/wiki, keeping the ontology (index.md) tidy and re-parenting/reorganizing the topic tree as it grows.
---

# Wiki Workflow

You are adding knowledge from the current conversation into Will's personal wiki
at `~/wiki` (a git repo). The thread you are in right now is the source
material — the user has decided something in it is worth preserving.

Your job: distill the learning into a leaf note, place it at the right spot in
the ontology, update the ontology, and commit. Leaves carry the weight — dense,
structured, with references. Indexes stay thin. Keep the tree sane as it grows.

Treat any topic or path in the current user request as a hint about what to capture
(a topic name, a suggested path, "the Rust part", etc.). Otherwise infer
from context.

**Conventions live in `~/wiki/AGENTS.md`, with `~/wiki/CLAUDE.md` as a legacy fallback** — file
layout, frontmatter shape, lightweight-index rule, move/rename rules, and commit format. Read the
first one that exists. This skill covers only the workflow; that file covers the output invariants.
Do not duplicate its content here.

## Step 1: Read the ontology

Read `~/wiki/index.md` in full. It is the canonical map of the tree — every
leaf should be reachable from it. Also list the wiki directory
(`git -C ~/wiki ls-files`) so you see the actual file layout, not just what
the index claims.

## Step 2: Distill the learning

From the current thread, write a concise note. Content guidance:

- **A one-paragraph lede** stating the takeaway in plain terms.
- **Sections** for sub-topics. Use headings, lists, tables, code blocks.
  Preserve structure — a flat blob is harder to scan.
- **References** at the bottom: every external source used in the thread,
  as markdown links. If the thread did web searches, cite the specific URLs,
  not the search query.

Keep it dense but readable. Favor bullets and short paragraphs over walls of
prose. No filler ("In this note, we will explore…"). State things directly.

Never write a note longer than the underlying material justifies. A two-line
fact is a two-line note.

## Step 3: Pick the topic path

Decide where the note belongs. The path is `~/wiki/<topic>/<subtopic>/.../<slug>.md`.

Rules:

1. **Prefer existing topics.** If the subject fits under a branch that already
   exists, put it there. Don't invent a parallel topic.
2. **Don't duplicate.** If a relevant note already exists, extend it rather
   than creating a parallel one. Bump its `updated` frontmatter.
3. **Create new branches sparingly.** A new top-level topic is a commitment.
   If the note is the only thing under it, ask: will there plausibly be
   more? If not, file it under an existing branch.
4. **Depth is free, but only up to a point.** Three or four levels is fine
   (`ai/llms/ingestion/html-to-markdown.md`). Beyond that the path becomes
   noise.

If the current user request specified a path, respect it unless it contradicts
an existing organization in a way you should flag.

## Step 4: Consider re-parenting

Before writing, look at the surrounding sub-tree. Adding this note may reveal
a better shape for the tree. Specific triggers:

- **A sibling topic keeps appearing.** If you are about to write the third
  note tagged `rust` under `ai/llms/`, the real topic is probably `rust`, not
  `llms`. Consider a top-level `rust/` branch, or a cross-cutting `tags`
  structure.
- **An index has grown long.** More than ~10 entries at a single level is a
  smell. Split by sub-theme.
- **Two branches are near-duplicates.** Merge them.

If you think the tree needs reshaping, **propose the change to the user before
executing it**. Show: current shape, proposed shape, which files would move
where, and which `index.md` entries would update. Only proceed on approval.
Reorganization is cheap when done deliberately, expensive when done silently.

## Step 5: Write files

1. Create/update the leaf note at the chosen path (`mkdir -p` any missing
   parent directories).
2. Update `~/wiki/index.md` to list the note — one line, descriptive enough
   that a reader can tell whether it's what they want, short enough to not
   bloat the index.
3. If the sub-tree under the new leaf has enough notes to deserve its own
   overview, optionally create a `<topic>/index.md`.

Do not write documentation or README files beyond what's needed here.

## Step 6: Commit

Commit format lives in the wiki's instruction file. Typical messages:

- `docs(wiki): add note on html-to-markdown for LLM ingestion`
- `docs(wiki): extend ai/llms/html-to-markdown with llms.txt probing notes`
- `refactor(wiki): split rust out of ai/llms into its own top-level topic`

Do not push unless the user asks.

## Step 7: Report back

Tell the user, briefly:

- What note was written (path + one-line summary).
- Any tree reorganization that happened.
- Anything from the thread you intentionally left out and why (e.g., "the
  Rust crate comparison was too transient to file; I kept only the
  cascade recommendation").

Then stop.
