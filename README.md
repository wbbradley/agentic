# Agentic Configuration

Personal instructions, skills, and harness configuration shared across coding agents.

## Layout

```text
.agents/
  AGENTS.md          # canonical, harness-neutral global instructions
  skills/            # portable Agent Skills (`<name>/SKILL.md`)
.claude/
  CLAUDE.md          # imports ../.agents/AGENTS.md
  skills -> ../.agents/skills
  settings.json      # Claude-only model, permissions, hooks, UI, and worktree settings
  remote-settings.json
```

`~/.agents` points to this repository's `.agents` directory and `~/.claude` points to its
`.claude` directory. Portable behavior belongs in `.agents`; harness-specific configuration belongs
in the corresponding harness directory.

## Install

```bash
git clone git@github.com:wbbradley/.claude.git ~/src/agentic
ln -s ~/src/agentic/.agents ~/.agents
ln -s ~/src/agentic/.claude ~/.claude
```

The repository remote still uses its historical `.claude` name. Renaming the remote repository is
optional and does not affect the local layout.

Codex discovers skills from `~/.agents/skills`. Its global instruction file is normally
`~/.codex/AGENTS.md`; link that file to the canonical source when needed:

```bash
ln -s ~/.agents/AGENTS.md ~/.codex/AGENTS.md
```

## Portability Rules

- Skill frontmatter contains only `name` and `description`.
- Skill bodies describe capabilities, not harness-specific tool names or model tiers.
- The current user request replaces slash-command-only placeholders such as `$ARGUMENTS`.
- Delegation and structured questions use the active harness's available capability, with a local
  fallback when the capability is absent.
- Shared workflows are read explicitly by path; they do not rely on Claude's `@file` expansion.

## Claude-Only Settings

The following remain in `.claude/settings.json` because they are not portable instruction content:

- Claude model and effort selection
- permission allow/deny lists
- lifecycle hooks (`shellsafety`, tmux notifications, resume, and cleanup)
- worktree, status-line, TUI, voice, and experimental feature settings

Configure equivalents in each harness rather than translating them into `AGENTS.md` or skills.

## Task Skills

- **todo**: research and add work to the front of `PLAN.md`
- **later**: research and add work to the back of `PLAN.md`
- **list-tasks**: summarize remaining plan items
- **next-task**: plan, implement, verify, commit, and archive the next item
- **find-bugs**: audit a codebase and add verified findings to the plan
