extends SceneTree

const WORLD_SCENE := "res://scenes/world/test_world.tscn"
const OUTPUT_DIR := "res://docs/visual-matrix"
const CASES: Array[Dictionary] = [
	{"size": Vector2i(1280, 720), "name": "1280x720", "details": true},
	{"size": Vector2i(1600, 720), "name": "1600x720", "details": false},
	{"size": Vector2i(1920, 1080), "name": "1920x1080", "details": false},
	{"size": Vector2i(1366, 768), "name": "1366x768", "details": false},
	{"size": Vector2i(844, 390), "name": "844x390", "details": true}
]

var game_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		_fail("visual capture requires a non-headless Godot window")
		return
	var absolute_output: String = ProjectSettings.globalize_path(OUTPUT_DIR)
	var mkdir_error: Error = DirAccess.make_dir_recursive_absolute(absolute_output)
	if mkdir_error != OK:
		_fail("could not create output directory: %d" % mkdir_error)
		return
	game_state = root.get_node("/root/GameState")
	for test_case in CASES:
		if not await _capture_case(test_case):
			return
	print("UI_VISUAL_MATRIX_CAPTURE_OK:%s" % absolute_output)
	quit(0)


func _capture_case(test_case: Dictionary) -> bool:
	var test_size: Vector2i = test_case.size
	var case_name: String = String(test_case.name)
	DisplayServer.window_set_size(test_size)
	root.size = test_size
	for _frame in range(5):
		await process_frame
	game_state.call("close_panel")
	var packed: PackedScene = load(WORLD_SCENE) as PackedScene
	if packed == null:
		_fail("could not load world scene")
		return false
	var world: Node = packed.instantiate()
	root.add_child(world)
	for _frame in range(8):
		await process_frame
	var gameplay: CanvasLayer = world.get_node_or_null("GameplayUI") as CanvasLayer
	var dialogue: CanvasLayer = world.get_node_or_null("DialogueUI") as CanvasLayer
	if gameplay == null or dialogue == null:
		_fail("%s did not instantiate gameplay UI" % case_name)
		return false
	if not await _save_frame("world_hud", case_name, test_size):
		return false
	gameplay.call("_open_main_menu")
	for _frame in range(2):
		await process_frame
	if not await _save_frame("main_menu", case_name, test_size):
		return false
	(gameplay.get_node("Root/MainMenu") as Control).call("close")
	await process_frame
	if bool(test_case.details):
		game_state.call("open_dex")
		for _frame in range(2):
			await process_frame
		if not await _save_frame("dex", case_name, test_size):
			return false
		game_state.call("close_panel")
		game_state.call("open_home")
		for _frame in range(2):
			await process_frame
		if not await _save_frame("home", case_name, test_size):
			return false
		game_state.call("close_panel")
		dialogue.call("show_dialogue", "向导", "欢迎来到迎风广场，准备好认识你的第一位伙伴了吗？")
		for _frame in range(2):
			await process_frame
		if not await _save_frame("dialogue", case_name, test_size):
			return false
		dialogue.call("hide_dialogue")
	world.queue_free()
	await process_frame
	print("UI_VISUAL_MATRIX_OK:%s" % case_name)
	return true


func _save_frame(view_name: String, case_name: String, expected_size: Vector2i) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_fail("%s/%s produced an empty image" % [case_name, view_name])
		return false
	var actual_size: Vector2i = Vector2i(image.get_width(), image.get_height())
	if actual_size != expected_size:
		_fail("%s/%s image size is %s, expected %s" % [case_name, view_name, actual_size, expected_size])
		return false
	var save_path: String = "%s/%s-%s.png" % [OUTPUT_DIR, view_name, case_name]
	var save_error: Error = image.save_png(save_path)
	if save_error != OK:
		_fail("could not save %s: %d" % [save_path, save_error])
		return false
	return true


func _fail(message: String) -> void:
	push_error("UI_VISUAL_MATRIX_CAPTURE_FAIL:%s" % message)
	quit(1)