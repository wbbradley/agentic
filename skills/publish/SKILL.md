---
name: publish
description: Prepare a project for release — update README, changelog, commit changes, bump version, tag, and guide the user through the final push/publish.
---

## Publish Workflow

Prepare the current project for a release. `$ARGUMENTS` may specify the version bump type (patch,
minor, major) or an explicit version number. Default to **minor** or **patch** if unspecified. When
we are below version 1.0, don't ask, just use your intuition.

### Step 0: Preflight

**Detect project type** by scanning for version-bearing files in this priority order:

| File | Project type | Version location |
|------|-------------|-----------------|
| `Cargo.toml` | Rust | `version = "..."` |
| `package.json` | Node.js | `"version": "..."` |
| `*.cabal` | Haskell/Cabal | `Version: ...` |
| `pyproject.toml` | Python | `version = "..."` |
| `setup.py` | Python (legacy) | `version="..."` |
| _(none found)_ | Generic | version derived from last git tag |

Read the version file to find the current version. Run `git status` and `git diff` to understand
what uncommitted changes exist. Find the most recent version tag (e.g.,
`git tag --list 'v*' --sort=-v:refname | head -1`) to establish the baseline for changelog and
breaking-change analysis.

If there are no changes since the last tag and no uncommitted work, tell the user there's nothing
to publish and stop.

### Step 1: Update README.md

Read the current `README.md` and scan the codebase (public API surface, examples, CLI flags, etc.)
for anything that should be reflected in the README but isn't. The README should describe the
project accurately — what it does, how to install it, how to use it. This is **not** a changelog;
do not list individual changes or version history. Only edit the README if something is materially
missing or incorrect. If the README is already accurate, skip this step.

### Step 2: Analyze changes and update CHANGELOG.md

Launch a sub-agent (subagent_type: "general-purpose") to perform an in-depth analysis of all
changes since the last version tag. Provide the sub-agent with the last version tag, current
version, and detected project type from Step 0.

The sub-agent should:

> Analyze all changes between the last version tag and HEAD (use `git log <tag>..HEAD` and
> `git diff <tag>..HEAD`). Read through every changed file carefully.
>
> **Breaking change analysis:** Look specifically for:
> - Removed or renamed public functions, types, modules, or API surface
> - Changed function/method signatures on public items
> - Changed semantics of existing public APIs
> - Removed or renamed CLI flags or subcommands
> - Changed default behaviors
> - Changed minimum language/runtime version requirements
> - Removed feature flags or configuration options
> - Changed serialization/deserialization or wire formats
> - Changed policy DSL syntax or semantics (if applicable)
>
> **Changelog generation:** Categorize all changes into:
> - **Breaking Changes** (if any)
> - **Added** — new features, new public API surface
> - **Changed** — non-breaking modifications to existing behavior
> - **Fixed** — bug fixes
> - **Removed** — removed features or deprecated items
>
> Return:
> 1. A boolean: whether any breaking changes were found.
> 2. A list of breaking changes (if any), each with a clear explanation of what broke and what
>    users need to do to migrate.
> 3. The categorized changelog entries, written concisely from the user's perspective (not
>    developer internals).

After the sub-agent returns:

- If breaking changes were found, **present them to the user** and ask whether the version bump
  should be upgraded to a major (or minor, if pre-1.0) bump. Wait for confirmation before
  proceeding.
- Read `CHANGELOG.md` (or create it if it doesn't exist). Add a new section at the top for the
  new version using this format:

```markdown
## [<new_version>] - <YYYY-MM-DD>

### Breaking Changes
- ...

### Added
- ...

### Changed
- ...

### Fixed
- ...
```

Omit any category that has no entries. Use the date of today.

### Step 3: Commit all pending changes

Stage and commit all meaningful changes (including any README and CHANGELOG updates from prior
steps) following normal commit hygiene — semantic commit messages, no attributions. If there are no
uncommitted changes, skip this step.

### Step 4: Bump the version

Determine the new version:
- If the user overrode the bump level in Step 2 due to breaking changes, use that.
- If `$ARGUMENTS` contains "major", "minor", or "patch", apply that bump to the current version.
- If `$ARGUMENTS` contains an explicit version (e.g., "1.2.3"), use it directly.
- Otherwise, default to a **patch** bump.

Edit the version in the appropriate file for the detected project type:

| Project type | What to edit |
|-------------|-------------|
| Rust | `version = "..."` in `Cargo.toml`. If this is a workspace with multiple publishable crates, ask the user which crate(s) to bump. |
| Node.js | `"version": "..."` in `package.json` |
| Haskell/Cabal | `Version: ...` in the `.cabal` file |
| Python | `version = "..."` in `pyproject.toml` (or `setup.py`) |
| Generic | No file to edit — version exists only in the git tag |

### Step 5: Build verification

Verify the project builds cleanly before tagging. If the build fails, stop and report the error —
do not proceed with a broken release.

| Project type | Build command |
|-------------|--------------|
| Rust | `cargo build --release` (also updates `Cargo.lock`) |
| Haskell/Cabal | `cabal build --allow-newer` |
| Node.js | `npm run build` (if a `build` script exists in package.json) |
| Python | skip (unless you know the standard build command for this project) |
| Generic | skip unless you can identify an obvious build command |

### Step 6: Commit the version bump

Stage the version file(s) and any lockfiles that changed (e.g. `Cargo.lock`, `package-lock.json`)
and commit with the message:

```
chore: bump version to <new_version>
```

For **Generic** projects (tag-only versioning) there is nothing to commit here — skip this step.

### Step 7: Tag the release

Create an annotated git tag:

```bash
git tag -a v<new_version> -m "v<new_version>"
```

### Step 8: Hand off to the user

Tell the user the release is ready. Suggest the appropriate push/publish commands based on the
detected project type:

**Rust:**
```bash
git push && git push --tags && cargo publish
```

**All other project types** (typically CI handles the rest):
```bash
git push && git push --tags
```

Then stop and yield to the user.
