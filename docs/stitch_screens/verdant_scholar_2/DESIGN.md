---
name: Verdant Scholar
colors:
  surface: '#f8faf8'
  surface-dim: '#d8dad9'
  surface-bright: '#f8faf8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f2'
  surface-container: '#eceeec'
  surface-container-high: '#e6e9e7'
  surface-container-highest: '#e1e3e1'
  on-surface: '#191c1b'
  on-surface-variant: '#3f4943'
  inverse-surface: '#2e3130'
  inverse-on-surface: '#eff1ef'
  outline: '#6f7a73'
  outline-variant: '#bec9c1'
  surface-tint: '#056c4d'
  primary: '#00543b'
  on-primary: '#ffffff'
  primary-container: '#0b6e4f'
  on-primary-container: '#98edc6'
  inverse-primary: '#83d7b1'
  secondary: '#735c00'
  on-secondary: '#ffffff'
  secondary-container: '#fed65b'
  on-secondary-container: '#745c00'
  tertiary: '#275048'
  on-tertiary: '#ffffff'
  tertiary-container: '#3f685f'
  on-tertiary-container: '#b9e5da'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#9ff4cc'
  primary-fixed-dim: '#83d7b1'
  on-primary-fixed: '#002115'
  on-primary-fixed-variant: '#005139'
  secondary-fixed: '#ffe088'
  secondary-fixed-dim: '#e9c349'
  on-secondary-fixed: '#241a00'
  on-secondary-fixed-variant: '#574500'
  tertiary-fixed: '#bfece1'
  tertiary-fixed-dim: '#a4cfc5'
  on-tertiary-fixed: '#00201b'
  on-tertiary-fixed-variant: '#254e46'
  background: '#f8faf8'
  on-background: '#191c1b'
  surface-variant: '#e1e3e1'
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  title-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.005em
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  title-sm:
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
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.03em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 12px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.5rem
  margin: 1rem
  margin-sm: 0.75rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

The design system embodies the "Verdant Scholar" ethos: an academic, calming, and focused atmosphere engineered specifically for modern educators navigating high-density daily schedules. Designed for a mobile-first teacher portal, the interface projects composed authority, clarity, and renewal, eliminating cognitive fatigue during hectic school transitions.

The design movement blends **Modern Academic Minimalism** with tactile, organic surfaces. It avoids stark corporate rigidity in favor of soft natural tones, quiet depth, and purposeful negative space. Interactions are smooth and grounding, instilling confidence and peace of mind as teachers manage lesson plans, room changes, and student attendance on the move.

## Colors

The palette draws directly from classic botanical scholarship and modern architectural spaces:

- **Primary (`#0b6e4f`)**: Deep Emerald. Used for high-priority indicators, active timetable slots, current period markers, and primary calls to action.
- **Secondary (`#d4af37`)**: Academic Ochre / Soft Gold. Reserved for advisory alerts, exam markings, schedule conflicts, and highlights that require immediate attention without alarmist urgency.
- **Tertiary (`#29524a`)**: Cypress Slate. Used for secondary navigation, sub-headers, timetable grid tracks, and contextual metadata.
- **Neutral (`#f6f8f6`)**: Mint-tinted Alabaster. Serves as the primary canvas, backed by crisp white (`#ffffff`) for elevated schedule cards and `#1b2420` for high-legibility typographic hierarchy.

## Typography

The type system is powered entirely by **Plus Jakarta Sans**, balancing its friendly geometric counters with clear, legible numerals critical for mobile timetables, room numbers, and period timestamps.

- **Headlines**: Weighted at 600 and 700 with subtle negative tracking, creating an organized, anchor-like rhythm across days and screen titles.
- **Body**: Uses regular weights (400) optimized for effortless scanning of subject curricula, room descriptions, and attendance notes.
- **Labels & Numbers**: Employ slight positive letter-spacing and medium/semi-bold weights for period indicators (e.g., "PERIOD 02", "RM 402B"), ensuring rapid distinction at a glance.

