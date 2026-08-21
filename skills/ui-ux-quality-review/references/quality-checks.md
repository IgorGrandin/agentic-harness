# UI/UX quality checks

Apply only the lenses relevant to the reviewed journey.

## Access and semantics

- semantic structure and accessible names match visible purpose;
- keyboard order, focus visibility, focus restoration, and escape behavior work;
- status, validation, and dynamic changes are conveyed without relying only on color or motion;
- contrast, zoom, text resizing, and reduced-motion behavior preserve use;
- touch targets and pointer alternatives suit the target device.

## Journey and feedback

- primary action and next step are clear;
- loading, empty, error, success, disabled, offline, timeout, and partial states are handled when applicable;
- destructive or irreversible actions communicate impact and recovery;
- forms retain input appropriately, associate errors with fields, and avoid placeholder-only labels;
- retries, repeated submissions, and interrupted operations do not create duplicate or ambiguous outcomes.

## Responsive and content resilience

- representative narrow and wide layouts avoid clipping, overlap, unreadable density, and unintended horizontal scrolling;
- long labels, localization, dynamic counts, missing media, and realistic data do not break structure;
- navigation and overlays remain usable with virtual keyboards, safe areas, and changed orientation when relevant.

## Consistency and performance

- components, tokens, terminology, and interaction patterns follow the repository design system;
- interaction latency has timely feedback and avoids layout instability;
- images, animation, and rendering cost are proportional to user value;
- analytics or experiments do not compromise accessibility or core task completion.

For standards-specific claims, cite the applicable authoritative requirement and verify the observable behavior it governs.
