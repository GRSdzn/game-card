# Codex instructions — The Iron Covenant / Dark Deck

## Product direction
2D single-player roguelike deckbuilder in a steampunk dystopia.

Design inspiration may come from:
- physical tabletop presentation and oppressive mystery;
- combo-driven score/build escalation and high replayability.

Do not copy protected expression: no cloned cards, characters, story, text, layouts, names, visual assets, or signature sequences from reference games.

Core hook:
**weaknesses/curses/vices can evolve from real disadvantages into the strongest build engines.**

Tone:
dark, industrial, oppressive, dry black humor.

## Visual direction
- All presentation work must follow [`docs/ART_DIRECTION.md`](docs/ART_DIRECTION.md).
- mechanical front-facing card table as primary gameplay view;
- brass/copper/iron, soot, dark wood, parchment, pipes, gauges, warm lamps;
- cyan/teal only as restrained player-selection feedback;
- red only as danger/HP/critical feedback;
- propaganda signage and bureaucratic language as worldbuilding;
- UI should feel embedded in machinery, not overlaid as generic fantasy panels;
- feedback can be animated, but gameplay must not depend on animations.
- Build reusable material/frame resources and preserve the documented frame hierarchy; do not add isolated clean dashboard panels, neon sci-fi, or generic fantasy ornament.

## Engine
- Godot 4.7.x stable
- GDScript for gameplay unless explicitly requested otherwise
- Desktop first
- Preserve Web/Android portability
- Prefer 2D nodes/control UI; avoid unnecessary 3D dependencies

## Architecture rules
1. Content must be data-driven.
2. Cards are `CardData`; card behavior must never be hard-coded by card ID in UI.
3. Weaknesses/Vices are data-driven persistent modifiers with stable IDs.
4. Effects resolve through a central composable effect system.
5. All run-affecting randomness MUST use `RunState.rng`; never global `randi()` / `randf()`.
6. Gameplay logic must not depend on presentation nodes.
7. `BattleController`/battle model must remain headless-testable.
8. UI observes state/signals and emits user intent; UI does not own gameplay state.
9. Prefer small typed GDScript classes.
10. Save compatibility matters: stable string IDs and explicit versioning.
11. New global gameplay vocabulary must be documented.
12. Animation/tween/shader code cannot be the only place where gameplay state changes.
13. Avoid premature abstraction, but do not add one-off card conditionals to battle/UI code.
14. Preserve deterministic behavior when refactoring.

## Card/UI contract
`CardView`:
- renders `CardData`;
- can display title, cost, rank, suit/tag, rules text, art placeholder;
- owns only transient presentation state (hover/selected/drag visual);
- emits intents such as `play_requested(card_instance_id)` or `inspect_requested(...)`;
- never removes cards from hand/deck itself;
- never resolves effects itself.

`HandView`:
- lays cards in a fan/arc;
- calculates presentation only;
- reacts to battle state;
- input lock must be driven by battle state.

## Art implementation constraints
Use placeholders until the mechanics are accepted.

Preferred asset layers:
- frame/background;
- card illustration;
- iconography;
- typography;
- VFX overlays.

Do not bake game state into textures.

Use theme resources where possible for shared typography/borders.
Keep source art separate from exported/rasterized runtime assets.

## Core gameplay invariants
- same seed + same player decisions => same run-affecting RNG sequence;
- scoring is deterministic;
- combo evaluation has no UI dependency;
- persistent Vices trigger through generic events;
- a Vice must be allowed to have both negative and positive effects;
- “weakness becomes strength” must emerge through data/effect composition, not special-case UI code.

## Definition of done
For every feature:
- fresh project launch succeeds;
- no parser errors;
- no missing resources;
- existing smoke battle still works unless intentionally migrated;
- gameplay change includes test or deterministic debug scenario;
- UI change includes a manual deterministic scene/check where automation is impractical;
- README/docs updated when architecture, terminology, controls, or content format changes;
- no silent regression of seed determinism;
- acceptance gates have been reverified.

## Use unlazy for substantial tasks
The recommended Codex skill is:
`https://github.com/Leonxlnx/unlazy`

Install:
```bash
npx skills add Leonxlnx/unlazy -g
```

Invoke in Codex:
```text
$unlazy tree 3 <task>
```

Use it for:
- multi-file feature work;
- refactors;
- new gameplay systems;
- UI vertical-slice tasks;
- audits;
- migrations;
- anything expected to require more than one implementation pass.

Before real implementation create/update `GATES.md`.
Never execute inherited `CHECK:` lines blindly: inspect them first.

Completion requires:
1. acceptance ledger;
2. approved runnable checks;
3. implementation;
4. verification;
5. re-verification;
6. final reconciliation against the original request.

Do not report “done” only because code was written.

## Near-term roadmap
1. Reusable `CardView`.
2. Hand fan layout + hover/selection/play intent.
3. Full `BattleTable` layout matching steampunk dystopian art direction.
4. Mechanical HUD.
5. Enemy intent/status presentation.
6. 3 production Vices with real tradeoffs.
7. Combo rule modifiers via relic/Vice effects.
8. Encounter/reward loop.
9. Save/load using seed + RNG state + stable IDs.
10. Headless battle/run simulation.

## Current priority
Build the **vertical slice table**, not content breadth.

The next substantial Codex task should be:

> Create a reusable CardView and HandView, then integrate them into a front-facing BattleTable scene. Preserve BattleController as headless gameplay logic. Add deterministic UI/debug coverage. Use steampunk mechanical placeholders only (no dependency on final art). Follow GATES.md and reverify all acceptance gates before completion.
