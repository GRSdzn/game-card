# Gates: playable vice demonstration

OWNS: scripts/**, data/**, tests/**, scenes/debug/**, localization/strings.csv, README.md, docs/DEMO_BATTLE.md, GATES.md

## Explicit battle result pass

Scope (solo): large localized outcome stamp in the existing modal → phase-based integration → deterministic victory/defeat captures → existing UI and launch checks, then re-verification.

- [x] N1: Victory and defeat are explicitly labeled above the existing reward/restart content; the result follows the model phase, keeps the smooth entrance and remains readable in EN/RU at compact/wide sizes, with no extra confirmation step or gameplay mutation.
  EVIDENCE: Captured reward/defeat/complete at 1280x720 RU and 1920x1080 EN in .godot/demo-review/result_*.png using the existing deterministic debug scene. Inspected both outcomes, post-reward victory persistence and compact content spacing. Main maps model phases to a presentation-only Outcome; the initial choice hides the stamp and the existing tray entrance includes it. Existing demo_ui_test passed all eight locale/size combinations and reward/continuation/defeat/restart paths; docs describe the explicit result.

## Machine overload pass

Scope (solo): data-driven pressure choices and central effects → pure ritual forecasts → mechanical controls and local VFX → model/UI tests and deterministic captures → re-verification.

- [x] M1: Full-pressure choices cost one Pressure once per turn; vent grants four block, overload costs three HP through block and adds eight damage to exactly the next valid ritual this turn. Invalid/terminal choices are no-ops; restart clears the mode; pure previews and seeded replay agree with resolution.
  CHECK: node tests/verify_demo.mjs machine
  EXPECT: MACHINE verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=0eee8420c282586dc23bf55190a38509709dd5cfc3d93c57e38bea16d83e3fd9; exit=0; EXPECT=matched; output-sha256=a4be08654d0fb568a460ffc1548fc6522df2520c78a2ecdcd9d2a3749ef0af8d; output-bytes=67; shell=C:\WINDOWS\system32\cmd.exe; cwd=E:\projects\game-card; path=b486667828a5/19 entries
- [x] M2: Real machine buttons emit model intents, show costs and lethal warnings in EN/RU, retain armed state across localization/resize, and clear warning/bonus on seal, end turn and restart. Animation never mutates battle/RNG.
  CHECK: node tests/verify_demo.mjs machine_ui
  EXPECT: MACHINE_UI verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=ab2f3386289b094f1ce9f442d6f54f75fbb7b770a6c2460747c19155bb65f6b1; exit=0; EXPECT=matched; output-sha256=b28deea1e99bb148c2987cf2bd0df501745548c8d17d2a019eed418cff1cabf8; output-bytes=73; shell=C:\WINDOWS\system32\cmd.exe; cwd=E:\projects\game-card; path=b486667828a5/19 entries
- [x] M3: Compact and wide deterministic machine scenes show readable controls, localized pressure warning, valve tremor, steam release and charged ritual feedback without covering cards or forecasts; terminology and exact rules are documented.
  EVIDENCE: Captured all five modes in .godot/demo-review/machine_{1280x720,1920x1080}_{ready,overload,vent,seal,lethal}.png using scenes/debug/machine_debug.tscn. Inspected RU compact ready/charge/vent/discharge and EN wide ready/charge; reviewed final lethal warning in machine_1280x720_lethal_final.png. Controls extend the existing ritual mechanism plate and clear the hand and forecast. Valve/needle tremor, local ring and steam use only presentation time. Actual pointer tests uncovered and fixed empty HandView bounds intercepting the valves; cards retain input. README and docs/DEMO_BATTLE.md reconciled against resource costs, one-turn charge, additive damage, immediate lethal payment and zero new RNG draws. No new final art or save format was introduced.

## Flow window entrance pass

Scope (solo): shared window entrance → phase identity and cancellation → deterministic visual review → existing UI/boot checks and re-verification.

- [x] P1: Choice, reward, complete and defeat windows fade and settle into place; repeated state/localization refreshes do not restart motion; dismissal cancels it and input remains modal immediately.
  EVIDENCE: Reviewed six rendered samples in .godot/demo-review/flow_{defeat,choice,reward,complete}_*.png, including defeat at 0.12/0.24/0.4 seconds and settled compact/wide layouts. Panel opacity and 18px travel settle within 0.4 seconds, text fits. Reviewed stable untranslated screen identity, guarded entrance reset, immediate modal input capture and dismiss cancellation. Existing demo_ui_test passed all eight locale/size combinations, including pointer selection during entrance, reward-to-complete, continuation, restart and defeat.

## Instrument animation pass

## Enemy turn feedback pass

Scope: mechanical button recoil, Inspector warning, travelling impact and distinct blocked/damaging attack feedback from resolved model events. Solo: result event → reusable sequence → integration/visual tests → re-verification.

- [x] T1: Accepted enemy attacks emit one factual result; animation distinguishes block from HP loss, retriggers safely, cancels on rebuild/restart, and never delays or mutates battle/RNG state.
  CHECK: node tests/verify_demo.mjs enemy_animation
  EXPECT: ENEMY_ANIMATION verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=931ea4e7a36155aef9b0a1661aaa00dbaea6e8ba085e7cd1a01a19b5c3d007b6; exit=0; EXPECT=matched; output-sha256=8a2e5783e3314a6660230599b78d77511bbbef66940558434cac7f1fc32db2a2; output-bytes=87; shell=C:\WINDOWS\system32\cmd.exe; cwd=E:\projects\game-card; path=b486667828a5/19 entries
- [x] T2: Deterministic attack and blocked-attack frames remain readable in compact and wide layouts; no full-screen flash or overlay input capture.
  EVIDENCE: Inspected .godot/demo-review/enemy_{compact,wide}_{0,20}.png at the impact phase (0.52 seconds): red damage and brass full-block result clear HP labels and hand cards. Motion is localized to warning, path, contact and rail; overlay/label ignore input. Expanded the existing forecast plate to fit the initial RU no-combination explanation uncovered by these captures. Deterministic replay scene: scenes/debug/enemy_turn_feedback_debug.tscn.

Scope: tactile pressure needle/steam and mechanical protection feedback; presentation only, no RNG or effect changes. Solo tree: reusable feedback → table integration → deterministic animation tests → visual check and re-verification.

- [x] A1: Pressure interpolates and vents on spending/refill; protection assembles and retracts on block changes; repeat snapshots and rebuilds do not replay bursts; disabled motion snaps to readable state.
  CHECK: node tests/verify_demo.mjs animation
  EXPECT: ANIMATION verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=c6bf72e831584f9c84d8b3561dabfe19748c7c30fef62fbb6c5db2e3895bd72d; exit=0; EXPECT=matched; output-sha256=0853c6431c37437e46ec04347e06e6035ef2b211339194768cb45ac85c0f2c36; output-bytes=81; shell=C:\WINDOWS\system32\cmd.exe; cwd=E:\projects\game-card; path=b486667828a5/19 entries
- [x] A2: Pressure and protection motion remains localized and readable at compact and wide sizes in the deterministic instrument debug scene.
  EVIDENCE: Inspected .godot/demo-review/instruments_compact.png (1280x720) and instruments_wide.png (1920x1080), sampled at 0.18 seconds after spending pressure and gaining protection. Armour clears HP fill and labels; steam stays above the gauge outlet. InstrumentFeedbackTest independently measures motion progression, retargeting, static fallback and zero gameplay/RNG mutation. Manual looping scene is scenes/debug/instrument_feedback_debug.tscn.


Scope: choose one of two data-driven Vices, fight a telegraphed alternating enemy, preview rituals without mutation, and claim one persistent reward per victory. Historical presentation records below remain historical; the gates here govern this gameplay migration.

Execution tree (solo): data/effect contracts → battle and run flow → localized table integration → deterministic verification and visual review.
Checks are authored/reviewed for this task and run in the project root. Set GODOT_BIN to the installed Godot executable. No downloaded CHECK commands are executed.

- [x] D1: Fresh editor import and main-scene launch have no parser/resource/runtime errors.
  CHECK: node tests/verify_demo.mjs boot
  EXPECT: BOOT verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=3d9665c8260c9030d7f63420837fd67de58146cf747e2584fc9d51c1747e5237; exit=0; EXPECT=matched; output-sha256=2c2b80376b6068bb20453491e68f84b2cf78ac3314d74acd711eeb0faccf088e; output-bytes=150; shell=C:\WINDOWS\system32\cmd.exe; cwd=E:\projects\game-card; path=b486667828a5/19 entries
- [x] D2: Legacy battle, table contracts, responsive checks, and EN/RU localization pass; main integration explicitly selects a Vice.
  CHECK: node tests/verify_demo.mjs regression
  EXPECT: REGRESSION verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=c046b71500f21ac723f46b21e2a921509e3b4ee50363bf80474fb10e73d1a670; exit=0; EXPECT=matched; output-sha256=2a40e8b4c2cfe493865610ee898371dd8c1b11b02602030cd6c64a04c720577e; output-bytes=166; shell=C:\WINDOWS\system32\cmd.exe; cwd=E:\projects\game-card; path=b486667828a5/19 entries
- [x] D3: Two Vices have tested costs/benefits; intents alternate and ritual mitigation matches displayed damage; previews match actual resolution without state/RNG mutation; reward and terminal guards hold; seeded replay is reproducible.
  CHECK: node tests/verify_demo.mjs gameplay
  EXPECT: GAMEPLAY verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=5fa22d4edb5258442205afa1e4758f72c7c22e616fe9160f2e5e7de8802fcfab; exit=0; EXPECT=matched; output-sha256=6944fc732feaa11bff3db18f721b53c1c37c9dff69417efa949cd3e035052a1d; output-bytes=72; shell=C:\WINDOWS\system32\cmd.exe; cwd=E:\projects\game-card; path=b486667828a5/19 entries
- [x] D4: Live selection, hover preview, localized intent, victory reward, continuation and restart work through UI intents at supported sizes.
  CHECK: node tests/verify_demo.mjs ui
  EXPECT: UI verification passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=dc847b9e0695ea22e81ad8a5db07dfdb9b23d9f7178cebebee96ee3f80a0adf2; exit=0; EXPECT=matched; output-sha256=b090a54f358794837eb6775dc3dd4982daa098c16b60e396012aa7d4572f462c; output-bytes=62; shell=C:\WINDOWS\system32\cmd.exe; cwd=E:\projects\game-card; path=b486667828a5/19 entries
- [x] D5: New screens and preview remain legible in EN/RU at 1280x720, 1366x768, 1600x900, and 1920x1080 using existing materials/frame hierarchy.
  EVIDENCE: Rendered deterministic choice/battle/reward captures for all eight size/locale combinations in .godot/demo-review/{choice,battle,reward}_{width}x{height}_{en,ru}.png; visually reviewed both languages across all four sizes plus complete/defeat at 1280x720 RU. Corrected modal z-order and frame/content padding, then recaptured the affected screens. Existing Utility frame, iron material, brass and parchment remain readable; forecasts clear cards. D4 independently checks bounds and actual pointer input.
- [x] D6: Documentation states controls, exact Vice/intent/reward rules, event ordering, preview boundaries and deterministic debug commands; final diff preserves pre-existing user edits.
  EVIDENCE: README and docs/DEMO_BATTLE.md reviewed against model/resources and original demonstration request. BattleController remains headless; stable IDs and enum ordinals retained; no new final art or UI RNG. git diff --check passed. Pre-existing .idea and import/project line-ending changes were not reverted or staged; content diff is confined to the feature files. Historic gates below are explicitly historical, not newly certified visual work.

## Historical acceptance ledgers (prior work)

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
