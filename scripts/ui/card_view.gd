class_name CardView
extends Control

signal play_requested(card_data: CardData)
signal inspect_requested(card_data: CardData)
signal preview_requested(card_data: CardData)

const CARD_SIZE := Vector2(142, 214)
const HOVER_LIFT := -30.0
const PARCHMENT_TEXTURE := preload("res://assets/ui/dirty_parchment_01.svg")
const SUIT_ART_TEXTURES := [
	preload("res://assets/ui/card_bone.svg"),
	preload("res://assets/ui/card_blood.svg"),
	preload("res://assets/ui/card_flesh.svg"),
	preload("res://assets/ui/card_spirit.svg"),
	preload("res://assets/ui/card_gold.svg"),
]

var card_data: CardData
var is_playable: bool = false
var is_selected: bool = false
var is_hovered: bool = false
var base_z_index: int = 0
var presentation_tween: Tween
var art_image: TextureRect
var card_shadow: Panel

@onready var card_frame: Panel = %CardFrame
@onready var art_placeholder: Panel = %ArtPlaceholder
@onready var title_label: Label = %TitleLabel
@onready var cost_label: Label = %CostLabel
@onready var suit_label: Label = %SuitLabel
@onready var rank_label: Label = %RankLabel
@onready var description_label: Label = %DescriptionLabel
@onready var tags_label: Label = %TagsLabel
@onready var state_label: Label = %StateLabel

func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	pivot_offset = CARD_SIZE * 0.5
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	LocalizationManager.locale_changed.connect(_on_locale_changed)
	_add_art_material()
	_add_card_depth()
	_update_presentation(true)

func display_card(new_card_data: CardData, playable: bool) -> void:
	card_data = new_card_data
	is_playable = playable
	is_selected = false
	_update_presentation(true)

func set_selected(value: bool) -> void:
	is_selected = value
	_update_presentation(false)

func set_base_z_index(value: int) -> void:
	base_z_index = value
	if not is_hovered:
		z_index = base_z_index

func _on_mouse_entered() -> void:
	is_hovered = true
	z_index = 100
	_update_presentation(false)
	preview_requested.emit(card_data)

func _on_mouse_exited() -> void:
	is_hovered = false
	z_index = base_z_index
	_update_presentation(false)
	preview_requested.emit(null)

func _on_gui_input(event: InputEvent) -> void:
	if card_data == null or not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		set_selected(true)
		if is_playable:
			play_requested.emit(card_data)
		accept_event()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		inspect_requested.emit(card_data)
		accept_event()

func _update_presentation(instant: bool) -> void:
	if not is_node_ready():
		return
	if card_data == null:
		title_label.text = LocalizationManager.translate(&"CARD_UNASSIGNED")
		return
	title_label.text = card_data.get_title()
	cost_label.text = LocalizationManager.translate(&"CARD_COST", {"cost": card_data.cost})
	suit_label.text = card_data.suit_name().to_upper()
	rank_label.text = LocalizationManager.translate(&"CARD_RANK", {"rank": card_data.rank})
	description_label.text = _effect_summary(card_data.effects)
	tags_label.visible = false
	state_label.text = LocalizationManager.translate(&"CARD_READY") if is_playable else LocalizationManager.translate(&"CARD_LOCKED")
	tooltip_text = "%s\n%s" % [card_data.get_title(), card_data.get_description()]
	state_label.modulate = Color("9bd2c7") if is_playable else Color("9a7960")
	card_frame.modulate = Color.WHITE if is_playable else Color(0.55, 0.49, 0.42, 1.0)

	var frame_style := _make_frame_style()
	var art_style := _make_art_style()
	card_frame.add_theme_stylebox_override("panel", frame_style)
	art_placeholder.add_theme_stylebox_override("panel", art_style)
	if art_image != null:
		art_image.texture = _art_texture()
	title_label.max_lines_visible = 2
	description_label.max_lines_visible = 2
	var target_position := Vector2(0.0, HOVER_LIFT if is_hovered else 0.0)
	var target_scale := Vector2.ONE * (1.045 if is_hovered else 1.0)
	if card_shadow != null:
		card_shadow.position = Vector2(6.0, 12.0) if is_hovered else Vector2(4.0, 8.0)
	if instant:
		card_frame.position = target_position
		scale = target_scale
		return
	if presentation_tween != null and presentation_tween.is_running():
		presentation_tween.kill()
	presentation_tween = create_tween().set_parallel(true)
	presentation_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	presentation_tween.tween_property(card_frame, "position", target_position, 0.14)
	presentation_tween.tween_property(self, "scale", target_scale, 0.14)

