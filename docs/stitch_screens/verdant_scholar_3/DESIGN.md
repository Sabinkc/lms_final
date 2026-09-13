---
name: Verdant Scholar
colors:
  surface: '#eefdf6'
  surface-dim: '#ceddd7'
  surface-bright: '#eefdf6'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#e8f7f0'
  surface-container: '#e2f1eb'
  surface-container-high: '#ddece5'
  surface-container-highest: '#d7e6df'
  on-surface: '#111e1a'
  on-surface-variant: '#3f4943'
  inverse-surface: '#26332f'
  inverse-on-surface: '#e5f4ed'
  outline: '#6f7a73'
  outline-variant: '#bec9c1'
  surface-tint: '#056c4d'
  primary: '#00543b'
  on-primary: '#ffffff'
  primary-container: '#0b6e4f'
  on-primary-container: '#98edc6'
  inverse-primary: '#83d7b1'
  secondary: '#006c51'
  on-secondary: '#ffffff'
  secondary-container: '#92f2cd'
  on-secondary-container: '#007054'
  tertiary: '#354e45'
  on-tertiary: '#ffffff'
  tertiary-container: '#4d665d'
  on-tertiary-container: '#c7e3d7'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#9ff4cc'
  primary-fixed-dim: '#83d7b1'
  on-primary-fixed: '#002115'
  on-primary-fixed-variant: '#005139'
  secondary-fixed: '#95f5d0'
  secondary-fixed-dim: '#79d8b4'
  on-secondary-fixed: '#002116'
  on-secondary-fixed-variant: '#00513c'
  tertiary-fixed: '#cde9dd'
  tertiary-fixed-dim: '#b1cdc1'
  on-tertiary-fixed: '#062019'
  on-tertiary-fixed-variant: '#334c43'
  background: '#eefdf6'
  on-background: '#111e1a'
  surface-variant: '#d7e6df'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 30px
    fontWeight: '600'
    lineHeight: 38px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1rem
  margin-tablet: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.25rem
  space-xl: 1.5rem
---

## Brand & Style
The design system reflects an academic administration environment that feels disciplined, tranquil, and clear. Built for educational leaders and instructors managing enterprise learning operations on mobile devices, it rejects the cluttered, bureaucratic tone of traditional institutional software in favor of modern, card-driven clarity.

The visual style blends refined modern minimalism with subtle tactile surfaces:
- **Calm Authority**: Grounded by deep forest emerald tones that communicate prestige, stability, and structure.
- **Card-Centric Modularity**: Operations, metrics, grading queues, and alerts are encapsulated into standalone cards, giving dense data room to breathe.
- **Precision Detailing**: Soft mint and emerald washes paired with crisp, structural borders ensure accessibility in high-light classroom or transit conditions.

## Colors
The palette balances authoritative deep foliage tones with airy, high-legibility neutrals:

- **Primary (`#0b6e4f`)**: Deep Forest Emerald. Anchor for top-level navigation headers, primary actions, progress bars, and critical indicators.
- **Secondary (`#2e9373`)**: Mint Leaf Emerald. Used for interactive hover/active states, secondary calls-to-action, active filters, and sub-metric trends.
- **Tertiary (`#d4f0e4`)**: Soft Mint Wash. Surfaces behind secondary badges, active status pills, alert highlights, and selected card backdrops.
- **Neutral (`#1b2824`)**: Deep Pine Neutral. Used for high-contrast typography, high-priority icons, and structural divider references.
- **Canvas & Surface System**:
  - App Background: Light muted mint-tinted neutral (`#f5f9f7`).
  - Card & Modal Surfaces: Pure `#ffffff` to retain separation against the background.
  - Border System: Crisp structural borders (`#e1eae5`) providing clean delineations without visual heaviness.

## Typography
Plus Jakarta Sans serves as the single typographic voice across headlines, body copy, and UI metadata. Its open apertures and modern geometric curves provide approachability, while deliberate letterforms guarantee legibility in compact mobile viewport conditions.

- Display roles set tone for KPI dashboards, cumulative grade counts, and onboarding summaries.
- Headlines and Titles prioritize clarity, utilizing 600 weight to stand distinct from soft card backgrounds.
- Body levels maintain a comfortable vertical cadence, calibrated to preserve readability when displaying multi-line course descriptions or administrative notes.
- Labels leverage medium and semibold weights for uppercase operational micro-indicators and status badges.

## Layout & Spacing
The layout follows a disciplined 4-column fluid mobile grid system transitioning to 8 columns on tablet viewports.

