extends CanvasLayer
## Wanted poster: center slam, then top-right only. Escape time lives on the HUD bar.

signal reveal_finished
signal escape_timeout

enum Phase { HIDDEN, SLAM, PINNED }

const SLAM_HOLD := 1.2
const SHRINK_DUR := 0.4
const CENTER_SCALE := 1.35
const PIN_SCALE := 0.55
const CENTER_POS := Vector2(640, 360)
const PIN_MARGIN := 16.0

var phase: Phase = Phase.HIDDEN
var escape_duration: float = 25.0
var escape_remaining: float = 25.0
var hunting: bool = false
var fast_mode: bool = false

var _root: Control
var _poster: Control
var _title: Label
var _face: ColorRect
var _trait_row: HBoxContainer

func _ready() -> void:
	layer = 30
	_build()
	hide_poster()

func _process(delta: float) -> void:
	if hunting and phase == Phase.PINNED:
		escape_remaining = maxf(0.0, escape_remaining - delta)
		_push_timer()
		if escape_remaining <= 0.0:
			hunting = false
			escape_timeout.emit()
	else:
		_push_timer()

func hide_poster() -> void:
	phase = Phase.HIDDEN
	hunting = false
	if _root:
		_root.visible = false

func play_reveal(duration: float = 25.0) -> void:
	escape_duration = duration
	escape_remaining = duration
	hunting = false
	phase = Phase.SLAM
	_root.visible = true
	_poster.pivot_offset = _poster.size * 0.5
	_poster.scale = Vector2(CENTER_SCALE, CENTER_SCALE)
	_poster.position = CENTER_POS - _poster.size * 0.5
	_poster.modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(0.05 if fast_mode else SLAM_HOLD).timeout
	if phase != Phase.SLAM:
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	var pin_pos := _pinned_position()
	tw.tween_property(_poster, "scale", Vector2(PIN_SCALE, PIN_SCALE), 0.05 if fast_mode else SHRINK_DUR)
	tw.parallel().tween_property(_poster, "position", pin_pos, 0.05 if fast_mode else SHRINK_DUR)
	await tw.finished
	phase = Phase.PINNED
	hunting = true
	_push_timer()
	reveal_finished.emit()


func apply_target_traits(traits: Dictionary, clothing: Color) -> void:
	reset_title()
	# Rebuild portrait colors from traits
	if _face:
		_face.color = Color(0.86, 0.7, 0.55)
	var portrait := _poster.get_node_or_null("Portrait")
	if portrait == null:
		# find panel child used as portrait — first Panel under poster after title
		for c in _poster.get_children():
			if c is Panel and c != _poster:
				portrait = c
				break
	# Direct chip / overlay updates via named nodes if present
	var beanie := _poster.find_child("Beanie", true, false)
	var glasses := _poster.find_child("GlassesBar", true, false)
	var shirt := _poster.find_child("Shirt", true, false)
	var stripe := _poster.find_child("Stripe", true, false)
	if shirt:
		shirt.color = clothing
	if stripe:
		stripe.color = Color(0.92, 0.92, 0.95)
	if beanie and traits.has(TraitCatalog.Slot.HAT):
		beanie.color = TraitCatalog.color_of(traits[TraitCatalog.Slot.HAT])
		beanie.visible = true
	if glasses and traits.has(TraitCatalog.Slot.GLASSES):
		glasses.color = TraitCatalog.color_of(traits[TraitCatalog.Slot.GLASSES])
		glasses.visible = true
	# Trait chips
	if _trait_row:
		var colors: Array[Color] = []
		for slot in [TraitCatalog.Slot.HAT, TraitCatalog.Slot.GLASSES, TraitCatalog.Slot.HELD]:
			if traits.has(slot):
				colors.append(TraitCatalog.color_of(traits[slot]))
		var i := 0
		for chip in _trait_row.get_children():
			if chip.get_child_count() > 0 and i < colors.size():
				chip.get_child(0).color = colors[i]
				i += 1

func stamp_escaped() -> void:
	hunting = false
	if _title:
		_title.text = "ESCAPED"
		_title.add_theme_color_override("font_color", Color(0.85, 0.15, 0.15))

func reset_title() -> void:
	if _title:
		_title.text = "SUSPECT WANTED"
		_title.add_theme_color_override("font_color", Color(0.75, 0.12, 0.12))

