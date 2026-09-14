# Gates: vertical-slice battle table

This is a TEMPLATE. Review every CHECK before approving execution.

- [ ] G1: Existing gameplay smoke scenario still passes.
  CHECK: <PROJECT_GODOT> --headless --path . res://tests/battle_smoke_test.tscn
  EXPECT: battle smoke test passed
  EVIDENCE: pending

- [ ] G2: CardView can render a CardData fixture without owning gameplay state.
  CHECK: <PROJECT_GODOT> --headless --path . res://tests/card_view_contract_test.tscn
  EXPECT: card view contract passed
  EVIDENCE: pending

- [ ] G3: CardView emits play/inspect intent and does not resolve effects directly.
  CHECK: <PROJECT_GODOT> --headless --path . res://tests/card_view_intent_test.tscn
  EXPECT: card intent contract passed
  EVIDENCE: pending

- [ ] G4: HandView presents the same fixture hand in deterministic card order.
  CHECK: <PROJECT_GODOT> --headless --path . res://tests/hand_view_contract_test.tscn
  EXPECT: hand view contract passed
  EVIDENCE: pending

- [ ] G5: Gameplay RNG remains isolated from presentation.
  CHECK: <PROJECT_GODOT> --headless --path . res://tests/rng_isolation_test.tscn
  EXPECT: rng isolation passed
  EVIDENCE: pending

- [ ] G6: BattleTable manual visual check.
  MANUAL: Open the deterministic UI debug scene at 1920x1080 and 1600x900. Verify cards remain readable; hand does not overlap HP/energy/end-turn controls; player selection feedback uses restrained cyan/teal; danger feedback remains red; no core interaction requires final art assets.
  EVIDENCE: pending

- [ ] G7: Documentation matches final architecture and controls.
  MANUAL: README.md and AGENTS.md describe the implemented scene names, signals, controls, and any new terminology.
  EVIDENCE: pending
