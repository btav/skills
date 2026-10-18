# Shared diff selection

Use these rules for review, diff walkthroughs, blast-radius analysis, PR bodies, and review loops. Honor any change set, base, range, or fixed review anchor explicitly supplied by the user or calling skill before applying defaults.

Run Git commands from the repository root, found with `git rev-parse --show-toplevel`, so paths and untracked-file discovery cover the whole repository. Resolve and verify refs before using them in a diff.

## Choose the change set

Unless a source was specified:

1. A named PR takes precedence. Read its title, body, and diff with `gh pr view <PR>` and `gh pr diff <PR>`.
2. On a feature branch, use its committed changes against the resolved default branch.
3. On the default branch, use uncommitted working changes.

If the source is unclear, including a detached checkout without a specified source, ask one short question before proceeding. An explicit request for working changes does not require discovering the default branch.

## Resolve the default branch

1. Read `git symbolic-ref --quiet refs/remotes/origin/HEAD`. Use its target if `git rev-parse --verify "<ref>^{commit}"` confirms that it exists.
2. If no valid configured target exists, check `refs/remotes/origin/main` and `refs/remotes/origin/master`. Use the candidate if exactly one resolves to a commit.
3. If neither remote-tracking candidate exists, check `refs/heads/main` and `refs/heads/master` in the same way.

If both candidates at a fallback step exist, ask which is the default; do not choose whichever was checked first. If no candidate resolves, report the missing base and ask. A configured default may be named something other than `main` or `master`. The current branch's upstream is not necessarily the default branch.

## Resolve a PR base

For a named PR, use its actual target branch, available from `gh pr view <PR> --json baseRefName`, rather than the repository default. A user-specified comparison base overrides this selection.

For local analysis or a review loop, verify that the checkout matches the requested PR head, then resolve the base branch in the PR's base repository, preferring its remote-tracking ref over a local branch. For a forked PR, do not mistake a ref in the fork for the base repository's ref. If the required checkout or ref is unavailable or ambiguous, report it and ask rather than substituting `main` or `master`.

## Build the diff

- **Committed branch changes:** resolve `review_anchor` with `git merge-base HEAD "$base_ref"`, then use `git diff "$review_anchor..HEAD" --`. For a PR body, read `git log --oneline "$review_anchor..HEAD" --` for recorded motivation. This scope excludes local uncommitted changes.
- **Working changes:** use `git diff HEAD --` for the combined staged and unstaged tracked changes. Also list non-ignored untracked files with `git ls-files --others --exclude-standard -z` and inspect them as additions; `git diff` does not include them. Preserve the NUL delimiters when reading paths containing spaces or newlines.
- **Remote PR analysis:** use the named PR's diff; unrelated local working changes are outside that source. If the user explicitly requests a different comparison base, compare the verified PR head against that base locally using the committed-branch rule; `gh pr diff` still uses the PR's recorded base.

If a required ref or merge-base cannot be resolved, report the missing ref or history instead of producing a diff against an empty or guessed base. Selection is read-only: do not fetch, change refs, or stage files just to obtain a diff.

## Review-loop anchor

Resolve the anchor to a commit ID once at loop start:

- For a PR checkout, use its merge-base with the resolved PR base.
- For a feature branch, use its merge-base with the resolved default or explicitly requested base.
- For uncommitted working changes, resolve `HEAD` to its commit ID.

Every loop pass uses `git diff "$review_anchor" --` against the current working tree, plus the same non-ignored untracked-file discovery above. This includes the original changes, staged and unstaged edits, and newly added files from fixes. Keep the anchor fixed even if a branch ref moves. Pass the anchor and this full local scope to each reviewer; do not substitute a committed-only diff or review only the latest fix.
