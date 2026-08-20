---
name: btav-why
description: Reconstruct why code is the way it is from git history, PRs, and issues. Every claim cited, with recorded rationale kept strictly separate from inference. Use only when explicitly invoked.
disable-model-invocation: true
---

# Why (design archaeology)

Invoked explicitly via `/btav-why` in Claude, `$btav-why` in Codex, or `/skill:btav-why` in Pi. Do not auto-fire on adjacent phrasings.

Dig up the recorded reasons. Cite everything. Keep known separate from guessed. Stop.

Use `btav-investigate` when something is *broken*; use this when something is *surprising* — the code works, but you want to know why it's shaped this way.

## Input

The user names a target — one or more of:

- A file, directory, function, or class ("why does `auth/` have two adapters?")
- A pattern or convention ("why do we wrap every handler in `withRetry`?")
- A dependency or config value ("why are we pinning `node@18`?")
- A past decision ("why did we move off Redis?")

If the target is ambiguous or missing, ask one short clarifying question before digging.

## Where to dig

Work through these sources; skip a source when it can't apply and say so.

1. **File history** — `git log --follow --oneline -- <path>`, then `git show <sha>` on the commits that plausibly introduced or reshaped the target.
2. **Symbol history** — `git log -S '<symbol>'` when the target is a name rather than a file; `git blame` to pin the introducing commit for specific lines.
3. **PRs and issues** — `gh pr list --state all --search "<sha or keyword>"`, `gh pr view <N> --comments` for PR discussion, `gh search issues` / `gh search prs` for design threads. If `gh` is unavailable or there's no remote, work from commit messages alone and say so in the output.
4. **In-repo records** — README, CHANGELOG, ADRs, design docs, and code comments near the target.

## Epistemics

- **Every claim cites its source** — a commit sha, PR/issue number, or `file:line`. No citation, no claim.
- **"Appears to" over "because."** Assert a motive only when someone wrote it down; otherwise it's inference and goes in `Inferred`.
- **Null results are findings.** "No recorded rationale" is a legitimate, useful answer — say it plainly instead of inventing a story.
- **Current code proves *what*, not *why*.** The shape of the code is evidence of behavior; only history and discussion are evidence of intent.

## Output format

````
## Question
<one sentence restating what's being asked>

## Timeline
- `abc123` (2023-04-12, PR #45) — <what changed, and the stated reason if any>
- `def456` (2023-06-02) — <what changed>
- …

## Known rationale
- <claim> — `abc123` / PR #45: "<short quote or tight paraphrase of the recorded reason>"
- …, or "No recorded rationale found."

## Inferred
- <plausible unrecorded explanation, phrased as inference: "appears to…", "likely…"> (`sha`, PR/issue, or `file:line`)
- …, or "none"

## Open questions
- <what would settle it: a person to ask, a thread to find, a repo you can't see>
````

## Rules

- **Timeline is curated, not complete.** Only the commits/PRs that shaped the answer — usually 3–7 entries, oldest first.
- **Quote short, paraphrase long.** A one-line commit message gets quoted; a paragraph of PR discussion gets a tight paraphrase with the citation.
- **Don't trawl more than ~15 commits or ~5 PRs** without signal. If the trail is cold, report what you searched and where a human might look next.
- **Squash-merge caveat.** When history is squashed, the PR is usually the richer source — check it before concluding there's no rationale.
- **Wrap every code reference in backticks** — paths, identifiers, shas, flags.

## What NOT to do

- Don't judge the decision. Whether it was *right* is a review question, not an archaeology question.
- Don't propose changes or fixes. The output is history, not a recommendation.
- Don't run the code, build, or tests. Reading history and files only.
- Don't present inference as fact — the `Known rationale` / `Inferred` boundary is the whole point of this skill.
- Don't pad the timeline with mechanical commits (formatting, dep bumps) unless one *is* the answer.

## Style rules

- **No emojis. No "Generated with Claude" footers.**
- Citations carry the report; prose just connects them.
- Print the report and stop.

## Worked example

Input: "Why does `src/db/client.ts` hand-roll connection retries instead of using the pool's built-in retry?"

Output:

````
## Question
Why does `src/db/client.ts` implement its own retry loop rather than using the pg pool's built-in retry support.

## Timeline
- `9b2d1e4` (2022-11-03, PR #112) — introduced `withRetry()` wrapper around `pool.query`; PR titled "work around pg-pool 3.4 retry bug".
- `c07aa91` (2023-01-19) — raised max retries 3 to 5, message: "prod incident 2023-01-18, cold-start timeouts".
- `f31c880` (2023-08-30, PR #201) — pg-pool upgraded to 3.6; retry wrapper left in place, no discussion of removing it.

## Known rationale
- The custom loop worked around a pg-pool 3.4 bug that dropped queued queries on retry — PR #112: "pool.retry loses queued queries under load; wrapping until upstream fix lands".
- Retry count was tuned after a production incident — `c07aa91`: "prod incident 2023-01-18, cold-start timeouts".

## Inferred
- The wrapper appears vestigial after the 3.6 upgrade because the recorded rationale targets the 3.4 bug and no later commit mentions the workaround (`PR #112`, `PR #201`).

## Open questions
- Whether anything now depends on the wrapper's jitter behavior — the author of PR #112 would know.
````
