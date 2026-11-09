extends SceneTree

func _shot(path: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("SHOT ", path, " err=", err, " ", img.get_width(), "x", img.get_height())

func _initialize() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var scene := packed.instantiate()
	var gm = scene.get_node("GameManager")
	gm.auto_start = false
	root.add_child(scene)
	call_deferred("_run", scene)

func _run(scene: Node) -> void:
	var out := ProjectSettings.globalize_path("res://")
	var gm = scene.get_node("GameManager")
	var poster = scene.get_node("WantedPoster")
	poster.fast_mode = true
	await gm.start_level_flow()
	poster.escape_remaining = poster.escape_duration * 0.4
	poster._push_timer()
	await _shot(out + "shot-hud-gameplay.png")
	gm.show_capture_feedback(true)
	await _shot(out + "shot-hud-correct.png")
	gm.show_capture_feedback(false)
	await _shot(out + "shot-hud-wrong.png")
	gm.hide_capture_feedback()
	print("HUD_SHOTS_DONE phase=", poster.phase, " hunting=", poster.hunting)
	quit(0)
