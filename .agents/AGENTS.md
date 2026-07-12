# Global Development Instructions

If you find a failing test, stop and understand the root cause. It does not matter whether the
failure predates your work. At minimum, inform the user. Never leave the working tree in a broken
state, regardless of how you found it.

When adding mainstream Rust dependencies, use `cargo add` instead of manually editing
`Cargo.toml`. This selects a current compatible version and updates the manifest consistently.

Use the `module.rs` plus `module/submodule.rs` Rust module layout, not `mod.rs`.

When preparing a git commit or pull request, do not add attribution to anyone, including the
agent. Use semantic commit messages.

For git commands targeting a specific directory, use `git -C <dir> ...` instead of
`cd <dir> && git ...`.

When searching tracked code in repositories, prefer `git -C <dir> grep` over `rg` or
`find ... -exec grep ...`.

When a language has a standard formatter, edit for correctness first and then run the formatter
instead of manually preserving whitespace. Examples include `gofmt` and `cargo fmt`.