func _pinned_position() -> Vector2:
	# Pivot is the poster center, so position is center minus half the unscaled size.
	# Place the scaled poster in the top-right corner.
	var vp := get_viewport().get_visible_rect().size
	var visual := _poster.size * PIN_SCALE
	var center := Vector2(vp.x - PIN_MARGIN - visual.x * 0.5, PIN_MARGIN + visual.y * 0.5)
	return center - _poster.size * 0.5

func _push_timer() -> void:
	var main := get_parent()
	if main == null:
		return
	var hud := main.get_node_or_null("HUD")
	if hud and hud.has_method("set_escape_time"):
		if hunting and phase == Phase.PINNED:
			hud.set_escape_time(escape_remaining, escape_duration)
		else:
			hud.set_escape_time(-1.0)

func _build() -> void:
	_root = Control.new()
	_root.name = "PosterRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_poster = Panel.new()
	_poster.name = "Poster"
	_poster.size = Vector2(260, 340)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.88, 0.72)
	sb.border_color = Color(0.35, 0.28, 0.18)
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_width_top = 4
	sb.border_width_bottom = 4
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	_poster.add_theme_stylebox_override("panel", sb)
	_root.add_child(_poster)

	_title = Label.new()
	_title.text = "SUSPECT WANTED"
	_title.position = Vector2(8, 12)
	_title.size = Vector2(244, 40)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.clip_text = false
	_title.add_theme_font_size_override("font_size", 18)
	_title.add_theme_color_override("font_color", Color(0.75, 0.12, 0.12))
	_poster.add_child(_title)

	# Placeholder suspect portrait (orange beanie / glasses / blue stripes via blocks)
	var portrait := Panel.new()
	portrait.name = "Portrait"
	portrait.position = Vector2(40, 56)
	portrait.size = Vector2(180, 170)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.78, 0.82, 0.88)
	psb.border_color = Color(0.2, 0.2, 0.22)
	psb.border_width_left = 3
	psb.border_width_right = 3
	psb.border_width_top = 3
	psb.border_width_bottom = 3
	portrait.add_theme_stylebox_override("panel", psb)
	_poster.add_child(portrait)

	var beanie := ColorRect.new()
	beanie.name = "Beanie"
	beanie.position = Vector2(50, 12)
	beanie.size = Vector2(80, 28)
	beanie.color = Color(0.95, 0.45, 0.15)
	portrait.add_child(beanie)

	var head := ColorRect.new()
	head.position = Vector2(55, 36)
	head.size = Vector2(70, 70)
	head.color = Color(0.86, 0.7, 0.55)
	portrait.add_child(head)

	var glasses := ColorRect.new()
	glasses.name = "GlassesBar"
	glasses.position = Vector2(60, 58)
	glasses.size = Vector2(60, 14)
	glasses.color = Color(0.08, 0.08, 0.1)
	portrait.add_child(glasses)

	var shirt := ColorRect.new()
	shirt.name = "Shirt"
	shirt.position = Vector2(40, 110)
	shirt.size = Vector2(100, 48)
	shirt.color = Color(0.25, 0.45, 0.85)
	portrait.add_child(shirt)
	var stripe := ColorRect.new()
	stripe.name = "Stripe"
	stripe.position = Vector2(40, 126)
	stripe.size = Vector2(100, 10)
	stripe.color = Color(0.92, 0.92, 0.95)
	portrait.add_child(stripe)

	_face = head

	_trait_row = HBoxContainer.new()
	_trait_row.position = Vector2(28, 240)
	_trait_row.add_theme_constant_override("separation", 12)
	_poster.add_child(_trait_row)
	_add_trait_chip(Color(0.95, 0.45, 0.15))
	_add_trait_chip(Color(0.08, 0.08, 0.1))
	_add_trait_chip(Color(0.25, 0.45, 0.85))

func _add_trait_chip(c: Color) -> void:
	var box := ColorRect.new()
	box.custom_minimum_size = Vector2(56, 56)
	box.color = Color(0.85, 0.8, 0.65)
	_trait_row.add_child(box)
	var inner := ColorRect.new()
	inner.position = Vector2(10, 10)
	inner.size = Vector2(36, 36)
	inner.color = c
	box.add_child(inner)