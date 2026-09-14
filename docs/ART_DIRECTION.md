# Iron Covenant — Art Direction

## Visual thesis

**Industrial gothic steampunk + dystopian propaganda + Victorian engraving + dirty brass machinery + warm gaslight.** The battle table is a physical card machine in an authoritarian ministry: bolted together, patched, soot-covered, and never clean. It must not resemble a modern dashboard with brown rectangles.

Every visual decision reinforces machine, bureaucracy, decay, control, physicality, or quiet bureaucratic absurdity. Prefer darker, more industrial, and more restrained choices when unsure.

## Controlled palette

| Role | Hex | Meaning |
| --- | --- | --- |
| Coal black | `#0D0E0D` | outer shadow and vignette |
| Black / dark iron | `#171817` / `#23221F` | machinery base and housing |
| Dark wood / burnt brown | `#261A13` / `#3B291D` | table and recesses |
| Brass dark/base/light | `#65451F` / `#8B612C` / `#B9823E` | structure and bevel |
| Copper dark/base | `#59362A` / `#864D36` | secondary metal |
| Parchment dark/base/light | `#7E6747` / `#B59A68` / `#D0B784` | paper and readable labels |
| Amber dark/light | `#9D5E22` / `#E0A04A` | neutral lamps and machinery |
| Danger red/bright | `#9B4038` / `#D15A4D` | damage, danger, enemy threat only |
| Player cyan/hi | `#589C9E` / `#79C4C6` | player hover, selection, valid action only |
| Ash gray | `#7A7770` | secondary and disabled text |

Keep 70–80% near-black, iron, wood, or brown. Brass/parchment takes 10–15%; emissive colour takes less than 5%. Cyan is never ambient decoration and red is never neutral UI.

## Material and frame rules

Use layers, not one decorated rectangle: dark base, subtle material, edge-darkening, light wear, frame, inner recess, then a restrained warm bevel. Material must stay subordinate to rules text.

The runtime modular kit is in `assets/ui/`: `black_iron_01`, `dark_wood_01`, `oxidized_brass_01`, `aged_copper_01`, `dirty_parchment_01`, `glass_dark`, and `leather_card_stock`. Wear overlays are `soot_overlay`, `scratches_overlay`, and `grime_edges`.

There are three frame families: **Utility** for logs/tooltips/archive, **Mechanism** for the Ritual/deck/gauges, and **Unique** for Inspector/boss modules. `IronStyleKit` applies them through `NinePatchRect` with 18px patch margins. Frame art has no text or semantic state; replacements must preserve those margins.

## Lighting and depth

Brightness hierarchy: Inspector portrait, interacting card, Ritual Machine, key gauges, table, utility rails, then extreme edges. The scene is mostly dark; local lamps reveal it. The live stack is factory background, physical table, mechanical UI, cards, local accents, then a reusable vignette.

Use upper/front warmth for Inspector, muted amber for Ritual, a small Pressure light, and soft shadows that deepen during card hover. Vignette stays 15–30% perceptually and cannot cover critical labels. No permanent fog over rules, endless spinning gears, screen shake, or decorative cyan.

## Cards and illustration

Cards are regime documents, not fantasy spell cards: cost seal, title strip, engraving window, suit/rank, short rule, and status. In hand, priority is cost, title, art, short effect, suit/rank, and availability. Full description remains in tooltip/inspect. Native labels must be sharper than art.

`CardData.art_path` is presentation-only. It never replaces the stable card ID, localization keys, suit, rank, or effects. Empty art falls back to a suit engraving, preserving reusable `CardView`. The language-neutral card back is `assets/ui/card_back_iron_covenant.svg`; values and rules are always native Godot text.

Base illustration prompt:

```text
dark dystopian steampunk card game artwork, Victorian industrial propaganda,
19th century engraved illustration, etched ink linework, aged printing, dirty
paper texture, black iron and antique brass machinery, factory soot,
authoritarian bureaucracy, grim atmosphere, warm amber gaslight, high contrast,
limited muted palette, no modern objects, no glossy sci-fi, no neon, no anime,
no cartoon, no text, no letters, no logos
```

Reject fake text, malformed anatomy, wrong perspective, neon, inconsistent light direction, unclear silhouettes, and excessive orange. Before larger production, apply one shared non-destructive grade: lower saturation, slightly crushed blacks, warm highlights, brown midtones, and a subtle paper overlay.

## Typography and localization

The initial font fallback is `Segoe UI`, `Noto Sans`, then `Arial`. Any future display font must include Latin and Cyrillic and be checked at 1920x1080, 1600x900, and 1366x768 in English and Russian. Main text is parchment, secondary text brass/ash, disabled text ash; do not use ordinary pure-white UI.

Generated art, panels, backgrounds, card backs, and gauges contain no readable EN/RU words, values, or gameplay terms. All player-facing text comes from `localization/strings.csv` through `LocalizationManager`; leave room for longer Russian text.

## Motion, VFX, and audio preparation

Motion is tactile and event-driven: 0.12–0.20 second card hover, short commit travel, Inspector damage flash, and Ritual pulse/partial rotation. Presentation may react to cached UI state only; it may not mutate state or consume `RunState.rng`. Future steam is rare small puffs from Pressure, Inspector pipes, and Ritual, never over rules.

Future audio: paper for cards, brass click for controls, gear/low impact for Ritual, mechanical counter for multiplier, and steam hiss for pressure.

## Asset pipeline

```text
assets/source/generated/  selected ImageGen source copies
assets/source/edited/     non-destructive cleanup files when needed
assets/textures/          runtime PNG/WebP/JPG exports
assets/ui/                reusable language-neutral SVG UI kit
assets/icons/             future small original icons
assets/shaders/           optional restrained compositing shaders
```

Never overwrite source generations. Runtime paths use lowercase snake_case. Rejected assets never enter runtime folders.

| Good | Avoid |
| --- | --- |
| Low-contrast wood under brass mechanism | Bright flat brown dashboard blocks |
| Amber lamp for neutral machinery | Cyan environmental decoration |
| Red only for hostile/critical information | Red neutral counters and labels |
| Paper card with native sharp text | Rules written into generated art |
| One strong Inspector housing | Repeating the boss frame everywhere |

## Battle-table rebuild standard

The authoritative battle composition is a **broad physical apparatus**, not a
three-column application layout. The table takes roughly 82–88% of the logical
viewport width; instruments are bolted to its sides rather than placed in free
standing information panels.

The material order is: industrial city beyond the machine, black-iron outer
chassis, `assets/textures/ui/battle_table_apparatus_01.png` as the table body,
then native Inspector/Ritual/slot/card controls. The apparatus texture is a
language-neutral structural underlay: pipes, card rail, brass braces and the
faint central aperture remain art; every value and label stays native Godot UI.

At a thumbnail the primary masses must read in this order: Inspector housing,
central Ritual ring, five physical cards on the lower rail, compact instrument
edge, then the factory environment. A dark scene must still separate these
masses in grayscale. Battle log and seed controls belong to the collapsed
Archive and do not occupy the playfield.

Inspector, Ritual Machine, left instrument HUD, three illustrated cards, deck/discard, table material, and outer lighting are the initial quality bar. New presentation work must fit this cluster’s palette, frame level, materials, typography, and lighting.
