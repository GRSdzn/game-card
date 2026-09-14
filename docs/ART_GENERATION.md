# Iron Covenant — Art Generation Log

This ledger records selected ImageGen sources used by the first visual art pass. It complements [ART_DIRECTION.md](ART_DIRECTION.md). Each selected image was visually inspected for readable fake text, malformed anatomy, unsuitable perspective, and neon/cyberpunk styling before it entered the project.

| Date | Asset | Source copy | Runtime output | Prompt summary | Integration notes |
| --- | --- | --- | --- | --- | --- |
| 2026-09-14 | Inspector portrait | `assets/source/generated/inspector/inspector_portrait_01.png` | `assets/textures/inspector/inspector_portrait_01.png` | Compliance Inspector, industrial respirator, brass apparatus, soot, upper gaslight, Victorian engraving influence; no text/logos/neon. | Aspect-covered crop in a mechanical socket plus low-opacity native mask overlay. |
| 2026-09-14 | Kick the Grave | `assets/source/generated/cards/kick_grave_01.png` | `assets/textures/cards/card_art_grave_kick_01.png` | Worker kicks an iron coffin in an industrial cemetery; smoke, engraving, bureaucratic absurdity; no text. | CardView crops to its art window; native document frame protects rule readability. |
| 2026-09-14 | Bone Defense | `assets/source/generated/cards/bone_defense_01.png` | `assets/textures/cards/card_art_bone_guard_01.png` | Skeletal bureaucrat behind filing cabinets and bone barricade; no paperwork or readable marks. | The first candidate was rejected because it contained fake lettering. Corrected source has no readable UI text. |
| 2026-09-14 | Hangover | `assets/source/generated/cards/hangover_01.png` | `assets/textures/cards/card_art_hangover_01.png` | Ruined factory clerk, metal desk, unlabelled medicine bottles, pipes, solemn absurdity; no text. | Crop is presentation-only; stable card values and effects do not change. |
| 2026-09-14 | Factory ministry | `assets/source/generated/environment/factory_ministry_01.png` | `assets/textures/environment/factory_ministry_01.png` | Oppressive Victorian industrial city, factories, pipes, smoke, sparse gas lamps, clear UI centre; no text/logos. | Low-opacity layer behind table shell and subordinate to cards. |

## Rebuild selections

| Date | Asset | Source copy | Runtime output | Integration notes |
| --- | --- | --- | --- | --- |
| 2026-09-14 | Kick the Grave v2 | `assets/source/generated/cards/kick_grave_02.png` | `assets/textures/cards/card_art_grave_kick_02.png` | Cinematic grave worker and iron coffin replace the earlier sepia-first validation art without changing the card's stable ID or effects. |
| 2026-09-14 | Bone Rebuttal v2 | `assets/source/generated/cards/bone_defense_02.png` | `assets/textures/cards/card_art_bone_guard_02.png` | Cinematic skeletal bureaucrat and filing-cabinet barricade replace the pure-engraving presentation image. |
| 2026-09-14 | Hangover v2 | `assets/source/generated/cards/hangover_02.png` | `assets/textures/cards/card_art_hangover_02.png` | Factory clerk under gaslight; same CardData identity and gameplay. |
| 2026-09-14 | Cinematic black iron | `assets/source/generated/materials/mat_black_iron_cinematic_01.png` | `assets/textures/materials/mat_black_iron_cinematic_01.png` | Shared neutral charcoal material for shell and frames. |
| 2026-09-14 | Battle table apparatus | `assets/source/generated/ui/battle_table_apparatus_01.png` | `assets/textures/ui/battle_table_apparatus_01.png` | Original front-facing black-iron tabletop with brass pipes, lower rail and aperture; no cards, readable text, values or localized UI. It sits below native controls. |

## Reproduction base prompt

```text
dark dystopian steampunk card game artwork, Victorian industrial propaganda,
19th century engraved illustration, etched ink linework, aged printing, dirty
paper texture, black iron and antique brass machinery, factory soot,
authoritarian bureaucracy, grim atmosphere, warm amber gaslight, high contrast,
limited muted palette, no modern objects, no glossy sci-fi, no neon, no anime,
no cartoon, no text, no letters, no logos
```

The Inspector adds an industrial respirator, cold bureaucratic posture, and a centred bust. The environment adds clear low-contrast centre/lower space for native UI.

## Import policy

Sources are preserved in `assets/source/generated/`; runtime copies use stable names in `assets/textures/`. No destructive external paint-over was used in this pass. Cropping, opacity, material layering, and vignette happen in Godot so raw sources remain recoverable. Before broader card production, add one shared non-destructive grade: saturation down, slightly crushed blacks, warm highlights, brown midtones, and low-opacity paper overlay.

Never import generated readable words, values, localized English/Russian text, or rejected candidates into a runtime folder.
