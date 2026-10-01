---
name: unslop
description: Edit README files, guides, API documentation, and prose comments when drafting, revising, or reviewing changed repository text for delivery. Remove filler and promotional language while preserving technical claims and security qualifications.
user-invocable: false
---

# Unslop

Use the requested text or changed prose, its intended audience, and the relevant
implementation or documentation as inputs. Edit the affected files in place and
report material ambiguities in chat. For a prose-only revision, preserve meaning
and evidentiary strength. When behavior changes, verify new claims against the
implementation and completed checks before stating them as facts.

Read only the code or documentation needed to resolve a claim. Do not expand a
small prose edit into a repository-wide rewrite. Leave executable examples alone
unless their behavior is part of the requested change.

## Language

- Start with the subject. Delete scene-setting, self-reference, pleasantries, and recaps.
- Replace promotional adjectives with the property that can be observed or tested.
- Replace metaphorical verbs with the concrete operation.
- Remove filler, forced triads, empty gerund endings, hedge stacks, rhetorical questions, and repeated conclusions.
- Prefer a period to chains of em dashes or colon splices.
- Preserve code, commands, paths, identifiers, dates, numbers, protocol terms, standard titles, and normative strength exactly.

Replace words such as `robust`, `seamless`, or `comprehensive` when they substitute
for a concrete property. Preserve quotations, established terms, and words that
carry technical meaning.

Do not write “serves as”, “not just X but Y”, “it is important to note”, “at its core”, “in conclusion”, “overall”, “simply”, or “of course”. State the claim directly.

## Formatting

- Use headings, lists, and tables only when they improve retrieval.
- Do not decorate prose with emoji or repeated bold labels.
- Keep list items grammatically parallel.
- Do not add a preamble before the result or a summary that repeats it.

## Review

Compare the revised text with its source and the relevant behavior. Check that
conditions, units, error behavior, examples, and qualified security claims still
mean the same thing. Remove remaining filler and repetition. Text searches can
locate phrases to inspect; they do not establish semantic equivalence.
