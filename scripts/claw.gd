extends Node3D
## Click the plaza. The claw resolves almost immediately against the nearest NPC.

signal capture_resolved(hit_target: bool, npc: CrowdNPC)

const DROP_DELAY := 0.03
const HIT_RADIUS := 1.15
const FLOOR_Y := 0.2

var enabled: bool = false
var busy: bool = false
var crowd: Node

var _reticle: MeshInstance3D
var _flash: ColorRect

func _ready() -> void:
	_build()

func bind_crowd(c: Node) -> void:
	crowd = c

func set_enabled(v: bool) -> void:
	enabled = v
	if not v and not busy and _reticle:
		_reticle.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or busy:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var ground: Vector2 = _ground_point(event.position)
		if not ground.is_finite():
			return
		_drop_at(ground)
		get_viewport().set_input_as_handled()

func _drop_at(world: Vector2) -> void:
	busy = true
	_reticle.visible = true
	_reticle.global_position = Vector3(world.x, FLOOR_Y, world.y)
	await get_tree().create_timer(DROP_DELAY).timeout
	var npc: CrowdNPC = null
	if crowd and crowd.has_method("get_npc_at_point"):
		npc = crowd.get_npc_at_point(world, HIT_RADIUS)
	var hit_target := npc != null and bool(npc.is_target)
	if npc != null and not hit_target:
		await _flash_red()
	capture_resolved.emit(hit_target, npc)
	await get_tree().create_timer(0.08).timeout
	_reticle.visible = false
	busy = false

func _ground_point(screen: Vector2) -> Vector2:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return Vector2(INF, INF)
	var origin := cam.project_ray_origin(screen)
	var dir := cam.project_ray_normal(screen)
	if absf(dir.y) < 0.0001:
		return Vector2(INF, INF)
	var t := (FLOOR_Y - origin.y) / dir.y
	if t < 0.0:
		return Vector2(INF, INF)
	var hit := origin + dir * t
	return Vector2(hit.x, hit.z)

func _flash_red() -> void:
	_flash.visible = true
	_flash.modulate = Color(1, 0, 0, 0.35)
	var tw := create_tween()
	tw.tween_property(_flash, "modulate:a", 0.0, 0.22)
	await tw.finished
	_flash.visible = false

func _build() -> void:
	_reticle = MeshInstance3D.new()
	_reticle.name = "Reticle"
	var mesh := CylinderMesh.new()
	mesh.top_radius = HIT_RADIUS
	mesh.bottom_radius = HIT_RADIUS
	mesh.height = 0.05
	_reticle.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.92, 0.25, 0.85)
	mat.roughness = 1.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_reticle.material_override = mat
	_reticle.visible = false
	add_child(_reticle)

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