## Layout & Spacing

The portal adheres to an edge-to-edge, single-column fluid mobile grid anchored by safe zones:

- **Horizontal Canvas Margins**: `1rem` on typical handheld devices (scaling down to `0.75rem` on ultra-compact displays) provides maximum horizontal room for timetable multi-column views and class detail cards.
- **Vertical Rhythm**: Built on an underlying 4px/8px incremental scale. Time rail tracks use consistent `1.5rem` (`space-xl`) offsets for hourly or period demarcations.
- **Schedule Stacking**: Class blocks in the timeline are separated by `0.75rem` (`space-md`) vertical gaps, ensuring periods are visually distinct while preserving a unified flow throughout the school day.

## Elevation & Depth

Visual hierarchy relies on **tonal layering and tinted atmospheric diffusion** instead of heavy drop shadows:

- **Base Layer (Elevation 0)**: Background canvas in `#f6f8f6`.
- **Card Layer (Elevation 1)**: Timetable cards and schedule blocks use pure `#ffffff` with a faint 1px border (`rgba(11, 110, 79, 0.08)`) and an ambient shadow: `0 2px 8px -2px rgba(11, 110, 79, 0.05)`.
- **Active / Current Period (Elevation 2)**: The active lecture card is framed with a left accent edge in `#0b6e4f` (4px width) and lifted by `0 8px 16px -4px rgba(11, 110, 79, 0.12)`.
- **Modals & Overlays (Elevation 3)**: Quick student check-in drawers and class detail sheets utilize frosted backdrop filters (`backdrop-filter: blur(12px)`) combined with `0 16px 32px -8px rgba(27, 36, 32, 0.16)`.

## Shapes

The design system implements a **Rounded** (scale `2`) geometry:

- Standard timetable class cards, bottom sheets, and containers adopt `0.5rem` (8px) base corners.
- Interactive day pills, quick-filter chips, and lesson tags utilize `1rem` to `1.5rem` smooth roundedness.
- Floating schedule action buttons and quick period jump controls feature soft circular/capsule styling, conveying warmth and approachable tactile usability.

## Components

### Timetable Class Cards
The core component of the view. Features a subtle left-border indicator reflecting subject categories (e.g., Emerald for Biology, Ochre for Homeroom). Displays:
- Start and end time in high-contrast `label-md`.
- Subject title in `title-md`, followed by Room & Grade level in `body-sm`.
- Status chip showing real-time states (e.g., "In Progress", "Upcoming", "Substitution").

### Day Selector / Week Rail
Horizontal carousel positioned below the top navigation bar. Each day item displays the abbreviated weekday and day of the month inside a rounded pill (`rounded-lg`). The active day uses a solid `#0b6e4f` fill with crisp white text and a dot badge for days containing special schedule changes.

### Chips & Tags
Compact, softly rounded tags (`rounded-lg`, height: 26px) with muted emerald tints (`rgba(11, 110, 79, 0.08)`) and bold text (`label-sm`). Used for room badges, section tags (e.g., "Grade 10-A"), and attendance status counters.

### Buttons
- **Primary**: Solid emerald fill (`#0b6e4f`), white text, `0.5rem` radius, used for primary actions like "Take Attendance" or "Start Class".
- **Secondary**: Emerald border (`1.5px`) with transparent surface or soft tint, used for "Swap Period" or "View Syllabus".
- **Ghost/Icon Button**: Low-profile icons for schedule navigation, calendar jump, and room search.

### Checkboxes & Attendance Radios
Circular selection surfaces with 20px hit areas, filled with `#0b6e4f` when checked and displaying an internal white checkmark or center pip. States include Present (Green), Late (Ochre), and Absent (Soft Rose).

### Input Fields & Search
Low-profile search fields with `0.5rem` roundedness, `#ffffff` surface, and light cypress borders (`rgba(41, 82, 74, 0.15)`). Focused state activates an emerald halo ring (`0 0 0 3px rgba(11, 110, 79, 0.15)`).