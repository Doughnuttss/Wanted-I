extends SceneTree

func _shot(path: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("SHOT ", path, " err=", err)

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
	var claw = scene.get_node("Claw")
	var crowd = scene.get_node("Crowd")
	var poster = scene.get_node("WantedPoster")
	var hud = scene.get_node("HUD")
	poster.fast_mode = true

	print("LOOP_TEST_START")
	# Full level intro + reveal
	await gm.start_level_flow()
	print("STATE_AFTER_REVEAL=", gm.state, " expect ACTIVE_HUNT=", gm.State.ACTIVE_HUNT)
	await process_frame

	# Claw hit target → next wanted
	if crowd.target:
		claw.enabled = true
		# Show reticle mid-drop for final screenshot
		claw.busy = true
		claw._reticle.visible = true
		claw._reticle.global_position = crowd.target.global_position
		claw._reticle.modulate = Color(1, 1, 0.4, 0.95)
		await _shot(out + "shot-gameplay-final.png")
		claw.busy = false
		claw._reticle.visible = false
		await claw._drop_at(crowd.target.global_position)
		# wait for game manager flow
		var guard := 0
		while gm._busy_flow and guard < 200:
			await process_frame
			guard += 1
		await create_timer(0.2).timeout
		print("AFTER_CAPTURE state=", gm.state, " captures=", hud.captures)

	# Force false alarms to game over path
	hud.set_lives(1)
	gm.state = gm.State.ACTIVE_HUNT
	poster.hunting = true
	claw.set_enabled(true)
	# Hit a non-target if available
	var miss_npc: CrowdNPC = null
	for n in crowd.npcs:
		if is_instance_valid(n) and not n.is_target:
			miss_npc = n
			break
	if miss_npc:
		await claw._drop_at(miss_npc.global_position)
		var g2 := 0
		while gm._busy_flow and g2 < 200:
			await process_frame
			g2 += 1
		await create_timer(0.3).timeout
		print("AFTER_MISS state=", gm.state, " lives=", hud.lives)

	# If not game over, drain lives via escape
	if gm.state != gm.State.GAME_OVER:
		hud.set_lives(1)
		gm.state = gm.State.ACTIVE_HUNT
		poster.hunting = true
		poster.escape_remaining = 0.01
		await create_timer(0.05).timeout
		# manually fire escape
		gm._on_escape_timeout()
		var g3 := 0
		while gm._busy_flow and g3 < 200:
			await process_frame
			g3 += 1
		await create_timer(1.2).timeout
		print("AFTER_ESCAPE state=", gm.state)

	print("LOOP_TEST_DONE state=", gm.state)
	quit(0)