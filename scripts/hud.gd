extends CanvasLayer
## Top-left HUD: LEVEL, CAPTURES Y/Z, LIVES hearts, escape progress bar.

signal lives_changed(lives: int)
signal captures_changed(current: int, quota: int)

var level: int = 1
var captures: int = 0
var quota: int = 4
var lives: int = 3
var max_lives: int = 3

var _level_label: Label
var _captures_label: Label
var _escape_panel: Panel
var _escape_track: ColorRect
var _escape_fill: ColorRect
var _hearts: Array[Label] = []

func _ready() -> void:
	layer = 20
	_build()
	refresh()

func set_level(v: int) -> void:
	level = v
	refresh()

func set_captures(current: int, new_quota: int = -1) -> void:
	captures = current
	if new_quota >= 0:
		quota = new_quota
	captures_changed.emit(captures, quota)
	refresh()

func set_lives(v: int) -> void:
	lives = clampi(v, 0, max_lives)
	lives_changed.emit(lives)
	refresh()

func reset_for_level(new_level: int, new_quota: int) -> void:
	level = new_level
	quota = new_quota
	captures = 0
	lives = max_lives
	set_escape_time(-1.0)
	refresh()

func set_escape_time(seconds: float, duration: float = -1.0) -> void:
	if _escape_fill == null or _escape_panel == null:
		return
	if seconds < 0.0 or duration <= 0.0:
		_escape_panel.visible = false
		_escape_fill.size.x = 0.0
		return
	_escape_panel.visible = true
	var ratio := clampf(seconds / duration, 0.0, 1.0)
	_escape_fill.size = Vector2(_escape_track.size.x * ratio, _escape_track.size.y)
	if ratio < 0.25:
		_escape_fill.color = Color(0.92, 0.16, 0.14)
	elif ratio < 0.55:
		_escape_fill.color = Color(0.95, 0.62, 0.12)
	else:
		_escape_fill.color = Color(0.28, 0.82, 0.36)

func refresh() -> void:
	if _level_label:
		_level_label.text = "LEVEL %d" % level
	if _captures_label:
		_captures_label.text = "CAPTURES: %d / %d" % [captures, quota]
	for i in _hearts.size():
		_hearts[i].modulate = Color(1, 1, 1, 1) if i < lives else Color(1, 1, 1, 0.25)

func _build() -> void:
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var stack := VBoxContainer.new()
	stack.name = "TopLeft"
	stack.position = Vector2(24, 18)
	stack.add_theme_constant_override("separation", 8)
	root.add_child(stack)

	_level_label = Label.new()
	_level_label.name = "LevelLabel"
	_level_label.add_theme_font_size_override("font_size", 36)
	_level_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_level_label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.12))
	_level_label.add_theme_constant_override("outline_size", 6)
	stack.add_child(_level_label)

	var cap_panel := _panel(Vector2(220, 40))
	cap_panel.name = "CapturesPanel"
	stack.add_child(cap_panel)
	_captures_label = Label.new()
	_captures_label.name = "CapturesLabel"
	_captures_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_captures_label.offset_left = 12
	_captures_label.offset_right = -8
	_captures_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_captures_label.add_theme_font_size_override("font_size", 20)
	_captures_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	cap_panel.add_child(_captures_label)

	var lives_panel := _panel(Vector2(220, 74))
	lives_panel.name = "LivesPanel"
	stack.add_child(lives_panel)

	var lives_title := Label.new()
	lives_title.text = "LIVES"
	lives_title.position = Vector2(12, 4)
	lives_title.add_theme_font_size_override("font_size", 14)
	lives_title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	lives_panel.add_child(lives_title)

	var hearts_row := HBoxContainer.new()
	hearts_row.position = Vector2(12, 28)
	hearts_row.add_theme_constant_override("separation", 10)
	lives_panel.add_child(hearts_row)

	_hearts.clear()
	for i in max_lives:
		var heart := Label.new()
		heart.text = "❤"
		heart.add_theme_font_size_override("font_size", 26)
		heart.add_theme_color_override("font_color", Color(0.92, 0.18, 0.22))
		hearts_row.add_child(heart)
		_hearts.append(heart)

	_escape_panel = _panel(Vector2(220, 48))
	_escape_panel.name = "EscapeBar"
	_escape_panel.visible = false
	stack.add_child(_escape_panel)

	var escape_title := Label.new()
	escape_title.name = "EscapeCaption"
	escape_title.text = "ESCAPE"
	escape_title.position = Vector2(10, 2)
	escape_title.add_theme_font_size_override("font_size", 13)
	escape_title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.92))
	_escape_panel.add_child(escape_title)

	_escape_track = ColorRect.new()
	_escape_track.name = "EscapeTrack"
	_escape_track.position = Vector2(10, 24)
	_escape_track.size = Vector2(200, 16)
	_escape_track.color = Color(0.16, 0.16, 0.18, 1)
	_escape_panel.add_child(_escape_track)

	_escape_fill = ColorRect.new()
	_escape_fill.name = "EscapeFill"
	_escape_fill.position = Vector2.ZERO
	_escape_fill.size = Vector2(200, 16)
	_escape_fill.color = Color(0.28, 0.82, 0.36)
	_escape_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escape_track.add_child(_escape_fill)

func _panel(size: Vector2) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.1, 0.72)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	return p