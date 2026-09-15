extends Node

## Deterministic manual QA: explicit fixture changes belong only in this scene.
func _ready() -> void:
	var options: Dictionary = {}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--demo-") and "=" in argument:
			var parts := argument.split("=", true, 1)
			options[parts[0]] = parts[1]
	var dimensions := String(options.get("--demo-size", "1600x900")).split("x")
	var viewport_size := Vector2i(int(dimensions[0]), int(dimensions[1]))
	get_window().size = viewport_size
	get_tree().root.content_scale_size = viewport_size
	LocalizationManager.set_locale(options.get("--demo-locale", "ru"), false)
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	var flow := main.get("flow_view") as DemoFlowView
	if options.has("--demo-motion-time"):
		flow.set_process(false)
	await get_tree().process_frame
	var demo := main.get("demo") as DemoRunController
	var view: String = options.get("--demo-view", "battle")
	if view != "choice":
		demo.choose_vice(StringName(options.get("--demo-vice", "obsession")))
		var kick := CardDatabase.get_card(&"grave_kick")
		var guard := CardDatabase.get_card(&"bone_guard")
		var curse := CardDatabase.get_card(&"hangover")
		demo.battle.hand = [kick, guard, curse, kick, guard]
		demo.battle.turn_index = 1
		demo.battle.changed.emit()
		if view == "reward" or view == "complete":
			demo.battle.enemy_hp = 1
			demo.battle.play_card(kick)
			if view == "complete":
				demo.claim_reward(&"reinforce")
		elif view == "defeat":
			demo.battle.player_hp = 1
			demo.battle.end_turn()
		else:
			main.call("_preview_card", curse)
	if options.has("--demo-motion-time"):
		flow.set_process(false)
		flow.advance_visuals(float(options["--demo-motion-time"]))
	else:
		await get_tree().create_timer(DemoFlowView.ENTRANCE_DURATION).timeout
	for _frame in 8:
		await get_tree().process_frame
	if options.has("--demo-capture"):
		await RenderingServer.frame_post_draw
		var capture_path: String = options["--demo-capture"]
		var error := get_viewport().get_texture().get_image().save_png(capture_path)
		if error != OK:
			push_error("Demo capture failed: %s" % error)
		else:
			print("Demo visual captured: ", capture_path)
		get_tree().quit(0 if error == OK else 1)
