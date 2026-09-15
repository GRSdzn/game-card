extends Node

## Fixed hand/HP fixtures are confined to this manual review scene.
func _ready() -> void:
	var options: Dictionary = {}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--") and "=" in argument:
			var parts := argument.split("=", true, 1)
			options[parts[0]] = parts[1]
	var dimensions := String(options.get("--size", "1280x720")).split("x")
	get_window().size = Vector2i(int(dimensions[0]), int(dimensions[1]))
	get_tree().root.content_scale_size = get_window().size
	LocalizationManager.set_locale(options.get("--locale", "ru"), false)
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	var demo := main.get("demo") as DemoRunController
	var table := main.get("battle_table") as BattleTable
	demo.choose_vice(&"greed")
	var curse := CardDatabase.get_card(&"hangover")
	var guard := CardDatabase.get_card(&"bone_guard")
	demo.battle.hand = [curse, guard, guard, curse, CardDatabase.get_card(&"grave_kick")]
	if options.get("--mode", "ready") == "lethal":
		demo.battle.player_hp = 3
	demo.battle.changed.emit()
	await get_tree().process_frame
	var mode: String = options.get("--mode", "ready")
	if mode in ["overload", "seal"]:
		table.machine_buttons[1].pressed.emit()
		demo.battle.play_card(curse)
		if mode == "seal":
			table.score_button.pressed.emit()
	elif mode == "vent":
		table.machine_buttons[0].pressed.emit()
	if options.has("--capture"):
		table.machine_feedback.set_process(false)
		table.pressure_feedback.set_process(false)
		table.protection_feedback.set_process(false)
		var sample := float(options.get("--time", "0.18"))
		table.machine_feedback.advance_visuals(sample)
		table.machine_feedback.set_process(false)
		table.pressure_feedback.advance_visuals(sample)
		table.protection_feedback.advance_visuals(sample)
		for _frame in 5:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var error := get_viewport().get_texture().get_image().save_png(options["--capture"])
		print("Machine frame captured: ", error)
		get_tree().quit(0 if error == OK else 1)
