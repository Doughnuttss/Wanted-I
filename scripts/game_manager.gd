extends Node
## GameManager: LEVEL_INTRO → POSTER_REVEAL → ACTIVE_HUNT → CAPTURE_RESOLVE → LEVEL_CLEAR / GAME_OVER

enum State { LEVEL_INTRO, POSTER_REVEAL, ACTIVE_HUNT, CAPTURE_RESOLVE, LEVEL_CLEAR, GAME_OVER }

@export var auto_start: bool = true
@export var start_level: int = 1

var state: State = State.LEVEL_INTRO
var level: int = 1
var hud: CanvasLayer
var poster: CanvasLayer
var crowd: Node
var claw: Node
var arena: Node
var _banner: Label
var _verdict: Label
var _verdict_band: ColorRect
var _home: Control
var _game_over: Control
var _busy_flow: bool = false
const VERDICT_HOLD := 0.75

func _ready() -> void:
	var main := get_parent()
	arena = main
	hud = main.get_node("HUD")
	poster = main.get_node("WantedPoster")
	crowd = main.get_node("Crowd")
	claw = main.get_node("Claw")
	claw.bind_crowd(crowd)
	claw.capture_resolved.connect(_on_capture_resolved)
	poster.reveal_finished.connect(_on_reveal_finished)
	poster.escape_timeout.connect(_on_escape_timeout)
	_build_banner()
	_build_verdict()
	_home = _build_overlay("CROWD SCAN PANIC", "Click to play", 70)
	_game_over = _build_overlay("GAME OVER", "Click to retry level", 85)
	_game_over.visible = false
	_home.gui_input.connect(_on_home_input)
	_game_over.gui_input.connect(_on_over_input)
	_home.visible = auto_start

func _unhandled_input(event: InputEvent) -> void:
	if state != State.GAME_OVER:
		return
	if event is InputEventMouseButton and event.pressed:
		_retry_level()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		_retry_level()
		get_viewport().set_input_as_handled()

func begin_run() -> void:
	if _home:
		_home.visible = false
	level = start_level
	await start_level_flow()

func _on_home_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_home.visible = false
		begin_run()

func _on_over_input(event: InputEvent) -> void:
	if state != State.GAME_OVER:
		return
	if event is InputEventMouseButton and event.pressed:
		_retry_level()

func start_level_flow() -> void:
	_busy_flow = true
	state = State.LEVEL_INTRO
	_hide_banner()
	hide_capture_feedback()
	claw.set_enabled(false)
	var cfg := DifficultyTables.for_level(level)
	hud.reset_for_level(level, int(cfg["quota"]))
	poster.reset_title()
	poster.hide_poster()
	var plaza: Rect2 = _plaza()
	crowd.spawn_level(cfg, plaza)
	_apply_poster_traits()
	await get_tree().create_timer(0.35).timeout
	state = State.POSTER_REVEAL
	_busy_flow = false
	await poster.play_reveal(float(cfg["escape_s"]))

func _on_reveal_finished() -> void:
	if state == State.GAME_OVER:
		return
	state = State.ACTIVE_HUNT
	claw.set_enabled(true)

func _on_escape_timeout() -> void:
	if state != State.ACTIVE_HUNT or _busy_flow:
		return
	_busy_flow = true
	state = State.CAPTURE_RESOLVE
	claw.set_enabled(false)
	poster.hunting = false
	poster.stamp_escaped()
	if crowd.target and is_instance_valid(crowd.target):
		crowd.target.sprint_to_exit()
	hud.set_lives(hud.lives - 1)
	await get_tree().create_timer(0.9).timeout
	if hud.lives <= 0:
		_enter_game_over()
		_busy_flow = false
		return
	await _next_wanted()
	_busy_flow = false

func _on_capture_resolved(hit_target: bool, npc: CrowdNPC) -> void:
	if state != State.ACTIVE_HUNT or _busy_flow:
		return
	_busy_flow = true
	state = State.CAPTURE_RESOLVE
	claw.set_enabled(false)
	poster.hunting = false
	if hit_target and npc and is_instance_valid(npc):
		show_capture_feedback(true)
		await get_tree().create_timer(VERDICT_HOLD).timeout
		hide_capture_feedback()
		crowd.remove_npc(npc)
		await npc.apply_hit_yank()
		crowd.scatter()
		hud.set_captures(hud.captures + 1)
		await get_tree().create_timer(0.15).timeout
		if hud.captures >= hud.quota:
			await _level_clear()
		else:
			await _next_wanted()
	elif npc != null and is_instance_valid(npc):
		show_capture_feedback(false)
		await npc.apply_false_alarm()
		await get_tree().create_timer(VERDICT_HOLD).timeout
		hide_capture_feedback()
		crowd.scatter(npc)
		hud.set_lives(hud.lives - 1)
		await get_tree().create_timer(0.15).timeout
		if hud.lives <= 0:
			_enter_game_over()
		else:
			state = State.ACTIVE_HUNT
			poster.hunting = true
			claw.set_enabled(true)
	else:
		await get_tree().create_timer(0.12).timeout
		state = State.ACTIVE_HUNT
		poster.hunting = true
		claw.set_enabled(true)
	_busy_flow = false

