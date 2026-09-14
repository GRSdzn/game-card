# Codex workflow for The Iron Covenant

## Why unlazy

The project uses `unlazy` for substantial autonomous changes so Codex must prove completion against explicit acceptance gates rather than stopping after an apparently plausible implementation.

Upstream:
https://github.com/Leonxlnx/unlazy

## Install

Recommended user-level installation:

```bash
npx skills add Leonxlnx/unlazy -g
```

Alternative manual Codex location:
```text
~/.codex/skills/unlazy
```

For reproducible team environments, pin an exact upstream commit rather than relying indefinitely on `main`.

## Invocation

For a normal multi-file feature:
```text
$unlazy tree 3 implement CardView + HandView + deterministic UI verification
```

For a larger refactor:
```text
$unlazy tree 4 refactor battle presentation without changing deterministic gameplay behavior
```

Depth should increase with task breadth, not just code size.

## Project-specific process

### 1. Read contracts first
Before coding:
- `AGENTS.md`
- `README.md`
- relevant scripts/resources/tests
- current `GATES.md`

### 2. Write acceptance gates
Each gate should test an observable outcome.

Good:
```text
G1: CardView renders CardData and emits play intent without applying effects.
CHECK: <deterministic test command>
EXPECT: card view contract passed
```

Bad:
```text
G1: UI looks good
```

A purely visual criterion can be manual, but separate it from testable behavioral requirements.

### 3. Security rule
`CHECK:` is executable shell code.

On inherited or generated gates:
- inspect commands;
- inspect called scripts;
- inspect working directory;
- approve only after review.

### 4. Implement leaf by leaf
For this project, typical leaves are:
- data contract;
- gameplay/model;
- UI/presentation;
- tests;
- documentation.

Avoid mixing all concerns in one script.

### 5. Verify determinism
Any gameplay task must explicitly consider:
- use of `RunState.rng`;
- stable call order;
- no random calls in presentation that consume gameplay RNG;
- seed regression.

Presentation randomness must use a separate cosmetic RNG or deterministic visual rule if necessary.

### 6. Reverify
Do not rely on previously green checks after refactors.
Re-run runnable gates and reconcile the final implementation against the user request.

## Suggested acceptance categories

- BOOT — project launches/loads
- PARSE — no GDScript parse/resource errors
- CORE — gameplay behavior
- RNG — deterministic seed behavior
- UI — signal/presentation contract
- CONTENT — resource validation
- DOCS — documentation updated
- REGRESSION — previous smoke scenario still passes

## Explicit project anti-patterns

Do not:
- implement a card by adding `if card.id == ...` in UI;
- make tween completion modify combat result;
- use global `randi()` for run-affecting decisions;
- let CardView remove itself from the player's hand model;
- couple combo detection to label text or scene node names;
- hardwire final artwork dimensions into gameplay;
- replace stable IDs during cosmetic refactors;
- mark a gate complete without evidence.

## Recommended next invocation

```text
$unlazy tree 3 Build the first vertical-slice battle table:
- reusable CardView;
- HandView fan layout;
- steampunk mechanical placeholder HUD;
- enemy row + player row;
- play/inspect intent signals;
- no gameplay ownership in UI;
- deterministic test/debug scenario;
- update README and GATES.md;
- reverify all runnable gates.
```
