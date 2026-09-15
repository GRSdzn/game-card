class_name DemoFlowView
extends Control

## A document tray: presentation and user intent only.
signal choice_requested(kind: StringName, id: StringName)
enum Outcome { NONE, VICTORY, DEFEAT }
var tray: PanelContainer
var result_stamp: Label
var heading: Label
var subtitle: Label
var choices_box: VBoxContainer
var choice_buttons: Array[Button] = []
var shade: ColorRect
var _screen_id: StringName = &""
var _entrance_time: float = 0.0
var _shade_start: float = 0.0
const ENTRANCE_DURATION: float = 0.4

func _ready() -> void:
	z_index = 200
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process(false)
	shade = ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.018, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	tray = PanelContainer.new()
	tray.set_anchors_preset(Control.PRESET_CENTER)
	tray.offset_left = -350
	tray.offset_right = 350
	tray.offset_top = -248
	tray.offset_bottom = 248
	var metal := StyleBoxFlat.new()
	metal.bg_color = Color("171817")
	metal.set_border_width_all(4)
	metal.border_color = Color("65451f")
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		metal.set_content_margin(side, 16)
	tray.add_theme_stylebox_override("panel", metal)
	add_child(tray)
	var texture := TextureRect.new()
	texture.texture = preload("res://assets/ui/black_iron_01.svg")
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_TILE
	texture.modulate.a = 0.2
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(texture)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	var inset := MarginContainer.new()
	for margin in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inset.add_theme_constant_override(margin, 16)
	tray.add_child(inset)
	inset.add_child(column)
	result_stamp = _label(42)
	result_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_stamp.add_theme_color_override("font_outline_color", Color("0d0e0d"))
	result_stamp.add_theme_constant_override("outline_size", 4)
	result_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_stamp.visible = false
	column.add_child(result_stamp)
	heading = _label(23)
	column.add_child(heading)
	subtitle = _label(15)
	column.add_child(subtitle)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 12)
	column.add_child(choices_box)
	IronStyleKit.add_wear(tray, 0.08)
	IronStyleKit.add_frame(tray, IronStyleKit.FrameLevel.UTILITY)
	var language := Button.new()
	language.text = "EN / РУ"
	language.position = Vector2(28, 48)
	language.pressed.connect(func() -> void:
		LocalizationManager.set_locale("ru" if LocalizationManager.current_locale == "en" else "en")
	)
	add_child(language)

func present(title: String, body: String, choices: Array[Dictionary], screen_id: StringName = &"", outcome: Outcome = Outcome.NONE) -> void:
	var next_id := screen_id if not screen_id.is_empty() else StringName(title)
	var entering := not visible or next_id != _screen_id
	if entering:
		_shade_start = shade.modulate.a if visible else 0.0
	_screen_id = next_id
	visible = true
	result_stamp.visible = outcome != Outcome.NONE
	if result_stamp.visible:
		var result_key: StringName = &"BATTLE_RESULT_VICTORY" if outcome == Outcome.VICTORY else &"BATTLE_RESULT_DEFEAT"
		result_stamp.text = LocalizationManager.translate(result_key)
		result_stamp.add_theme_color_override("font_color", Color("e0a04a") if outcome == Outcome.VICTORY else Color("d15a4d"))
	heading.text = title
	subtitle.text = body
	for child in choices_box.get_children():
		choices_box.remove_child(child)
		child.queue_free()
	choice_buttons.clear()
	for choice in choices:
		var button := Button.new()
		button.text = choice["title"]
		button.custom_minimum_size.y = 42
		button.add_theme_font_size_override("font_size", 18)
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("261a13")
			style.set_border_width_all(2)
			style.border_color = Color("8b612c") if state == "normal" else Color("589c9e")
			button.add_theme_stylebox_override(state, style)
		button.add_theme_color_override("font_color", Color("d0b784"))
		button.pressed.connect(func() -> void: choice_requested.emit(choice["kind"], choice["id"]))
		choices_box.add_child(button)
		choice_buttons.append(button)
		if not String(choice.get("description", "")).is_empty():
			var description := _label(15)
			description.text = choice["description"]
			choices_box.add_child(description)
	if entering:
		_entrance_time = 0.0
		advance_visuals(0.0)
		set_process(true)

func dismiss() -> void:
	visible = false
	_screen_id = &""
	set_process(false)

func _process(delta: float) -> void:
	advance_visuals(delta)

## Presentation clock also allows reproducible samples in the debug scene.
func advance_visuals(delta: float) -> void:
	_entrance_time = minf(_entrance_time + maxf(delta, 0.0), ENTRANCE_DURATION)
	var background_t := clampf(_entrance_time / 0.28, 0.0, 1.0)
	var panel_t := clampf((_entrance_time - 0.04) / 0.36, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - panel_t, 3.0)
	shade.modulate.a = lerpf(_shade_start, 1.0, background_t * background_t * (3.0 - 2.0 * background_t))
	tray.modulate.a = panel_t * panel_t * (3.0 - 2.0 * panel_t)
	var travel := 18.0 * (1.0 - eased)
	tray.offset_top = -248.0 + travel
	tray.offset_bottom = 248.0 + travel
	if _entrance_time >= ENTRANCE_DURATION:
		set_process(false)

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("d0b784"))
	return label
