---
name: frontend-design
description: Create or materially redesign user interfaces with an intentional visual direction grounded in the product, repository, and existing design system. Use for new pages, composed views, major component work, landing pages, or explicit visual polish. Do not use for non-visual frontend logic or tiny styling corrections with an obvious local pattern.
---

# Frontend design

Build a functional interface whose visual choices are specific to the product rather than generic defaults.

## Establish direction

1. Inspect the actual framework, component library, tokens, brand assets, nearby screens, content, and interaction conventions. Repository guidance and supplied designs outrank this skill.
2. Identify the audience, context of use, page or component job, information hierarchy, and required states.
3. For substantial work, state a compact direction before coding:
   - visual premise and one memorable signature;
   - color roles derived from existing tokens or a justified palette;
   - typography roles and hierarchy;
   - layout rhythm, density, and responsive behavior;
   - interaction and motion intent.
4. Review the direction against the brief. Replace choices that could be reused unchanged for an unrelated product.

## Implement with restraint

- Reuse the repository's components and tokens before creating new primitives.
- Use real content when available; placeholder copy must preserve realistic length and hierarchy.
- Make structure communicate meaning. Do not add decorative cards, gradients, labels, or numbered sections without a content reason.
- Define responsive behavior and all relevant loading, empty, error, success, disabled, focus, hover, and active states.
- Use motion only when it explains state, hierarchy, or continuity; respect reduced-motion preferences.
- Preserve semantics, keyboard access, performance, and existing product behavior.
- Keep visual changes within the authorized scope. Do not redesign adjacent surfaces merely for consistency.

## Verify

Inspect the rendered result at representative narrow and wide sizes. Check hierarchy, overflow, spacing rhythm, content realism, interaction states, and obvious regressions. Use `ui-ux-quality-review` for an explicit accessibility or interaction-quality audit when that review is requested or materially warranted.
