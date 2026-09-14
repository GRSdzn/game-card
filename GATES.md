# Iron Covenant presentation and localization — acceptance ledger

## Scope

## Battle Table Visual Rebuild — authoritative gates

The earlier presentation ledger is superseded for visual acceptance: it
described the rejected dashboard composition. These gates apply to the physical
apparatus rebuild.

| Gate | Observable check | Status |
| --- | --- | --- |
| B1. Parser/resource scan | `godot --editor --headless --path . --quit` | Passed after final rebuild |
| B2. Battle UI contract | `res://tests/battle_table_ui_test.tscn` | Passed after final rebuild |
| B3. Gameplay preservation | `res://tests/battle_smoke_test.tscn` | Passed after final rebuild |
| B4. RNG isolation | Scan presentation scripts for `RunState.rng`, global random calls, or EffectResolver mutation | Passed: no presentation matches |
| B5. EN localization | `res://tests/localization_test.tscn` | Passed after runtime-refresh fix |
| B6. RU localization | `res://tests/localization_test.tscn` | Passed after runtime-refresh fix |
| B7. 1920 EN visual | Captured `screens/rebuild_1920_en_verified.png`; Inspector, Ritual, hand, edge instruments, material table and warm lighting are visible | Passed by manual inspection |
| B8. 1600 EN visual | Deterministic debug scene inspected at 1600x900 | Passed by manual inspection |
| B9. 1600 RU visual | Deterministic debug scene inspected at 1600x900 with `--art-locale=ru` | Passed by manual inspection |
| B10. 1366 safety | Deterministic RU debug scene inspected at 1366x768 | Passed by manual inspection |
| B11. Thumbnail hierarchy | `screens/rebuild_1920_thumbnail_verified.png` retains Inspector, Ritual ring, hand, material table and warm edge lighting | Passed by manual inspection |
| B12. Grayscale hierarchy | `screens/rebuild_1920_grayscale_verified.png` separates Inspector, cards, Ritual, table, and background values | Passed by manual inspection |
| B13. Empty-table physicality | `screens/rebuild_empty_1920_en_verified.png` has rails, pipes, machine aperture and chassis without hand cards | Passed by manual inspection |
| B14. Generated-art text rule | New apparatus, material, Inspector and card art contain no readable EN/RU gameplay text | Passed by manual asset review |
| B15. Documentation/provenance | Art Bible, generation ledger, README and this ledger identify the rebuild assets | Passed |

This pass changes presentation and localized display text only. `BattleController`,
effects, combo formulas, weaknesses, deck rules, enemy behavior, seed behavior,
and gameplay RNG remain outside the UI and localization layers.

| Gate | Observable check | Status |
| --- | --- | --- |
| G1. Existing battle smoke test | `res://tests/battle_smoke_test.tscn` | Passed |
| G2. Existing BattleTable UI test | `res://tests/battle_table_ui_test.tscn` | Passed |
| G3. BattleController semantics remain stable | Existing deterministic smoke assertions pass | Passed |
| G4. Presentation/localization consume no gameplay RNG | `rg -n 'EffectResolver|randi\(|randf\(' scripts/ui scenes` returns no matches | Passed |
| G5. English translation resource loads | `localization_test.tscn` checks `TranslationServer` and `UI_SEAL_RITUAL` | Passed |
| G6. Russian translation resource loads | `localization_test.tscn` checks `TranslationServer` and Russian `UI_SEAL_RITUAL` | Passed |
| G7. Runtime switch refreshes visible table text | `localization_test.tscn` switches EN → RU and asserts Inspector, card, and log refresh | Passed |
| G8. Selected locale persists | `localization_test.tscn` writes isolated settings and reloads it | Passed |
| G9. Card identity is locale-independent | `localization_test.tscn` retains its stable fixture ID across switch | Passed |
| G10. Russian card fixture is assigned without corrupted text | `localization_test.tscn` asserts the Cyrillic title; visual glyph raster check remains manual | Automated text check passed; visual check pending |
| G11. All visible BattleTable/CardView/HandView text is key-driven | Scan scripts **and scenes**; the visible `BUREAU APPROVED / ILLUSTRATION SLOT` fallback is removed from `CardView.tscn` | Passed |
| G12. 1920×1080 EN physical-table pass | Run `scenes/debug/battle_table_composition_debug.tscn` and inspect | Pending manual inspection |
| G13. 1600×900 EN responsive pass | Run `scenes/debug/battle_table_composition_debug.tscn` and inspect | Pending manual inspection |
| G14. 1600×900 RU responsive pass | Switch to `Русский` in the archive and inspect | Pending manual inspection |
| G15. Hovered hand card remains visible and unclipped | UI test checks raised z-order, unclipped hand, and bounds for five deterministic cards | Passed structurally |
| G16. Inspector is the strongest top-level focal point | Inspect debug scene at target resolutions | Pending manual inspection |
| G17. Ritual Machine is the board’s visual center | Inspect debug scene at target resolutions | Pending manual inspection |
| Parser and resource scan | `godot --editor --headless --path . --quit` | Passed |

