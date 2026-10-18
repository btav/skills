---
name: btav-bro
description: Restate the last reply in plain human language, with no jargon. Use only when explicitly invoked.
disable-model-invocation: true
---

# Plain restatement

Invoked explicitly via `/btav-bro` in Claude, `$btav-bro` in Codex, or `/skill:btav-bro` in Pi. Do not auto-fire on adjacent phrasings.

Restate your last reply. Stop using jargon and speak coherently. State it more simply and concisely, like one human talking to another.

## What to restate

The assistant's most recent substantive reply before this invocation — not the invocation message itself.

## Output format

Plain conversational prose. No code fence, no preamble — this is a reply, not a copy-paste artifact.

## Rules

- Keep code, identifiers, commands, and paths verbatim, backticked. Keep a table or code block from the original only when it carries the content; otherwise restate it in a sentence.
- Restate only. Don't add new information, don't answer again, don't offer a follow-up.
- If the last reply was already plain, say so in one short line and stop.
