---
name: linear
description: Use this skill whenever the user mentions Linear, Linear issues, Linear tickets, Linear tasks, the `linear` CLI, or anything involving Linear.app project/issue tracking. It explains how to drive the `linear` CLI (by @schpet) and fall back to the Linear GraphQL API for the user Will Bradley, whose Linear account is on the Walrus Core (WAL) team.
---

# Linear CLI Quickstart

The `linear` command (from `@schpet/linear-cli`, v2.x) is installed globally on this machine. Use
`linear <command> --help` as the canonical reference for details beyond the hotspots below. If the
active harness exposes an additional `linear-cli` skill, read it as supplementary guidance. This
skill captures the local context and CLI quirks that should not be rediscovered each time.

## User context

- **User:** Will Bradley
- **Default Linear team:** `WAL` (Walrus Core). Most or all assigned issues live here.
- **Linear priority encoding:** `0 = No priority, 1 = Urgent, 2 = High, 3 = Medium, 4 = Low`.
  Lower number ≠ lower importance. Always translate to words when reporting to the user.

## Top-level command map

```
linear auth              # login/logout/whoami
linear issue (i)         # create/list/view/comment/update issues
linear team (t)          # list/find teams
linear project (p)       # projects
linear cycle (cy)        # team cycles
linear milestone (m)
linear initiative (init)
linear label (l)
linear document (doc)
linear api               # raw GraphQL fallback
linear schema            # dump the GraphQL schema
```

Every command supports `--help`. When in doubt, run `linear <cmd> --help`.

## Gotchas that bit last time

1. **`linear issue list` and `linear issue mine` both require a sort order.** Pass `--sort priority`
   (or `--sort manual`), set `issue_sort` in `.linear.toml`, or export `LINEAR_ISSUE_SORT=priority`.
   Without one you get:
   `Failed to list issues: Sort must be provided via command line flag, configuration file, or LINEAR_ISSUE_SORT environment variable`

2. **`linear issue mine` requires a team.** It is *per-team*, not global. Either pass `--team WAL`
   (or whatever team key applies) or run it from a directory where the team can be inferred.
   Without one you get:
   `Failed to list issues: Could not determine team key from directory name or team flag`

3. **There is no built-in way to list issues across all teams via the CLI.** Use the GraphQL API
   fallback (`linear api`) for cross-team queries like "all issues assigned to me everywhere".

4. **`linear issue mine` defaults to `--state unstarted` only.** Pass `--all-states` or repeat
   `--state started --state unstarted --state backlog` to widen the set.

5. **`--no-pager` is only valid on `issue list`** — passing it to `project list`, etc. errors out.

6. **File-based input beats inline strings for markdown.** Use `--description-file` on
   `issue create`/`issue update` and `--body-file` on `issue comment add`/`update`. Inline
   `--description`/`--body` mangle newlines and special characters in the Linear UI.

## Recipes

### List the user's open issues across all teams (cross-team, sorted by priority)

The CLI alone cannot do this; use the GraphQL API. This is what Will will usually mean by
"list my Linear issues".

```bash
linear api <<'GRAPHQL'
{
  viewer {
    id
    name
    assignedIssues(
      first: 100,
      filter: { state: { type: { nin: ["completed", "canceled"] } } }
    ) {
      nodes {
        identifier
        title
        priority
        state { name type }
        team { key }
        updatedAt
      }
    }
  }
}
GRAPHQL
```

Then translate `priority` using the mapping above and group by state
(In Progress → Todo → Backlog). The result is JSON on stdout — pipe to `jq` if you need to
reshape it.

### List open issues on a specific team via the CLI

```bash
linear issue mine --team WAL --sort priority --all-states
```

or just

```bash
linear issue list --team WAL --sort priority
```

### Find teams and their keys

```bash
linear team list
```

Use the `KEY` column (e.g. `WAL`, `CORE`, `DVX`) when passing `--team`.

### View, start, create, comment on an issue

```bash
linear issue view WAL-1207                 # show details
linear issue start WAL-1207                # move into In Progress + branch helper
linear issue url WAL-1207                  # print the web URL
linear issue create --team WAL --title "..." --description-file /tmp/desc.md
linear issue update WAL-1207 --description-file /tmp/desc.md
linear issue comment add WAL-1207 --body-file /tmp/comment.md
linear issue comment list WAL-1207
```

## GraphQL fallback — when and how

Reach for `linear api` whenever the CLI lacks a flag you need (cross-team listing, custom filters,
bulk reads, reading fields the CLI does not surface). Two rules:

1. **Queries with non-null markers (`String!`, `Int!`, etc.) must be passed via heredoc on stdin**,
   not as a shell argument, or the `!` will be mangled.
2. **Pass variables with `--variable key=value`** for scalars, or `--variables-json '{...}'` for
   structured inputs.

Examples:

```bash
# Schema discovery — write once, grep locally
linear schema -o "${TMPDIR:-/tmp}/linear-schema.graphql"
# then: grep -A 30 "^type Issue " "${TMPDIR:-/tmp}/linear-schema.graphql"

# Who am I?
linear api '{ viewer { id name email } }'

# Search by free text
linear api --variable term=oyster <<'GRAPHQL'
query($term: String!) {
  searchIssues(term: $term, first: 20) {
    nodes { identifier title state { name } team { key } }
  }
}
GRAPHQL
```

## When reporting results to the user

- Translate priority integers to words (Urgent/High/Medium/Low/No priority).
- Group by state (In Progress, Todo, Backlog) — it almost always matches how the user thinks.
- Show the issue identifier (e.g. `WAL-1207`) so the user can click through / feed it to
  other `linear` subcommands.
- If you needed the GraphQL fallback because of a CLI limitation, mention it briefly so the user
  knows why you did not use `linear issue mine`.
