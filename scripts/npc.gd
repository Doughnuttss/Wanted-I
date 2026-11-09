class_name CrowdNPC
extends Node3D
## Blockout NPC on the plaza. Plaza rect is world X and Z, in metres.

signal clicked(npc: CrowdNPC)

const FLOOR_Y := 0.16
const REF_WIDTH := 720.0

var is_target: bool = false
var is_decoy: bool = false
var traits: Dictionary = {}
var clothing: Color = Color(0.3, 0.5, 0.8)
var move_speed: float = 1.5
var plaza: Rect2 = Rect2(-10.2, -10.2, 20.4, 20.4)
var _waypoint: Vector2 = Vector2.ZERO
var _body: MeshInstance3D
var _head: MeshInstance3D
var _hat: MeshInstance3D
var _glasses: MeshInstance3D
var _held: MeshInstance3D
var stunned: bool = false
var panic_t: float = 0.0
var fleeing: bool = false

func setup(p_traits: Dictionary, p_clothing: Color, p_plaza: Rect2, speed: float, rng: RandomNumberGenerator) -> void:
	traits = p_traits.duplicate()
	clothing = p_clothing
	plaza = p_plaza
	move_speed = speed * plaza.size.x / REF_WIDTH
	var s := 1.0 + rng.randf_range(-0.1, 0.1)
	scale = Vector3(s, 1.0 + rng.randf_range(-0.12, 0.12), s)
	_ensure_visuals()
	_apply_look()
	var inset := _pad(40.0)
	position = Vector3(
		rng.randf_range(plaza.position.x + inset, plaza.end.x - inset),
		FLOOR_Y,
		rng.randf_range(plaza.position.y + inset, plaza.end.y - inset)
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
	tw.tween_property(self, "scale", scale * Vector3(1.15, 0.35, 1.15), 0.04)
	tw.tween_property(self, "position:y", FLOOR_Y + 1.4, 0.16)
	await tw.finished
	queue_free()

func apply_false_alarm() -> void:
	stunned = true
	var punch := scale
	var tw := create_tween()
	tw.tween_property(self, "scale", punch * Vector3(1.18, 0.82, 1.18), 0.06)
	tw.tween_property(self, "scale", punch, 0.12)
	await get_tree().create_timer(0.28).timeout
	stunned = false
	panic_t = 1.4

func sprint_to_exit() -> void:
	fleeing = true
	var here := Vector2(position.x, position.z)
	var center := plaza.get_center()
	var exits: Array[Vector2] = [
		Vector2(center.x, plaza.position.y - 2.4),
		Vector2(center.x, plaza.end.y + 2.4),
		Vector2(plaza.position.x - 2.4, center.y),
		Vector2(plaza.end.x + 2.4, center.y),
	]
	var best: Vector2 = exits[0]
	var best_d := here.distance_squared_to(best)
	for e in exits:
		var d := here.distance_squared_to(e)
		if d < best_d:
			best_d = d
			best = e
	_waypoint = best
	move_speed *= 2.2

func _physics_process(delta: float) -> void:
	if stunned or _body == null:
		return
	var spd := move_speed * (1.65 if panic_t > 0.0 else 1.0)
	if panic_t > 0.0:
		panic_t = maxf(0.0, panic_t - delta)
	var here := Vector2(position.x, position.z)
	if here.distance_to(_waypoint) < _pad(8.0):
		if fleeing:
			queue_free()
			return
		_pick_waypoint()
		return
	var dir := (_waypoint - here).normalized()
	here += dir * spd * delta
	if not fleeing:
		var inset := _pad(20.0)
		here.x = clampf(here.x, plaza.position.x + inset, plaza.end.x - inset)
		here.y = clampf(here.y, plaza.position.y + inset, plaza.end.y - inset)
	position = Vector3(here.x, FLOOR_Y, here.y)

func _pick_waypoint() -> void:
	var inset := _pad(30.0)
	_waypoint = Vector2(
		randf_range(plaza.position.x + inset, plaza.end.x - inset),
		randf_range(plaza.position.y + inset, plaza.end.y - inset)
	)

func _pad(pixels: float) -> float:
	return pixels * plaza.size.x / REF_WIDTH

func _ensure_visuals() -> void:
	if _body:
		return
	_body = _add_box("Body", Vector3(0.46, 0.72, 0.32), Vector3(0, 0.56, 0), clothing)
	_head = _add_box("Head", Vector3(0.34, 0.34, 0.34), Vector3(0, 1.12, 0), Color(0.86, 0.7, 0.55))
	_hat = _add_box("Hat", Vector3(0.42, 0.16, 0.42), Vector3(0, 1.36, 0), Color.WHITE)
	_hat.visible = false
	_glasses = _add_box("Glasses", Vector3(0.3, 0.07, 0.08), Vector3(0, 1.14, 0.16), Color.BLACK)
	_glasses.visible = false
	_held = _add_box("Held", Vector3(0.18, 0.24, 0.14), Vector3(0.34, 0.72, 0.08), Color.WHITE)
	_held.visible = false

func _apply_look() -> void:
	_set_color(_body, clothing)
	_hat.visible = false
	_glasses.visible = false
	_held.visible = false
	for slot in traits.keys():
		var id: String = traits[slot]
		var col := TraitCatalog.color_of(id)
		match int(slot):
			TraitCatalog.Slot.HAT:
				_hat.visible = true
				_set_color(_hat, col)
			TraitCatalog.Slot.GLASSES:
				_glasses.visible = true
				_set_color(_glasses, col)
			TraitCatalog.Slot.HELD:
				_held.visible = true
				_set_color(_held, col)

func _add_box(node_name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi

func _set_color(mi: MeshInstance3D, color: Color) -> void:
	var mat := mi.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = color
