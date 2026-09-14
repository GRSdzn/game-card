---
name: iron-covenant-dev
description: Project-specific completion and architecture discipline for the Godot roguelike deckbuilder The Iron Covenant. Use for multi-file features, gameplay systems, UI vertical slices, refactors, migrations, deterministic tests, and explicit requests to complete the task thoroughly. Works together with the upstream unlazy skill.
---

# Iron Covenant development skill

Read `AGENTS.md`, `README.md`, and current `GATES.md` before implementation.

For substantial tasks, invoke/use the upstream `unlazy` discipline and create an acceptance ledger before real work.

## Mandatory invariants

1. Godot 4.7.x, typed GDScript preferred.
2. Gameplay is headless-testable.
3. UI emits intent and does not own gameplay state.
4. All run-affecting RNG uses `RunState.rng`.
5. Presentation must never consume gameplay RNG.
6. Cards, Vices, relics, enemies, and effects remain data-driven.
7. Stable content IDs must survive cosmetic refactors.
8. Effects remain composable through the central resolver.
9. Animations/tweens cannot determine combat truth.
10. Update docs and tests when contracts change.

## Product test

Every new gameplay system should reinforce at least one pillar:
- weakness becomes strength;
- readable combo escalation;
- physical mechanical table;
- dark bureaucratic humor;
- replayable seeded runs.

If a feature reinforces none of these pillars, challenge its scope before expanding it.

## Visual test

Default presentation:
- front-facing mechanical card table;
- dark steampunk dystopia;
- brass/copper/iron + soot + parchment;
- warm lamp light;
- restrained cyan selection;
- restrained red danger;
- physical card motion;
- no generic neon sci-fi UI.

## Completion

Do not claim completion after implementation alone.

Require:
- acceptance gates;
- verification;
- regression check;
- re-verification;
- documentation reconciliation.

For visual-only criteria, use explicit manual gates rather than pretending they are automated.
