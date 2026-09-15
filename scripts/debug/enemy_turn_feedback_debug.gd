extends Node

func _ready() -> void:
	var options: Dictionary = {}
	for argument in OS.get_cmdline_user_args():
		if "=" in argument:
			var parts := argument.split("=", true, 1)
			options[parts[0]] = parts[1]
	var dimensions := Vector2i(1920, 1080) if options.get("--size", "compact") == "wide" else Vector2i(1280, 720)
	get_window().size = dimensions
	get_tree().root.content_scale_size = dimensions
	LocalizationManager.set_locale(options.get("--locale", "ru"), false)
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	var demo := main.get("demo") as DemoRunController
	var table := main.get("battle_table") as BattleTable
	demo.choose_vice(&"greed")
	await get_tree().process_frame
	var block := int(options.get("--block", "0"))
	demo.battle.hand.clear()
	demo.battle.player_block = block
	main.call("_refresh")
	table.end_turn_button.pressed.emit()
	if options.has("--capture"):
		table.enemy_turn_feedback.set_process(false)
		table.enemy_turn_feedback.advance_visuals(float(options.get("--time", "0.52")))
		await RenderingServer.frame_post_draw
		var error := get_viewport().get_texture().get_image().save_png(options["--capture"])
		print("Enemy turn frame captured: ", error)
		get_tree().quit(0 if error == OK else 1)
		return
	while is_inside_tree():
		await get_tree().create_timer(1.8).timeout
		demo.battle.player_hp = 30
		demo.battle.hand.clear()
		demo.battle.player_block = 20 if demo.battle.turn_index % 2 == 1 else 0
		main.call("_refresh")
		table.end_turn_button.pressed.emit()