func _make_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("201b17")
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	style.border_color = Color("66c7c1") if is_playable and (is_selected or is_hovered) else Color("8a6030")
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.72)
	style.shadow_size = 11
	style.shadow_offset = Vector2(2, 7)
	style.content_margin_left = 12
	style.content_margin_top = 12
	style.content_margin_right = 12
	style.content_margin_bottom = 12
	return style

func _make_art_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _suit_art_color()
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("a1763c")
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style

func _add_art_material() -> void:
	var grain := TextureRect.new()
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grain.stretch_mode = TextureRect.STRETCH_TILE
	grain.texture = PARCHMENT_TEXTURE
	grain.modulate = Color(1.0, 1.0, 1.0, 0.25)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_placeholder.add_child(grain)
	art_image = TextureRect.new()
	art_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
	art_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_image.modulate = Color(1.0, 1.0, 1.0, 0.90)
	art_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_placeholder.add_child(art_image)

func _add_card_depth() -> void:
	card_shadow = Panel.new()
	card_shadow.position = Vector2(4.0, 8.0)
	card_shadow.size = CARD_SIZE
	card_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.0, 0.0, 0.0, 0.54)
	shadow_style.corner_radius_top_left = 6
	shadow_style.corner_radius_top_right = 6
	shadow_style.corner_radius_bottom_right = 6
	shadow_style.corner_radius_bottom_left = 6
	shadow_style.shadow_color = Color(0.0, 0.0, 0.0, 0.82)
	shadow_style.shadow_size = 12
	shadow_style.shadow_offset = Vector2(2, 7)
	card_shadow.add_theme_stylebox_override("panel", shadow_style)
	add_child(card_shadow)
	move_child(card_shadow, 0)
	var stock := TextureRect.new()
	stock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stock.stretch_mode = TextureRect.STRETCH_TILE
	stock.texture = PARCHMENT_TEXTURE
	stock.modulate = Color(0.72, 0.54, 0.34, 0.13)
	stock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_frame.add_child(stock)
	card_frame.move_child(stock, 0)

func _suit_art_color() -> Color:
	if card_data == null:
		return Color("3a2c24")
	var colors := [Color("453228"), Color("482625"), Color("40322b"), Color("2a3d3b"), Color("4a3a23")]
	return colors[clampi(card_data.suit, 0, colors.size() - 1)]

func _art_texture() -> Texture2D:
	if card_data != null and not card_data.art_path.is_empty():
		var generated_art := ResourceLoader.load(card_data.art_path) as Texture2D
		if generated_art != null:
			return generated_art
	if card_data == null:
		return SUIT_ART_TEXTURES[0]
	return SUIT_ART_TEXTURES[clampi(card_data.suit, 0, SUIT_ART_TEXTURES.size() - 1)]

func _effect_summary(effects: Array[EffectData]) -> String:
	if effects.is_empty():
		return LocalizationManager.translate(&"CARD_NO_EFFECT")
	var lines: PackedStringArray = []
	for effect in effects:
		lines.append(effect.describe())
	return " + ".join(lines)

func _on_locale_changed(_locale: String) -> void:
	_update_presentation(true)
