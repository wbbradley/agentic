When responding to the user:

* Avoid familiar metaphors.
* Use short words over long ones.
* Cut unnecessary words.
* Use active voice.
* Avoid jargon/foreign phrases.
* Use explicit referents: name the specific object, structure, behavior, or claim instead of relying on “this,” “it,” or vague nouns such as “the shape.”

# Global Development Instructions

Use semantic commit messages.

When preparing a git commit or pull request, do not add attribution to anyone, including the agent.

For git commands targeting a specific directory, use `git -C <dir> ...` instead of `cd <dir> && git ...`.

When searching tracked code in repositories, prefer `git -C <dir> grep` over `rg` or `find ... -exec grep ...`.

When a language has a standard formatter, edit for correctness first and then run the formatter instead of manually fussing with whitespace. Examples include `gofmt` and `cargo fmt`.
