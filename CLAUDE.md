If you find a failing test, stop everything and understand the root cause. It doesn't matter if you
think it was failing before you got there. At the very least, inform the user. Do not ever leave the
world in a broken state, regardless of how you found it.

When adding mainstream dependencies in Rust, always use `cargo add` rather than manually editing
Cargo.toml. This ensures we get the latest versions.

When in a cargo workspace, to check compilation and to re-format Rust code, just run `chk` which is
in my PATH at ~/.local/bin. It runs `cargo fmt ...` as well as `cargo clippy --fix`, and some other
checks.

We always use module.rs + module/submodule.rs file layout, not mod.rs file layout.

When asked to put together a git commit or PR, do not add any attributions to anyone, including
yourself. Use semantic git commits.

For git commands in a specific directory, avoid `cd ... && git ...` instead use `git -C dir ...`

When searching for code in repos, prefer `git -C dir grep` over other options like `rg` and `find ... -exec grep ...`.

When editing code in any language with a standard formatter, just bluntly edit the code without
worrying about whitespace, then use the formatter to fix it. (ie: gofmt, chk in the case of Rust, as
mentioned above.)

Never ask me to /schedule an agent in some time. If you think that needs to happen, use the /later
skill right now to append that to the PLAN.md.

Terse shorthand is fine between tool calls (that's you thinking out loud, and brevity
there is good). Your final summary is different: it's for a reader who didn't see any of
that.

If you've been working for a while without the user watching (overnight, across many
tool calls, since they last spoke), your final message is their first look at any of it.
Write it as a re-grounding, not a continuation of your working thread: the outcome
first, then the one or two things you need from them, each explained as if new. The
vocabulary you built up while working is yours, not theirs; leave it behind unless you
re-introduce it.

When you write the summary at the end, drop the working shorthand. Write complete
sentences. Spell out terms. Don't use arrow chains, hyphen-stacked compounds, or labels
you made up earlier. When you mention files, commits, flags, or other identifiers, give
each one its own plain-language clause. Open with the outcome: one sentence on what
happened or what you found. Then the supporting detail. If you have to choose between
short and clear, choose clear.
