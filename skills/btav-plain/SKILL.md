---
name: btav-plain
description: Check a document against the four ISO 24495-1 plain language principles. Reports findings anchored to the text; rewrites only on request. Use only when explicitly invoked.
disable-model-invocation: true
---

# Plain language (ISO 24495-1)

Invoked explicitly via `/btav-plain` in Claude, `$btav-plain` in Codex, or `/skill:btav-plain` in Pi. Do not auto-fire on adjacent phrasings.

Name the reader. Check the four principles. Quote the text, name the fix. Report and stop.

## Input

A file path, a pasted document, or a diff of prose. READMEs, docs, specs, PR bodies, emails, release notes — anything a reader has to get something out of.

If no document is supplied with the invocation, ask one short question — "Paste the document or give me a path." — and stop. Do not invent text to audit, and do not grab a previous message in the conversation as the input.

Audit is the default: report findings, change nothing. Rewrite only on `--rewrite` or an explicit request.

## The four principles

ISO 24495-1:2023 defines plain language as writing the intended reader can find, understand, and use. It prescribes no readability formula and no word-count target. The checklist below is the working interpretation. Each principle asks a question about the reader, not about the prose on its own.

### 1. Relevant — the reader gets what they need

- Who is this for? If the document doesn't name its reader, infer one from context and label the inference.
- What did they come here to do? Every section either serves that or is padding.
- Is the level of detail pitched at the reader, or at what the author found interesting?
- What is missing, so the reader has to go elsewhere to get it?
- What is present that they never needed?

### 2. Findable — the reader can easily find it

- Does the order match the reader's task, or the author's discovery sequence?
- Does each heading say what is actually in its section? A heading that could sit above any section is a label, not a heading.
- Are parallel items a list, and is tabular data a table?
- Can a reader who wants one fact reach it without reading the whole document?

### 3. Understandable — the reader can easily understand it

- Familiar words over formal ones. Use the word the reader already uses.
- Define project and domain terms on first use. Don't explain language or framework basics — see `## Relationship to btav-unslop`.
- One name per thing. Pick the term and repeat it; synonym cycling makes the reader stop to check whether two names mean two things.
- Name the actor. Active voice unless the actor is genuinely unknown or irrelevant.
- Main point first, in the sentence, the paragraph, and the document.
- Every sentence parses on the first read. That is the target, not short sentences — see `## Relationship to btav-unslop`.

### 4. Usable — the reader can act on it

- Can the reader do the thing afterward? Name the gap where they can't.
- State the **assumed reader** at the top of every audit. The other three principles are judged against it, so it has to be visible and arguable.
- The standard settles this principle by testing with real readers, which you can't do. Flag the findings only a reader test decides, and say that's what they need. Never claim to have tested with readers.

## How to audit

1. Read the whole document before judging any part of it.
2. Identify the reader. Use the audience the document names; if it names none, infer one from where the document lives and say you inferred it.
3. One pass per principle, in order.
4. Rank findings by reader impact, not by principle order. A missing prerequisite under Relevant outranks a passive verb under Understandable.
5. Anchor each finding to quoted text or, for missing content, to the section or location where it belongs.

## Output format

````
## Reader
<one sentence: who this is for and what they came to do. Say so if you inferred it.>

## Findings

### 1. <what the reader hits> (principle: relevant | findable | understandable | usable)
> <the quoted text, or the location where missing content belongs>
<the fix in one or two sentences. Show the replacement wording when the fix is sentence-level.>

### 2. <...>

## Reader test only
<findings a real reader test would settle. Omit this section when there are none.>
````

## Rewrite mode

Off by default. Fires on `--rewrite` or an explicit request.

Output the rewritten document in exactly one plain-text fenced code block. Use a fence longer than any backtick fence inside the document. Nothing before or after the block. Same contract as `btav-unslop` `## Output format` — the fence is a copy-safe wrapper, not part of the text.

Rewrite mode applies Relevant, Understandable, and Usable. It does not restructure the document, add headings, or invent facts to fill gaps; preserve gaps that require information the user did not supply.

## Relationship to btav-unslop

`btav-unslop` owns the catalog of AI writing tells. This skill owns the reader-centered checklist. They overlap, so the boundaries are explicit.

Load the catalog by reading `btav-unslop/SKILL.md` from the same skills directory this skill was loaded from, then apply its `## AI writing tropes to avoid` section. If the skill isn't available, skip that pass — never block the audit on it.

- **Don't restate what the catalog already covers.** Active voice is `#### Passive Voice Padding`. Filler and hedge stacks are `#### Filler Phrases and Overhedging`. Weak-verb adverbs are `#### Adverbs Propping Up Weak Verbs`. Cite the trope by name instead of writing a second version of the rule.
- **Sentence length.** The target is *parses on the first read*, not *short*. Never split a sentence that already parses, and never emit three short sentences in a row. `#### Dense Sentences` and `#### Short Punchy Fragments` beat any instinct to shorten.
- **Headings and lists.** Audit mode may recommend them for a document the reader navigates. Rewrite mode must not introduce headings, bullets, or markdown the original didn't have — `btav-unslop` rule 6 ("Don't AI-ify") wins.
- **Defining terms.** Define terms the stated reader will not know; don't explain concepts they already understand.

## Rules

- Anchor every finding to quoted text or, for missing content, to a named location in the document.
- Judge against the stated reader. Change the reader and the findings change.
- Preserve exact technical terms, proper nouns, and quoted material in any rewrite.
- Preserve straight quotes (`"`, `'`); never substitute smart/curly quotes or unicode arrows (`→`, `⇒`).
- A document that passes still uses `## Reader`, followed by `## Findings` with `No findings.`

## What NOT to do

- **Don't quote or paraphrase ISO 24495-1 clause text.** The standard is paywalled. Cite a principle by name, never by clause number.
- Don't rewrite in audit mode. Show the replacement sentence inside a finding, not a rewritten document.
- Don't invent a reader the document doesn't imply. Infer one and label it as inferred.
- Don't score, grade, or emit a readability index. The standard prescribes no formula.
- Don't claim you tested with readers.
- Don't raise a finding you can't name a fix for.

## Style rules

- **No emojis. No "Generated with Claude" footers.**
- Print the requested audit or rewrite and stop.
