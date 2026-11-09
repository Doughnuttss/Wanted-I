extends Node2D
## Claw/net: click → 0.15s drop delay + floor reticle → resolve.

signal capture_resolved(hit_target: bool, npc: CrowdNPC)

const DROP_DELAY := 0.15
const HIT_RADIUS := 32.0

var enabled: bool = false
var busy: bool = false
var crowd: Node2D

var _reticle: Node2D
var _ring: Polygon2D
var _flash: ColorRect

func _ready() -> void:
	z_index = 40
	_build()

func bind_crowd(c: Node2D) -> void:
	crowd = c

func set_enabled(v: bool) -> void:
	enabled = v
	if not v and not busy and _reticle:
		_reticle.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or busy:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_drop_at(get_global_mouse_position())
		get_viewport().set_input_as_handled()

func _drop_at(world: Vector2) -> void:
	busy = true
	_reticle.visible = true
	_reticle.global_position = world
	_reticle.modulate = Color(1, 1, 0.4, 0.95)
	await get_tree().create_timer(DROP_DELAY).timeout
	var npc: CrowdNPC = null
	if crowd and crowd.has_method("get_npc_at_point"):
		npc = crowd.get_npc_at_point(world, HIT_RADIUS)
	var hit_target := npc != null and bool(npc.is_target)
	if hit_target:
		_reticle.modulate = Color(0.3, 1, 0.4, 1)
		await get_tree().create_timer(0.05).timeout
	elif npc != null:
		_reticle.modulate = Color(1, 0.2, 0.2, 1)
		await _flash_red()
	else:
		_reticle.modulate = Color(1, 1, 1, 0.55)
	capture_resolved.emit(hit_target, npc)
	await get_tree().create_timer(0.1).timeout
	_reticle.visible = false
	busy = false

func _flash_red() -> void:
	_flash.visible = true
	_flash.modulate = Color(1, 0, 0, 0.35)
	var tw := create_tween()
	tw.tween_property(_flash, "modulate:a", 0.0, 0.3)
	await tw.finished
	_flash.visible = false

func _build() -> void:
	_reticle = Node2D.new()
	_reticle.name = "Reticle"
	_reticle.visible = false
	add_child(_reticle)
	_ring = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * float(i) / 28.0
		pts.append(Vector2(cos(a), sin(a)) * HIT_RADIUS)
	_ring.polygon = pts
	_ring.color = Color(1, 1, 0.3, 0.4)
	_reticle.add_child(_ring)
	var cross_h := ColorRect.new()
	cross_h.size = Vector2(26, 3)
	cross_h.position = Vector2(-13, -1.5)
	cross_h.color = Color(1, 1, 0.55)
	cross_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticle.add_child(cross_h)
	var cross_v := ColorRect.new()
	cross_v.size = Vector2(3, 26)
	cross_v.position = Vector2(-1.5, -13)
	cross_v.color = Color(1, 1, 0.55)
	cross_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticle.add_child(cross_v)

	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 50
	add_child(flash_layer)
	_flash = ColorRect.new()
	_flash.name = "RedFlash"
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 0, 0, 1)
	_flash.visible = false
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(_flash)