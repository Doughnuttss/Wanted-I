extends Node2D
## Crowd Scan Panic — arena slice (plaza, stalls, exits, Y-sort props).

const VIEW := Vector2(1280, 720)
const PLAZA_SIZE := Vector2(720, 480)
const WALL_THICK := 28.0
const EXIT_GAP := 120.0
const STALL_SIZE := Vector2(72, 96)

var plaza_rect: Rect2

func get_plaza_rect() -> Rect2:
	return plaza_rect

func _ready() -> void:
	_build_world()

func _build_world() -> void:
	var center := VIEW * 0.5
	plaza_rect = Rect2(center - PLAZA_SIZE * 0.5, PLAZA_SIZE)

	_add_rect("Grass", Rect2(Vector2.ZERO, VIEW), Color(0.45, 0.62, 0.38), -100)

	# Exit paths beyond the four openings
	_add_rect("PathN", Rect2(center.x - EXIT_GAP * 0.5, 0, EXIT_GAP, plaza_rect.position.y), Color(0.72, 0.72, 0.7), -90)
	_add_rect("PathS", Rect2(center.x - EXIT_GAP * 0.5, plaza_rect.end.y, EXIT_GAP, VIEW.y - plaza_rect.end.y), Color(0.72, 0.72, 0.7), -90)
	_add_rect("PathW", Rect2(0, center.y - EXIT_GAP * 0.5, plaza_rect.position.x, EXIT_GAP), Color(0.72, 0.72, 0.7), -90)
	_add_rect("PathE", Rect2(plaza_rect.end.x, center.y - EXIT_GAP * 0.5, VIEW.x - plaza_rect.end.x, EXIT_GAP), Color(0.72, 0.72, 0.7), -90)

	# Cobble plaza floor
	_add_rect("PlazaFloor", plaza_rect, Color(0.62, 0.62, 0.6), -80)
	_add_rect("PlazaCenter", Rect2(center - Vector2(90, 60), Vector2(180, 120)), Color(0.74, 0.73, 0.7), -79)

	# Perimeter walls with N/S/E/W exit gaps
	_build_walls(plaza_rect, center)

	# Soft tree blobs outside plaza (decorative)
	_add_blob("TreeNW", Vector2(110, 90), 48, Color(0.28, 0.5, 0.28))
	_add_blob("TreeNE", Vector2(1170, 100), 52, Color(0.55, 0.55, 0.22))
	_add_blob("TreeSW", Vector2(130, 640), 46, Color(0.7, 0.45, 0.2))
	_add_blob("TreeSE", Vector2(1150, 630), 50, Color(0.3, 0.52, 0.3))

	var ysort := Node2D.new()
	ysort.name = "YSort"
	ysort.y_sort_enabled = true
	ysort.z_index = 10
	add_child(ysort)

	# Two central stalls / pillars (awning + pillar)
	_add_stall(ysort, "StallWest", center + Vector2(-130, -10))
	_add_stall(ysort, "StallEast", center + Vector2(130, -10))

	# Benches along walls
	_add_bench(ysort, "BenchN1", Vector2(center.x - 180, plaza_rect.position.y + 36))
	_add_bench(ysort, "BenchN2", Vector2(center.x + 180, plaza_rect.position.y + 36))
	_add_bench(ysort, "BenchS1", Vector2(center.x - 180, plaza_rect.end.y - 36))
	_add_bench(ysort, "BenchS2", Vector2(center.x + 180, plaza_rect.end.y - 36))

	# Crates
	_add_crate(ysort, "Crate1", Vector2(plaza_rect.position.x + 70, plaza_rect.position.y + 90), Color(0.55, 0.38, 0.22))
	_add_crate(ysort, "Crate2", Vector2(plaza_rect.position.x + 100, plaza_rect.position.y + 110), Color(0.35, 0.45, 0.65))
	_add_crate(ysort, "Crate3", Vector2(plaza_rect.end.x - 90, plaza_rect.position.y + 100), Color(0.7, 0.4, 0.25))
	_add_crate(ysort, "Crate4", Vector2(plaza_rect.position.x + 80, plaza_rect.end.y - 90), Color(0.55, 0.38, 0.22))
	_add_crate(ysort, "Crate5", Vector2(plaza_rect.end.x - 100, plaza_rect.end.y - 100), Color(0.35, 0.45, 0.65))

	# Potted plants
	_add_plant(ysort, "PlantSW", center + Vector2(-90, 70))
	_add_plant(ysort, "PlantSE", center + Vector2(90, 70))
	_add_plant(ysort, "PlantNW", Vector2(plaza_rect.position.x + 140, plaza_rect.position.y + 140))
	_add_plant(ysort, "PlantNE", Vector2(plaza_rect.end.x - 140, plaza_rect.position.y + 140))

	# Exit markers (readable labels for slice)
	_add_exit_label("ExitN", Vector2(center.x, plaza_rect.position.y - 18), "EXIT")
	_add_exit_label("ExitS", Vector2(center.x, plaza_rect.end.y + 18), "EXIT")
	_add_exit_label("ExitW", Vector2(plaza_rect.position.x - 28, center.y), "EXIT")
	_add_exit_label("ExitE", Vector2(plaza_rect.end.x + 28, center.y), "EXIT")

