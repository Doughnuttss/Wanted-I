extends Node3D
## Loads the Blender market square. Fixed angled camera — it never pans or follows.

const GLB_PATH := "res://assets/generated/market_square.glb"
## Walkable plaza in world X (east) and Z (south). Blender +Y is Godot -Z.
const PLAZA := Rect2(-10.2, -10.2, 20.4, 20.4)

var plaza_rect: Rect2 = PLAZA

func get_plaza_rect() -> Rect2:
	return plaza_rect

func _ready() -> void:
	_build_environment()
	_load_market()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.58, 0.80, 0.96)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.74, 0.76)
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.85
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52, 32, 0)
	sun.light_energy = 0.72
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)

func _load_market() -> void:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(ProjectSettings.globalize_path(GLB_PATH), state)
	if err != OK:
		push_error("Market square glTF failed to load (%s)" % err)
		_add_fallback_camera()
		return
	var scene := doc.generate_scene(state)
	scene.name = "MarketSquare"
	add_child(scene)
	var cam := _find_camera(scene)
	if cam == null:
		_add_fallback_camera()
		return
	cam.current = true

func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	for child in node.get_children():
		var found := _find_camera(child)
		if found:
			return found
	return null

func _add_fallback_camera() -> void:
	# Blender MarketCam (3.4, -18.5, 21.5) lens 32mm, Y-up conversion.
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.fov = rad_to_deg(2.0 * atan(24.0 / 64.0))
	cam.position = Vector3(3.4, 21.5, 18.5)
	cam.look_at(Vector3(0.0, 0.4, -0.2), Vector3.UP)
	cam.current = true
	add_child(cam)
