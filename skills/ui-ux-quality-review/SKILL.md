---
name: ui-ux-quality-review
description: Review an implemented or specified interface for accessibility, interaction feedback, responsive behavior, usability, and design-system consistency. Use for UI quality reviews, accessibility checks, pre-delivery verification, or investigation of experience defects. Do not use merely because frontend files are touched or when the task is primarily visual ideation.
---

# UI/UX quality review

Assess observable experience risks in context and return prioritized, verifiable findings. Review does not authorize implementation unless the user asks for fixes.

## Review strategy

1. Identify the critical user journeys, target devices, input methods, user states, and repository design-system rules.
2. Inspect the implementation and, when available, exercise the rendered interface using the safest suitable browser or computer-use capability.
3. Review the highest-risk journey first. Read [references/quality-checks.md](references/quality-checks.md) for the detailed lenses; apply only those relevant to the surface.
4. Verify claims with code evidence, rendered behavior, or an authoritative standard. Distinguish confirmed defects from recommendations.
5. Report findings by user impact and include a concrete expected outcome or reproduction condition.

## Priorities

- **Critical:** blocks a core task or excludes users with no viable workaround.
- **High:** causes likely errors, inaccessible interaction, data loss risk, or failure on an important viewport/input.
- **Medium:** creates substantial friction, ambiguity, inconsistency, or avoidable performance cost.
- **Low:** polish improvement with limited functional impact.

## Boundaries

- Do not enforce arbitrary aesthetic preferences as usability requirements.
- Do not claim standards compliance from static inspection alone when behavior must be tested.
- Preserve the product's intentional design language unless it causes a concrete experience problem.
- Scope the review to the requested surface and its meaningful regression paths.

## Handoff

Return: journeys inspected, environments or viewports checked, prioritized findings with evidence, passed high-risk checks, unverified areas, and recommended verification after fixes.
