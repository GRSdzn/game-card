extends Node

## Persistent state for a run. This is intentionally small at the scaffold stage.
signal run_started(seed_text: String)
signal run_changed

var seed_text: String = ""
var rng := RandomNumberGenerator.new()
var player_hp: int = 30
var max_hp: int = 30
var gold: int = 0
var floor_index: int = 0
var weakness_ids: Array[StringName] = []
var starter_deck: Array[StringName] = [
	"grave_kick", "grave_kick", "grave_kick",
	"bone_guard", "bone_guard",
	"hangover",
]
var starter_weaknesses: Array[StringName] = []

func start_new_run(custom_seed: String = "") -> void:
	seed_text = custom_seed.strip_edges()
	if seed_text.is_empty():
		seed_text = "%08X" % Time.get_ticks_usec()
	rng.seed = seed_text.hash()
	player_hp = max_hp
	gold = 0
	floor_index = 0
	weakness_ids = starter_weaknesses.duplicate()
	run_started.emit(seed_text)
	run_changed.emit()

func roll_int(min_value: int, max_value: int) -> int:
	return rng.randi_range(min_value, max_value)

func save_rng_state() -> int:
	return rng.state

func restore_rng_state(value: int) -> void:
	rng.state = value