## Manual procedure

Open `scenes/debug/battle_table_composition_debug.tscn` at 1920×1080 and
1600×900. Check that the five known cards are complete, a hovered card clears its
neighbors, the Inspector and Ritual Machine anchor the table, and no central dead
region dominates. Repeat at 1600×900 after choosing `Русский` from `ARCHIVE
FILES`; verify Cyrillic glyphs, wrapping, and primary actions.

## Readability redesign gates — opened by `screens/1.png` and `screens/2.png`

| Gate | Observable check | Status |
| --- | --- | --- |
| R1. No critical text is clipped, letter-stacked, or behind a sibling | Automated bounds assertions for EN/RU at 1366×768, 1600×900, and 1920×1080; manual screenshot review | Automated checks passed; manual review pending |
| R2. Inspector has independent portrait, identity, Integrity, and Intent cells | Structural UI test and manual review at all target widths | Structural checks passed; manual review pending |
| R3. Ritual area presents committed state without overflowing card-title lists | Structural text/bounds test with five long RU titles | Passed |
| R4. Hand stays readable before and during hover | Five-card bounds, z-order, and title/effect readability review | Automated checks passed; manual review pending |
| R5. Side apparatus collapses or reflows before it steals the battle surface | Responsive layout test at 1366×768 and manual review | Automated checks passed; manual review pending |
| R6. Reusable material resources replace flat-only primary surfaces | Resource/scene audit for iron, brass, wood, parchment, suit illustrations, Inspector mask, and Ritual emblem | Passed |
| R7. Presentation feedback explains play, ritual, damage, and enemy-turn state changes | BattleTable state-diff animation and event-readout coverage in the deterministic UI integration test; no battle-state mutation or gameplay RNG | Automated integration passed; manual review pending |
| R8. Style Kit v1 follows one documented visual language | `docs/ART_DIRECTION.md`, palette tokens, reusable material/frame resources, and a deterministic reference scene audit | Passed by `battle_table_ui_test.tscn` |
| R9. Frame hierarchy remains readable | Utility, mechanism, and unique-object frame levels are distinguishable in the reference scene without reducing text contrast | Pending |

## Full Visual Art Pass v1

| Gate | Observable acceptance | Status |
| --- | --- | --- |
| G1 | Existing headless battle smoke test passes unchanged. | Passed: `battle_smoke_test.tscn` |
| G2 | Existing BattleTable UI integration test passes. | Passed: `battle_table_ui_test.tscn` |
| G3 | Presentation, localization, and art code do not consume `RunState.rng`; BattleController behavior is unchanged. | Passed: smoke/UI tests and presentation scan |
| G4 | English localization test passes. | Passed: `localization_test.tscn` |
| G5 | Russian localization test passes. | Passed: `localization_test.tscn` |
| G6 | 1920x1080 English battle table is visually inspected: physical apparatus hierarchy, readable cards, no material clipping. | Pending manual inspection |
| G7 | 1600x900 English battle table is visually inspected. | Pending manual inspection |
| G8 | 1366x768 English/Russian safety layout is visually inspected. | Pending manual inspection |
| G9 | Generated runtime art has no baked gameplay or localized UI text. | Passed: selected Inspector, three cards, and environment manually reviewed |
| G10 | Inspector is the strongest upper focal point and is integrated into a mechanical housing. | Pending manual inspection |
| G11 | Ritual Machine is present as the visual center and reacts only to existing presentation state. | Pending manual inspection |
| G12 | Reusable material, frame, lighting, and card-stack assets are integrated by the live BattleTable. | Passed structurally: resource scan and UI integration test |
| G13 | Russian card titles and rules remain readable with Cyrillic glyph coverage. | Pending manual inspection |
| G14 | English card titles and rules remain readable. | Pending manual inspection |
| G15 | Art direction, generation provenance, localization constraints, and runtime asset paths are documented. | Passed: ART_DIRECTION, ART_GENERATION, README |
