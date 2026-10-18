---
name: btav-unslop
description: Improve pasted prose while preserving tone. Keep it simple, restructure only when required, and scrub AI writing tropes. Use only when explicitly invoked.
disable-model-invocation: true
---

# Improve writing

Invoked explicitly via `/btav-unslop` in Claude, `$btav-unslop` in Codex, or `/skill:btav-unslop` in Pi. Do not auto-fire on adjacent phrasings.

Rewrite the user's text to be simpler and cleaner without changing voice.

## Input

The user pastes one or more passages of prose to improve. The text may be a paragraph, an email, a Slack message, a doc, a README — anything written in prose.

When another btav skill needs a prose pass, use only the [Prose checklist](references/prose-checklist.md), then return control to that skill. Its task and output format still apply; this skill's standalone rewrite workflow does not.

If no prose is supplied with the invocation, ask one short question — "Paste the text you want improved." — and stop. Do not invent text to edit, and do not grab a previous message in the conversation as the input.

## How to improve

1. Read the whole passage and identify its voice, tone, and meaning. If the register is unclear, preserve it.
2. Apply the [Prose checklist](references/prose-checklist.md). Use the detailed [trope reference](references/tropes.md) only when a specific pattern or worked example needs clarification.
3. Keep paragraph and sentence order unless the meaning is broken or the flow is incoherent. Do not introduce headings, bullet lists, or markdown formatting the original did not have. The output fence below is only a delivery wrapper.
4. Reread the finished rewrite against the checklist and these rules. Make only supported edits, and keep this self-audit out of the output.

## Output format

Output the rewritten text in exactly one plain-text fenced code block. Nothing before or after the block. This makes the copy button preserve spaces and line breaks exactly.

- Open the block with ` ```text ` and close it with ` ``` `. The fence is not part of the rewritten text.
- If the text itself contains a triple-backtick fence, use an outer fence with more backticks than any run in the text.
- Do not add a leading or trailing blank line inside the fence.
- For ordinary prose and email, do not hard-wrap lines. Keep each paragraph on one continuous line and put exactly one blank line between paragraphs.
- Preserve meaningful single line breaks in poetry, addresses, signatures, and list items.
- No preamble ("Here is the improved version:").
- No change log or summary of edits.
- If the input is already clean, leave its content unchanged and still use the copy-safe fence.

## Rules

- Let clarity and useful content determine the length. Cut padding without summarizing, expanding, or dropping facts to meet a word-count target.
- Preserve the original paragraph breaks unless restructuring is unavoidable.
- Preserve straight quotes (`"`, `'`); never substitute smart/curly quotes or unicode arrows (`→`, `⇒`).
- Preserve exact technical terms, proper nouns, names, and quoted material.
- Preserve the original's formatting conventions (markdown vs plain text, list style, code fences).
- Preserve useful existing em dashes; reduce repetition or forced dramatic pauses. Never introduce an em dash that wasn't in the original.

## What NOT to do

- Don't summarize, expand, or paraphrase beyond what's needed for clarity.
- Don't add commentary explaining your edits.
- Don't grade the writing or offer suggestions outside the rewrite.
- Don't refuse to edit because the prose is "fine" — output it unchanged instead.
- Don't change the meaning. If a sentence is ambiguous, preserve the ambiguity rather than guess.

## Style rules

- No emojis. No preamble. No "Generated with Claude" footer.
- No fractal summaries — don't restate the rewrite at the end.
- Plain language. The output should read like a human edited it, not like a different AI rewrote it.
