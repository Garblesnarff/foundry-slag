# Design System

This app uses the Foundry shared design system. See `~/Projects/foundry/_shared/DESIGN_SYSTEM.md` for the complete specification.

## Foundry Slag Customizations

### Color Palette

**Primary**
- Black: `#141210` (charcoal forge black)
- Gray: `#3A3935` (dark steel gray)
- Light: `#F5F5F5` (off-white)

**Accent**
- Amber: `#E8A849` (molten slag amber)

### Typography

**Font Stack**
- Body: DM Sans
- Code: JetBrains Mono
- Titles: Playfair Display (use sparingly)

**Scale**
- h1: 2.5rem (only for app title)
- h2: 1.875rem (section headers)
- h3: 1.25rem (subsection headers)
- Body: 1rem
- Small: 0.875rem

### Language & Tone

Use metallurgy and forge language instead of generic tech terminology:

- Do: "Slag it", "Slag away", "Slagging..."
- Don't: "Process", "Remove", "Extract"

- Do: "The slag burns away, the gold remains"
- Don't: "Background removed successfully"

- Do: "Forge", "Smelt", "Refine", "Polish"
- Don't: "Tool", "App", "Feature"

### Component Patterns

See `../frontend/src/styles/foundry.css` for component utilities.

Key patterns:
- `.btn-primary` — Amber action buttons
- `.btn-secondary` — Gray secondary buttons
- `.dropzone` — Drag-and-drop area with dashed border
- `.card` — Gray background container
- `.slider` — Custom range input with amber thumb

### Imagery

No placeholder imagery. All visual elements should support the dark forge aesthetic with amber accents.

### Responsiveness

Mobile-first approach. Test at:
- 375px (mobile)
- 768px (tablet)
- 1440px (desktop)
- 2560px (ultrawide)

Focus on desktop (1440px) for macOS M1-M4 implementation.
