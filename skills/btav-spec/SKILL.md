---
name: btav-spec
description: Develop a product spec, then a grounded tech spec for one feature or fix through conversation. Use only when explicitly invoked.
disable-model-invocation: true
---

# Specify a change

Invoked via `/btav-spec` in Claude, `$btav-spec` in Codex, or `/skill:btav-spec` in Pi, with a change request or existing spec directory. If neither is supplied, ask what change to specify.

Produce two connected documents: product behavior first, technical design second. Finish at the specification handoff.

## Ground the conversation

Read applicable repository instructions and relevant product documentation and code before asking questions answerable through exploration. Scope exploration to the change. Existing behavior is evidence, not automatically the desired behavior; distinguish inspected facts, proposals, assumptions, and unresolved decisions. Cite existing-code claims with verified file locations.

Use an explicit artifact location or the project's established spec convention. Otherwise use `docs/specs/<change>/product.md` and `tech.md` in the target repository, with a short descriptive change name. Inspect existing files before writing; refine a matching spec without overwriting an unrelated change. Do not create a Git repository or require existing code to discuss a new product.

## Product first

Read [Document outlines](references/documents.md). Develop purpose, scope, observable behaviors, invariants, failure cases, acceptance scenarios, and exclusions with the user. Give significant behaviors, invariants, and acceptance scenarios stable labels that survive revisions.

Ask about material choices the available context cannot settle. Offer concrete tradeoffs when useful. Do not fill gaps by inventing product requirements or treating silence as agreement. Scale the conversation and document detail to the change.

Present a reviewable product draft. Resolve material questions and obtain the user's confirmation of the product decisions before developing the tech spec. If the supplied product spec is already agreed and the request preserves its decisions, use that agreement without asking again. Record confirmed decisions separately from remaining questions.

## Technical design

Explain architecture, responsibilities, data flow, important interfaces, state ownership, intended code organization, implementation steps, and verification. Ground the design in inspected project patterns; mark proposed modules and interfaces as proposals rather than existing code. Include migrations, compatibility, concurrency, recovery, or rollout details when the change needs them.

Connect every significant product behavior and invariant to an implementation approach and acceptance verification. Specify enough code shape to locate responsibility without writing the implementation or prescribing speculative abstractions.

Bring constraints that force product tradeoffs back to the product discussion. Do not silently weaken an invariant to fit an easier design. Update both documents when decisions change and recheck their consistency. Mark a spec ready only when material decisions are resolved and verification is defined; an assumption affecting behavior remains a question until settled.

## Artifacts and handoff

Honor the harness's current mode and write permissions. In plan mode, draft document content in conversation when repository writes are prohibited. Never switch modes or bypass restrictions to persist drafts. When writes are allowed, save the documents at the selected location. Do not implement code or automatically start delivery.

Keep documents concise using the sibling [Prose checklist](../btav-unslop/references/prose-checklist.md). It is a prose pass, not a separate workflow. If unavailable, continue without it.

Finish with the artifact locations (or clearly labeled unsaved drafts), readiness, unresolved decisions, and the handoff: invoke `btav-deliver` with the ready spec directory. A ready draft in chat still needs to be saved before delivery can consume it. Do not imply that proposed tests have run.