func _level_clear() -> void:
	state = State.LEVEL_CLEAR
	claw.set_enabled(false)
	poster.hunting = false
	poster.hide_poster()
	_show_banner("LEVEL CLEAR!", Color(0.95, 0.9, 0.3))
	await get_tree().create_timer(1.0).timeout
	level += 1
	_hide_banner()
	await start_level_flow()

func _next_wanted() -> void:
	var cfg := DifficultyTables.for_level(level)
	var plaza: Rect2 = _plaza()
	# Keep captures/lives; refresh crowd + poster
	var saved_captures: int = hud.captures
	var saved_lives: int = hud.lives
	crowd.spawn_level(cfg, plaza)
	hud.set_captures(saved_captures, int(cfg["quota"]))
	hud.set_lives(saved_lives)
	poster.reset_title()
	_apply_poster_traits()
	state = State.POSTER_REVEAL
	await poster.play_reveal(float(cfg["escape_s"]))

func _enter_game_over() -> void:
	state = State.GAME_OVER
	claw.set_enabled(false)
	poster.hunting = false
	if _game_over:
		_game_over.visible = true
	_show_banner("GAME OVER — click to RETRY LEVEL", Color(1.0, 0.35, 0.3))

func _retry_level() -> void:
	if state != State.GAME_OVER:
		return
	_hide_banner()
	if _game_over:
		_game_over.visible = false
	poster.reset_title()
	# Retry same level, restore lives
	call_deferred("_retry_deferred")

func _retry_deferred() -> void:
	await start_level_flow()

func _apply_poster_traits() -> void:
	if poster.has_method("apply_target_traits"):
		var clothing := Color(0.3, 0.5, 0.8)
		if crowd.target and is_instance_valid(crowd.target):
			clothing = crowd.target.clothing
		poster.apply_target_traits(crowd.target_traits, clothing)

func _plaza() -> Rect2:
	if arena.has_method("get_plaza_rect"):
		return arena.get_plaza_rect()
	return Rect2(280, 120, 720, 480)

func _build_banner() -> void:
	var layer := CanvasLayer.new()
	layer.name = "BannerLayer"
	layer.layer = 60
	add_child(layer)
	_banner = Label.new()
	_banner.name = "Banner"
	_banner.visible = false
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.position = Vector2(140, 300)
	_banner.size = Vector2(1000, 80)
	_banner.add_theme_font_size_override("font_size", 42)
	_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_banner.add_theme_constant_override("outline_size", 8)
	layer.add_child(_banner)

func _show_banner(text: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.visible = true

func _hide_banner() -> void:
	if _banner:
		_banner.visible = false

func _build_verdict() -> void:
	var layer := CanvasLayer.new()
	layer.name = "VerdictLayer"
	layer.layer = 55
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_verdict_band = ColorRect.new()
	_verdict_band.name = "VerdictBand"
	_verdict_band.visible = false
	_verdict_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_verdict_band.anchor_left = 0.0
	_verdict_band.anchor_right = 1.0
	_verdict_band.anchor_top = 0.5
	_verdict_band.anchor_bottom = 0.5
	_verdict_band.offset_top = -90
	_verdict_band.offset_bottom = 90
	_verdict_band.color = Color(0.02, 0.02, 0.03, 0.55)
	root.add_child(_verdict_band)
	_verdict = Label.new()
	_verdict.name = "Verdict"
	_verdict.visible = false
	_verdict.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_verdict.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_verdict.add_theme_font_size_override("font_size", 128)
	_verdict.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_verdict.add_theme_constant_override("outline_size", 18)
	_verdict.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_verdict)

func show_capture_feedback(correct: bool) -> void:
	if _verdict == null:
		return
	_verdict.text = "CORRECT" if correct else "WRONG"
	_verdict.add_theme_color_override(
		"font_color",
		Color(0.45, 1.0, 0.42) if correct else Color(1.0, 0.22, 0.16)
	)
	if _verdict_band:
		_verdict_band.color = Color(0.02, 0.08, 0.03, 0.5) if correct else Color(0.18, 0.02, 0.02, 0.55)
		_verdict_band.visible = true
	_verdict.visible = true

func hide_capture_feedback() -> void:
	if _verdict:
		_verdict.visible = false
	if _verdict_band:
		_verdict_band.visible = false

func _build_overlay(title: String, subtitle: String, layer_index: int) -> Control:
	var layer := CanvasLayer.new()
	layer.name = title.replace(" ", "")
	layer.layer = layer_index
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.06, 0.09, 0.8)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(140, 250)
	title_label.size = Vector2(1000, 72)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 60)
	title_label.add_theme_color_override("font_color", Color(0.97, 0.9, 0.45))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title_label.add_theme_constant_override("outline_size", 10)
	root.add_child(title_label)
	var sub_label := Label.new()
	sub_label.text = subtitle
	sub_label.position = Vector2(140, 336)
	sub_label.size = Vector2(1000, 40)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 28)
	sub_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	root.add_child(sub_label)
	return root