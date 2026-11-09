class_name CrowdNPC
extends Area2D
## Modular NPC: body scale/tint + extensible trait slots.

signal clicked(npc: CrowdNPC)

const BODY_W := 22.0
const BODY_H := 34.0

var is_target: bool = false
var is_decoy: bool = false
var traits: Dictionary = {} ## Slot -> trait id
var clothing: Color = Color(0.3, 0.5, 0.8)
var move_speed: float = 55.0
var plaza: Rect2 = Rect2(280, 120, 720, 480)
var _waypoint: Vector2 = Vector2.ZERO
var _body: ColorRect
var _head: ColorRect
var _hat: ColorRect
var _glasses: ColorRect
var _held: ColorRect
var _outline: ColorRect
var stunned: bool = false
var panic_t: float = 0.0
var fleeing: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = true
	input_pickable = true
	_ensure_visuals()
	_pick_waypoint()
	body_entered.connect(func(_b): pass)
	input_event.connect(_on_input_event)

func setup(p_traits: Dictionary, p_clothing: Color, p_plaza: Rect2, speed: float, rng: RandomNumberGenerator) -> void:
	traits = p_traits.duplicate()
	clothing = p_clothing
	plaza = p_plaza
	move_speed = speed
	# scale ±15% H / ±10% W
	var sx := 1.0 + rng.randf_range(-0.10, 0.10)
	var sy := 1.0 + rng.randf_range(-0.15, 0.15)
	scale = Vector2(sx, sy)
	_ensure_visuals()
	_apply_look()
	position = Vector2(
		rng.randf_range(plaza.position.x + 40, plaza.end.x - 40),
		rng.randf_range(plaza.position.y + 40, plaza.end.y - 40)
	)
	_pick_waypoint()

func has_trait(id: String) -> bool:
	for k in traits.keys():
		if traits[k] == id:
			return true
	return false

func shared_trait_count(other: Dictionary) -> int:
	var n := 0
	for slot in other.keys():
		if traits.has(slot) and traits[slot] == other[slot]:
			n += 1
	return n

func apply_hit_yank() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * Vector2(1.2, 0.6), 0.05)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
	await tw.finished
	queue_free()

func apply_false_alarm() -> void:
	stunned = true
	modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.5).timeout
	stunned = false
	modulate = Color.WHITE
	panic_t = 2.0

func sprint_to_exit() -> void:
	fleeing = true
	var center := plaza.get_center()
	var edges := [
		Vector2(position.x, plaza.position.y - 40),
		Vector2(position.x, plaza.end.y + 40),
		Vector2(plaza.position.x - 40, position.y),
		Vector2(plaza.end.x + 40, position.y),
	]
	var best: Vector2 = edges[0]
	var best_d: float = position.distance_squared_to(best)
	for e in edges:
		var d := position.distance_squared_to(e)
		if d < best_d:
			best_d = d
			best = e
	_waypoint = best
	move_speed *= 2.2

func _physics_process(delta: float) -> void:
	if stunned:
		return
	var spd := move_speed * (1.6 if panic_t > 0.0 else 1.0)
	if panic_t > 0.0:
		panic_t = maxf(0.0, panic_t - delta)
	if position.distance_to(_waypoint) < 8.0:
		if fleeing:
			queue_free()
			return
		_pick_waypoint()
	var dir := (_waypoint - position).normalized()
	position += dir * spd * delta
	position.x = clampf(position.x, plaza.position.x + 20, plaza.end.x - 20) if not fleeing else position.x
	position.y = clampf(position.y, plaza.position.y + 20, plaza.end.y - 20) if not fleeing else position.y

func _pick_waypoint() -> void:
	_waypoint = Vector2(
		randf_range(plaza.position.x + 30, plaza.end.x - 30),
		randf_range(plaza.position.y + 30, plaza.end.y - 30)
	)

func _ensure_visuals() -> void:
	if _body:
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(BODY_W, BODY_H)
	shape.shape = rect
	shape.position = Vector2(0, -BODY_H * 0.5)
	add_child(shape)

	_outline = ColorRect.new()
	_outline.size = Vector2(BODY_W + 4, BODY_H + 4)
	_outline.position = Vector2(-(BODY_W + 4) * 0.5, -(BODY_H + 4))
	_outline.color = Color(0.12, 0.12, 0.14)
	_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_outline)

	_body = ColorRect.new()
	_body.size = Vector2(BODY_W, BODY_H * 0.55)
	_body.position = Vector2(-BODY_W * 0.5, -BODY_H * 0.55)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)

	_head = ColorRect.new()
	_head.size = Vector2(16, 16)
	_head.position = Vector2(-8, -BODY_H)
	_head.color = Color(0.86, 0.7, 0.55)
	_head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_head)

	_hat = ColorRect.new()
	_hat.size = Vector2(20, 10)
	_hat.position = Vector2(-10, -BODY_H - 8)
	_hat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hat.visible = false
	add_child(_hat)

	_glasses = ColorRect.new()
	_glasses.size = Vector2(14, 5)
	_glasses.position = Vector2(-7, -BODY_H + 6)
	_glasses.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glasses.visible = false
	add_child(_glasses)

	_held = ColorRect.new()
	_held.size = Vector2(10, 12)
	_held.position = Vector2(BODY_W * 0.5 - 2, -BODY_H * 0.45)
	_held.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held.visible = false
	add_child(_held)

func _apply_look() -> void:
	_body.color = clothing
	_hat.visible = false
	_glasses.visible = false
	_held.visible = false
	for slot in traits.keys():
		var id: String = traits[slot]
		var col := TraitCatalog.color_of(id)
		match int(slot):
			TraitCatalog.Slot.HAT:
				_hat.visible = true
				_hat.color = col
			TraitCatalog.Slot.GLASSES:
				_glasses.visible = true
				_glasses.color = col
			TraitCatalog.Slot.HELD:
				_held.visible = true
				_held.color = col

func _on_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)