func _build_walls(plaza: Rect2, center: Vector2) -> void:
	var walls := Node2D.new()
	walls.name = "Walls"
	walls.z_index = 5
	add_child(walls)

	var c := Color(0.48, 0.48, 0.5)
	var half_gap := EXIT_GAP * 0.5

	# Top wall split
	_wall_seg(walls, "WallN_L", Rect2(plaza.position.x, plaza.position.y, (center.x - half_gap) - plaza.position.x, WALL_THICK), c)
	_wall_seg(walls, "WallN_R", Rect2(center.x + half_gap, plaza.position.y, plaza.end.x - (center.x + half_gap), WALL_THICK), c)
	# Bottom
	_wall_seg(walls, "WallS_L", Rect2(plaza.position.x, plaza.end.y - WALL_THICK, (center.x - half_gap) - plaza.position.x, WALL_THICK), c)
	_wall_seg(walls, "WallS_R", Rect2(center.x + half_gap, plaza.end.y - WALL_THICK, plaza.end.x - (center.x + half_gap), WALL_THICK), c)
	# Left
	_wall_seg(walls, "WallW_T", Rect2(plaza.position.x, plaza.position.y, WALL_THICK, (center.y - half_gap) - plaza.position.y), c)
	_wall_seg(walls, "WallW_B", Rect2(plaza.position.x, center.y + half_gap, WALL_THICK, plaza.end.y - (center.y + half_gap)), c)
	# Right
	_wall_seg(walls, "WallE_T", Rect2(plaza.end.x - WALL_THICK, plaza.position.y, WALL_THICK, (center.y - half_gap) - plaza.position.y), c)
	_wall_seg(walls, "WallE_B", Rect2(plaza.end.x - WALL_THICK, center.y + half_gap, WALL_THICK, plaza.end.y - (center.y + half_gap)), c)

func _wall_seg(parent: Node, n: String, r: Rect2, c: Color) -> void:
	var body := StaticBody2D.new()
	body.name = n
	body.position = r.position
	parent.add_child(body)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = r.size
	shape.shape = rect
	shape.position = r.size * 0.5
	body.add_child(shape)
	var vis := ColorRect.new()
	vis.size = r.size
	vis.color = c
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(vis)
	var outline := ColorRect.new()
	outline.size = Vector2(r.size.x, 3)
	outline.position = Vector2(0, r.size.y - 3)
	outline.color = Color(0.28, 0.28, 0.3)
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(outline)

func _add_rect(n: String, r: Rect2, c: Color, z: int) -> void:
	var node := ColorRect.new()
	node.name = n
	node.position = r.position
	node.size = r.size
	node.color = c
	node.z_index = z
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)

func _add_blob(n: String, pos: Vector2, radius: float, c: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = n
	poly.color = c
	poly.z_index = -70
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * float(i) / 10.0
		pts.append(pos + Vector2(cos(a), sin(a)) * radius * (0.85 + 0.15 * sin(i * 2.1)))
	poly.polygon = pts
	add_child(poly)

func _add_stall(parent: Node, n: String, pos: Vector2) -> void:
	var root := Node2D.new()
	root.name = n
	root.position = pos
	parent.add_child(root)
	# pillar
	var pillar := ColorRect.new()
	pillar.size = Vector2(40, 70)
	pillar.position = Vector2(-20, -70)
	pillar.color = Color(0.55, 0.55, 0.52)
	pillar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pillar)
	# awning
	var awning := ColorRect.new()
	awning.size = Vector2(70, 28)
	awning.position = Vector2(-35, -88)
	awning.color = Color(0.42, 0.28, 0.16)
	awning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(awning)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 70)
	shape.shape = rect
	shape.position = Vector2(0, -35)
	body.add_child(shape)
	root.add_child(body)

func _add_bench(parent: Node, n: String, pos: Vector2) -> void:
	var root := Node2D.new()
	root.name = n
	root.position = pos
	parent.add_child(root)
	var seat := ColorRect.new()
	seat.size = Vector2(70, 18)
	seat.position = Vector2(-35, -18)
	seat.color = Color(0.5, 0.5, 0.48)
	seat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(seat)

func _add_crate(parent: Node, n: String, pos: Vector2, c: Color) -> void:
	var root := Node2D.new()
	root.name = n
	root.position = pos
	parent.add_child(root)
	var box := ColorRect.new()
	box.size = Vector2(28, 28)
	box.position = Vector2(-14, -28)
	box.color = c
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)

func _add_plant(parent: Node, n: String, pos: Vector2) -> void:
	var root := Node2D.new()
	root.name = n
	root.position = pos
	parent.add_child(root)
	var pot := ColorRect.new()
	pot.size = Vector2(22, 18)
	pot.position = Vector2(-11, -18)
	pot.color = Color(0.7, 0.4, 0.28)
	pot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pot)
	var leaf := Polygon2D.new()
	leaf.color = Color(0.3, 0.62, 0.32)
	leaf.polygon = PackedVector2Array([
		Vector2(0, -42), Vector2(14, -18), Vector2(-14, -18)
	])
	root.add_child(leaf)

func _add_exit_label(n: String, pos: Vector2, text: String) -> void:
	var label := Label.new()
	label.name = n
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = pos - Vector2(28, 10)
	label.size = Vector2(56, 20)
	label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.22))
	label.z_index = 20
	add_child(label)
