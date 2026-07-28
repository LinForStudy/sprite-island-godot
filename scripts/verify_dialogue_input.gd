extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var input_router: Node = root.get_node("/root/InputRouter")
	var world_state: Node = root.get_node("/root/WorldState")
	world_state.call("set_dialogue_open", true)
	input_router.call("set_exploration_blocked", &"dialogue", true)

	input_router.set("_touch_interact_queued", true)
	var dialogue_close_consumed: bool = bool(input_router.call("consume_interact"))
	if not dialogue_close_consumed:
		_fail("dialogue close did not consume the interact action while exploration was blocked")
		return

	input_router.call("set_touch_move", Vector2.RIGHT)
	var blocked_move: Vector2 = input_router.call("get_move_vector")
	if not blocked_move.is_zero_approx():
		_fail("dialogue input blocker leaked movement to exploration")
		return

	world_state.call("set_dialogue_open", false)
	input_router.call("set_exploration_blocked", &"dialogue", false)
	input_router.call("set_exploration_blocked", &"modal_test", true)
	input_router.set("_touch_interact_queued", true)
	var modal_interact_consumed: bool = bool(input_router.call("consume_interact"))
	input_router.call("set_exploration_blocked", &"modal_test", false)
	if modal_interact_consumed:
		_fail("non-dialogue modal blocker leaked interaction to exploration")
		return

	for keycode in [KEY_E, KEY_SPACE]:
		var mapped: bool = false
		for event in InputMap.action_get_events("interact"):
			if event is InputEventKey and ((event as InputEventKey).keycode == keycode or (event as InputEventKey).physical_keycode == keycode):
				mapped = true
				break
		if not mapped:
			_fail("interact action is missing keycode %d" % keycode)
			return

	var packed_world: PackedScene = load("res://scenes/world/test_world.tscn") as PackedScene
	if packed_world == null:
		_fail("world scene could not load for dialogue close smoke")
		return
	var world: Node = packed_world.instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	var dialogue: CanvasLayer = world.get_node("DialogueUI") as CanvasLayer
	dialogue.call("show_dialogue", "迎风向导", "关闭输入回归")
	input_router.set("_touch_interact_queued", true)
	var player: CharacterBody2D = world.get_node("YSortEntities/Player") as CharacterBody2D
	player.call("_physics_process", 0.016)
	if bool(world_state.get("dialogue_open")) or dialogue.get_node("Root").visible:
		_fail("player interaction path did not close the visible dialogue panel")
		return

	current_scene = null
	world.queue_free()
	await process_frame
	print("DIALOGUE_INPUT_SMOKE_OK")
	quit(0)


func _fail(message: String) -> void:
	push_error("DIALOGUE_INPUT_SMOKE_FAIL: %s" % message)
	quit(1)