- **Mobile Viewport (< 600px)**: 4 columns, 16px screen margin (`margin`), and 12px horizontal gutters (`gutter-mobile`). Vertical card stack spacing enforces a strict 16px rhythm (`space-md`).
- **Tablet & Large Foldables (600px - 1024px)**: 8 columns, 24px screen margin (`margin-tablet`), 16px gutters (`gutter`). Allows side-by-side metric dashboards and master-detail splits.
- **Internal Card Padding**: Standard cards utilize 16px (`space-md`) internal padding, while compact summary cards scale down to 12px. Section groupings utilize 24px (`space-xl`) vertical separation.

## Elevation & Depth
Depth is created through crisp structural boundaries and soft tonal stacking rather than heavy dropshadows:

- **Level 0 (App Canvas)**: Ground layer rendered in `#f5f9f7`.
- **Level 1 (Default Cards & Tiles)**: Pure `#ffffff` background with a crisp, 1px border (`#e1eae5`) and a diffused, low-opacity emerald tint shadow (`0 2px 8px -2px rgba(11, 110, 79, 0.05)`).
- **Level 2 (Interactive Elements & Floating Modals)**: Lifted surface utilizing `#ffffff`, a 1px border (`#d1e1d8`), and an ambient shadow (`0 8px 24px -4px rgba(11, 110, 79, 0.10)`).
- **Level 3 (Sticky Navigation Bars & Bottom Sheets)**: Retains `#ffffff` with a subtle top hairline border (`#e1eae5`) and an ambient elevation spread (`0 -4px 16px rgba(11, 110, 79, 0.06)`).

## Shapes
Geometry is smooth and structural, prioritizing generous corner curvetures to maintain a friendly, approachable mobile interface:

- **Cards & Modal Sheets**: Styled with `rounded-2xl` (1rem / 16px) curvature to soften dense academic workflows.
- **Buttons, Text Inputs, and Dropdowns**: Standardized on `rounded-xl` (0.75rem / 12px) to ensure tactile target identification.
- **Chips, Pills, and Avatars**: Fully rounded (`rounded-full`) for high-contrast categorical differentiation.

## Components

### Buttons
- **Primary**: Solid Deep Forest Emerald (`#0b6e4f`) background, white text (`#ffffff`), `rounded-xl`, height 48px, horizontal padding `space-lg`. Active state shifts to `#08543c`.
- **Secondary**: Soft Mint Wash (`#d4f0e4`) background with `#0b6e4f` text and no border, height 48px.
- **Outlined**: Transparent background, 1.5px border in `#0b6e4f`, text in `#0b6e4f`.
- **Destructive**: Soft crimson background (`#fdeeed`) with crimson text (`#b42318`).

### Cards & Metrics
- Standard cards feature `#ffffff` background, `rounded-2xl` corners, 1px solid `#e1eae5` border, and 16px padding.
- Metric cards incorporate an accent header icon container (36x36px, `rounded-xl`, `#d4f0e4` background, `#0b6e4f` glyph).

### Input Fields
- Height 48px, `rounded-xl`, 1px solid `#d1e1d8`, white background.
- Focus state expands border to 2px solid `#0b6e4f` with a soft mint outer glow ring (`rgba(11, 110, 79, 0.12)`). Placeholder in neutral-muted `#687e74`.

### Chips & Badges
- Status badges: Height 26px, `rounded-full`, horizontal padding 10px. Active/Enrolled uses `#d4f0e4` background with `#0b6e4f` text. Pending uses soft amber (`#fef3f2` / `#b54708`).
- Filter chips: Height 32px, `rounded-xl`, border 1px solid `#e1eae5`, interactive state shifts to `#0b6e4f` fill with white text.

### Lists & Cohort Rows
- Enclosed inside `rounded-2xl` parent card containers. Individual rows are separated by 1px divider lines in `#edf3f0`.
- Left-aligned user or course avatar (40x40px, `rounded-xl`), centered 2-line title and subtitle, right-aligned meta badge or chevron icon.

### Checkboxes & Radio Controls
- Checkboxes: 20x20px, `rounded-md` (6px), 1.5px border `#9ab3a6`. Checked state: `#0b6e4f` fill with white checkmark.
- Radio buttons: 20x20px, circular, with an inner `#0b6e4f` filled circle of 10px diameter on selection.

### Administrative Specific Components
- **Course Progress Ring**: 48px radial SVG track in `#d4f0e4` with `#0b6e4f` stroke completion indicator.
- **Grading Quick-Bar**: Fixed bottom accessory view with quick-action score presets styled in soft mint tiles.