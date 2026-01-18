# FlwKit iOS SDK — UI Rendering & Template System (V1)

## Overview
FlwKit is a **remote UI composition + flow engine** for mobile onboarding.
The iOS SDK fetches a **published flow JSON** from the backend and renders it **natively with SwiftUI**, using a **block-based renderer** and a **token-based theme system**.

The goal is to remain **powerful but safe** by separating:

1. **Structure**: which blocks appear and in what order  
2. **Layout primitives**: strict layout rules (VStack/ScrollView, padding, alignment)  
3. **Style tokens**: colors/typography/radius/buttons as named tokens  
4. **Templates**: prebuilt themes + optional starter flows

---

## How the SDK Builds UI

### Block-based rendering (not freeform)
The SDK does not support arbitrary Figma-like layouts in V1.
Instead, each screen is composed of **blocks** rendered in a vertical stack.

This provides:
- deterministic rendering across devices
- minimal edge cases
- safe remote updates without breaking UI

---

## Screen Model (V1)

A screen contains:
- `id`
- `type` (usually `standard`)
- optional `themeId`
- an ordered list of `blocks`
- transitions (handled by Flow runtime)

Example screen JSON:
```json
{
  "id": "screen_goal",
  "type": "standard",
  "themeId": "theme_mint_dark",
  "blocks": [
    { "type": "header", "title": "What is your goal?", "subtitle": "Next 6 months" },
    { "type": "choice", "key": "goal", "style": "cards", "options": [
      { "label": "Be stronger", "value": "strength" },
      { "label": "Build muscles", "value": "muscles" }
    ]},
    { "type": "cta", "primary": { "label": "Next", "action": "next" } }
  ]
}
```

---

## Supported Blocks (recommended V1 set)

Start with ~8–12 blocks max:

- `header` (title/subtitle)
- `media` (image URL)
- `choice` (single/multi choice)
- `text_input`
- `slider`
- `benefits_list`
- `testimonial` (simple)
- `cta` (primary/secondary actions)
- `spacer` (token-based)
- `footer` (optional)

Add new blocks later via `schemaVersion` bump.

---

## Rendering Rules (strict layout primitives)

To ensure reliable native layout:

- always render inside a `ScrollView`
- single vertical column (`VStack`)
- consistent padding and max width
- use `safeAreaInset` for bottom CTA blocks
- token-based spacing (`xs/s/m/l/xl`) rather than raw values

Not supported in V1:
- arbitrary positioning
- per-element custom CSS-like styling
- freeform drag layouts

---

## Theme / Style Tokens

Templates are powered by **themes**, not custom styling per block.

A theme is a set of tokens:
- colors (background/surface/primary/text)
- typography tokens (title/body/caption)
- radius tokens (sm/md/lg)
- button style tokens (filled/outline)

Example theme:
```json
{
  "id": "theme_mint_dark",
  "tokens": {
    "background": "#0B1220",
    "surface": "#111827",
    "primary": "#3DDC97",
    "secondary": "#2DD4BF",
    "textPrimary": "#E5E7EB",
    "textSecondary": "#9CA3AF",
    "radius": "lg",
    "buttonStyle": "filled",
    "font": "system"
  }
}
```

### Theme resolution order
1. Screen `themeId`
2. Flow default theme
3. SDK fallback theme

---

## SDK Renderer Architecture

Recommended: **Block Registry**

- a `BlockRenderer` routes block JSON → SwiftUI view
- each block maps to a SwiftUI view:
  - `HeaderBlockView`
  - `ChoiceBlockView`
  - `CTABlockView`
  - etc.

Unknown block type:
- render a small “Unsupported block” placeholder
- emit `render_error` analytics event

---

## Flow Runtime + State

The SDK runtime manages:
- current screen id
- answers dictionary
- attributes (passed in from host app)
- transitions (conditional navigation)

Persistence:
- store progress in `UserDefaults` keyed by flowKey + userId
- restore if app is killed/backgrounded

---

## Analytics Events (V1)

Emit:
- `flow_start`
- `screen_view`
- `answer`
- `flow_complete`
- `flow_exit`
- `render_error`

Events should be batched and retried via a simple queue.

---

## Templates (SDK role)

Templates are primarily a dashboard concern (themes + starter flows).
In the SDK they appear as:
- `themeId` applied to screens/flows
- consistent token mapping

The SDK does not need template metadata—only:
- themes
- blocks
- tokens

---

## V1 success criteria
- SDK integration in < 10 minutes
- published flows render consistently
- cached fallback works offline
- templates look distinct while staying within constraints
