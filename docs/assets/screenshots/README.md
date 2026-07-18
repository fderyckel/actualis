# Screenshot standard

Screenshots support user understanding; they are not decoration and never substitute for accurate steps.

## When to capture

Capture a screenshot when it helps the reader recognize the correct surface, locate a non-obvious control, confirm a meaningful result, or recover from a visible error. Do not capture routine screens that the text already makes unambiguous.

No end-user UI exists in the current core-kernel workspace snapshot, so the initial screenshot status is `not_applicable`. Do not create mock screenshots and present them as product behavior.

## Capture procedure

1. Use a deterministic local or review environment on the documented version.
2. Seed fictional, stable data created for documentation. Never use production or personal data.
3. Use the default supported theme and viewport unless the page documents a device-specific workflow.
4. Capture only the relevant window or region. Remove browser chrome unless it supplies necessary context.
5. Preserve enough surrounding UI for orientation; avoid excessive cropping and decorative callouts.
6. Save the image under `docs/assets/screenshots/<page-slug>/`.
7. Add meaningful alt text and a caption in the page.
8. Record the capture in `<page-slug>/manifest.yaml`.

## File and manifest convention

Use lowercase kebab-case names that describe the user state, not a step number:

```text
docs/assets/screenshots/move-pallet/
  manifest.yaml
  pallet-details-before-move.png
  move-confirmation.png
```

Use this manifest shape:

```yaml
page: docs/user/core-kernel/move-pallet.md
captured_on: 2026-07-18
verified_against: <commit-or-release>
environment: deterministic-review
viewport: 1440x900
data_fixture: docs-core-kernel-v1
images:
  - file: pallet-details-before-move.png
    state: Pallet is released and located in STORAGE-A
    alt: Pallet details showing current location STORAGE-A and the Move action
    sensitive_data_reviewed: true
```

## Quality rules

- Prefer PNG for UI text and WebP only when its output remains crisp and the documentation renderer supports it.
- Keep text legible without requiring the reader to open the original file.
- Use natural interface focus or a restrained annotation only when the target remains hard to locate.
- Do not encode essential instructions only in color or in an annotation.
- Every image needs useful alt text; every instructional image also needs a caption.
- Re-capture when layout, visible copy, navigation, theme, example data, or the represented state changes.
- Delete an obsolete image only after confirming it is no longer referenced.

