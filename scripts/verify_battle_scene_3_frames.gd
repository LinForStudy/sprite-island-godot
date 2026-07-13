extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var player_data: SpiritData = GameCatalog.get_spirit_by_id("bubblepup")
	var enemy_data: SpiritData = GameCatalog.get_spirit_by_id("emberfox")
	if player_data == null or enemy_data == null:
		push_error("battle_scene smoke failed: test spirits did not load")
		quit(1)
		return
	var player_stats: Dictionary = GameCatalog.get_stats(player_data, 4)
	var enemy_stats: Dictionary = GameCatalog.get_stats(enemy_data, 4)
	var cases: Array[Dictionary] = [
		{"size": Vector2i(1280, 720), "name": "1280x720"},
		{"size": Vector2i(1920, 1080), "name": "1920x1080"},
		{"size": Vector2i(844, 390), "name": "mobile_landscape_844x390"}
	]
	for test_case in cases:
		var view_size: Vector2i = test_case.size
		var case_name: String = String(test_case.name)
		root.size = view_size
		await process_frame
		_setup_battle_state(player_stats, enemy_stats)
		var packed_scene: PackedScene = load("res://scenes/battle/battle_scene.tscn") as PackedScene
		if packed_scene == null:
			push_error("battle_scene smoke failed: scene did not load")
			quit(1)
			return
		var scene: Node = packed_scene.instantiate()
		root.add_child(scene)
		for frame_index in range(3):
			await process_frame
		var image: Image = root.get_viewport().get_texture().get_image()
		if image != null and not image.is_empty():
			var save_path: String = "res://docs/battle_scene_smoke_battle_%s.png" % case_name
			var save_error: int = image.save_png(save_path)
			if save_error != OK:
				push_error("battle_scene smoke could not save screenshot: %d" % save_error)
				quit(1)
				return
		scene.queue_free()
		await process_frame
	print("battle_scene battle smoke 3 frames passed for 1280x720, 1920x1080, mobile landscape")
	quit(0)

func _setup_battle_state(player_stats: Dictionary, enemy_stats: Dictionary) -> void:
	var save_manager: Node = root.get_node("/root/SaveManager")
	save_manager.save_data = {
		"version": 1,
		"last_saved_at": "battle-smoke",
		"discovered": {"bubblepup": true, "emberfox": true},
		"captured": {
			"bubblepup": {
				"affection": 42,
				"hunger": 70,
				"cleanliness": 70,
				"mood": "ready",
				"level": 4,
				"exp": 0,
				"current_hp": int(player_stats.hp)
			}
		},
		"exploration_streak": {}
	}
	var battle_manager: Node = root.get_node("/root/BattleManager")
	battle_manager.battle_state = {
		"status": "active",
		"habitat_id": "grassland",
		"player_spirit_id": "bubblepup",
		"enemy_spirit_id": "emberfox",
		"player_level": 4,
		"enemy_level": 4,
		"enemy_hp": int(enemy_stats.hp),
		"player_energy": 34,
		"player_guard_turns": 0,
		"log": ["泡泡汪勇敢出战！"]
	}
	battle_manager.current_phase = battle_manager.BattlePhase.PLAYER_CHOOSE
	battle_manager.pending_result = null