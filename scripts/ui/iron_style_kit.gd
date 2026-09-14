class_name IronStyleKit
extends RefCounted

enum FrameLevel { UTILITY, MECHANISM, UNIQUE }

const UTILITY_FRAME := preload("res://assets/ui/frame_utility.svg")
const MECHANISM_FRAME := preload("res://assets/ui/frame_mechanism.svg")
const UNIQUE_FRAME := preload("res://assets/ui/frame_unique.svg")
const SOOT_OVERLAY := preload("res://assets/ui/soot_overlay.svg")
const SCRATCHES_OVERLAY := preload("res://assets/ui/scratches_overlay.svg")
const GRIME_EDGES := preload("res://assets/ui/grime_edges.svg")
const VIGNETTE := preload("res://assets/ui/vignette.svg")

static func add_frame(target: Control, level: FrameLevel) -> void:
	var frame := NinePatchRect.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.texture = _frame_texture(level)
	frame.patch_margin_left = 18
	frame.patch_margin_top = 18
	frame.patch_margin_right = 18
	frame.patch_margin_bottom = 18
	frame.draw_center = false
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(frame)

static func add_wear(target: Control, opacity: float = 0.16) -> void:
	for texture in [SOOT_OVERLAY, SCRATCHES_OVERLAY, GRIME_EDGES]:
		var overlay := TextureRect.new()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_SCALE
		overlay.texture = texture
		overlay.modulate = Color(1.0, 1.0, 1.0, opacity)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		target.add_child(overlay)

static func add_vignette(target: Control) -> void:
	var overlay := TextureRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.texture = VIGNETTE
	overlay.modulate = Color(1.0, 1.0, 1.0, 0.26)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(overlay)

static func _frame_texture(level: FrameLevel) -> Texture2D:
	match level:
		FrameLevel.MECHANISM:
			return MECHANISM_FRAME
		FrameLevel.UNIQUE:
			return UNIQUE_FRAME
		_:
			return UTILITY_FRAME
