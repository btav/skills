# Paired specifications

Use these outlines as a starting point. Omit irrelevant detail and expand sections only when needed to make a material decision explicit. Preserve stable labels when revising existing documents.

## Product spec

- **Status and context:** draft or ready; the change, intended users, purpose, and product decisions the user has confirmed.
- **Scope:** included behavior and explicit exclusions.
- **Behaviors:** observable outcomes, with stable labels such as `B1`.
- **Invariants:** properties that must hold under the relevant conditions, labeled such as `I1`. State the boundary and conditions rather than making vague promises.
- **Acceptance scenarios:** concrete inputs/actions and expected outcomes, labeled such as `A1`, referencing the behaviors or invariants they establish. Include relevant failure and boundary cases.
- **Open decisions:** questions and assumptions requiring agreement; say none when resolved.

Keep implementation mechanisms in the tech spec. For example, the product invariant is that retrying checkout cannot create a duplicate order; its storage and idempotency mechanism belongs in the technical design.

## Tech spec

- **Status and basis:** draft or ready; link the product spec, identify the repository revision inspected when available, and distinguish existing facts from proposals.
- **Architecture and code shape:** components, ownership, relevant modules, interfaces, state and data flow, and the project patterns being reused.
- **Design decisions:** the selected approach and material tradeoffs; relevant errors, compatibility, migrations, or operational concerns.
- **Implementation steps:** small, verifiable units in dependency order.
- **Requirement mapping:** product label → implementation responsibility/mechanism → acceptance scenario and verification method. Cover each significant behavior and invariant; avoid unsupported claims that a narrow test proves a universal property.
- **Verification:** relevant existing commands and proposed additions or direct reproductions. Distinguish known runnable checks from checks still to be implemented, and identify environment needs or limits.
- **Open decisions:** unresolved technical choices. Surface any requiring a product revision.

Ready means the documents agree, product decisions are confirmed, material design choices are settled, and acceptance has observable criteria. It does not mean implementation or verification has occurred. Invoking delivery on ready specs is the handoff; another approval ceremony is unnecessary.
