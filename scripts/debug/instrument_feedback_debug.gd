extends Node

var table: BattleTable

func _ready() -> void:
	var capture := ""
	var dimensions := Vector2i(1280, 720)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--instrument-capture="):
			capture = argument.trim_prefix("--instrument-capture=")
		if argument == "--instrument-wide":
			dimensions = Vector2i(1920, 1080)
	get_window().size = dimensions
	get_tree().root.content_scale_size = dimensions
	LocalizationManager.set_locale("ru", false)
	table = preload("res://scenes/battle/battle_table.tscn").instantiate() as BattleTable
	add_child(table)
	_show(3, 0)
	await get_tree().process_frame
	if not capture.is_empty():
		_show(1, 10)
		table.pressure_feedback.set_process(false)
		table.protection_feedback.set_process(false)
		table.pressure_feedback.advance_visuals(0.18)
		table.protection_feedback.advance_visuals(0.18)
		await RenderingServer.frame_post_draw
		var error := get_viewport().get_texture().get_image().save_png(capture)
		print("Instrument frame captured: ", error)
		get_tree().quit(0 if error == OK else 1)
		return
	while is_inside_tree():
		for values in [Vector2i(2, 5), Vector2i(1, 10), Vector2i(3, 0)]:
			await get_tree().create_timer(1.6).timeout
			_show(values.x, values.y)

func _show(pressure: int, protection: int) -> void:
	var guard := CardDatabase.get_card(&"bone_guard")
	table.render_battle([guard, guard], [true, true], 30, 30, protection, pressure, 3,
		48, 0, 1, "", 4, 0, [], ComboResult.new(), false, true)
