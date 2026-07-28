extends SceneTree

const WORLD_SCENE := "res://scenes/world/test_world.tscn"
const CASES: Array[Dictionary] = [
	{"size": Vector2i(1280, 720), "name": "1280x720", "mobile": false},
	{"size": Vector2i(1600, 720), "name": "1600x720", "mobile": false},
	{"size": Vector2i(1920, 1080), "name": "1920x1080", "mobile": false},
	{"size": Vector2i(1366, 768), "name": "1366x768", "mobile": false},
	{"size": Vector2i(844, 390), "name": "844x390", "mobile": true}
]

var display_manager: Node
var game_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	display_manager = root.get_node("/root/DisplayManager")
	game_state = root.get_node("/root/GameState")
	for test_case in CASES:
		root.size = test_case.size
		for _frame in range(2):
			await process_frame
		if bool(display_manager.call("is_mobile_layout")) != bool(test_case.mobile):
			_fail("%s selected the wrong display profile" % String(test_case.name))
			return
		var packed: PackedScene = load(WORLD_SCENE) as PackedScene
		if packed == null:
			_fail("world scene did not load")
			return
		var world: Node = packed.instantiate()
		root.add_child(world)
		for _frame in range(5):
			await process_frame
		var visible_size: Vector2i = Vector2i(root.get_visible_rect().size)
		var gameplay: CanvasLayer = world.get_node_or_null("GameplayUI") as CanvasLayer
		var dialogue: CanvasLayer = world.get_node_or_null("DialogueUI") as CanvasLayer
		if gameplay == null or dialogue == null:
			_fail("%s did not instantiate gameplay or dialogue UI" % String(test_case.name))
			return
		if gameplay.get_node_or_null("Root/DexPanel") != null or gameplay.get_node_or_null("Root/HomePanel") != null:
			_fail("legacy DexPanel/HomePanel still exists")
			return
		var touch_controls: Control = gameplay.get_node("Root/TouchControls") as Control
		if touch_controls.visible != bool(test_case.mobile):
			_fail("%s touch control visibility mismatch" % String(test_case.name))
			return
		gameplay.call("_open_main_menu")
		await process_frame
		var main_menu: Control = gameplay.get_node("Root/MainMenu") as Control
		if not main_menu.visible:
			_fail("%s could not open the HUD main menu" % String(test_case.name))
			return
		_assert_inside(main_menu.get_node("ModalCenter/ModalPanel") as Control, visible_size, "%s main menu" % String(test_case.name))
		if _has_failed():
			return
		main_menu.call("close")
		await process_frame
		game_state.call("open_dex")
		await process_frame
		var dex_panel: Control = gameplay.get_node("Root/DexPage/ModalShell/ModalCenter/ModalPanel") as Control
		_assert_inside(dex_panel, visible_size, "%s dex" % String(test_case.name))
		if _has_failed():
			return
		game_state.call("close_panel")
		game_state.call("open_home")
		await process_frame
		var home_panel: Control = gameplay.get_node("Root/HomePage/ModalShell/ModalCenter/ModalPanel") as Control
		_assert_inside(home_panel, visible_size, "%s home" % String(test_case.name))
		if _has_failed():
			return
		game_state.call("close_panel")
		dialogue.call("show_dialogue", "向导", "欢迎来到迎风广场。")
		await process_frame
		_assert_inside(dialogue.get_node("Root") as Control, visible_size, "%s dialogue" % String(test_case.name))
		if _has_failed():
			return
		dialogue.call("hide_dialogue")
		world.queue_free()
		await process_frame
		print("UI_MATRIX_OK:%s" % String(test_case.name))
	print("UI_MATRIX_STRUCTURAL_SMOKE_OK")
	quit(0)


func _assert_inside(control: Control, viewport_size: Vector2i, label: String) -> void:
	var rect: Rect2 = control.get_global_rect()
	if rect.position.x < -1.0 or rect.position.y < -1.0 or rect.end.x > float(viewport_size.x) + 1.0 or rect.end.y > float(viewport_size.y) + 1.0:
		_fail("%s is outside viewport: %s vs %s" % [label, rect, viewport_size])


func _fail(message: String) -> void:
	set_meta("failed", true)
	push_error("UI_MATRIX_FAIL:%s" % message)
	quit(1)


func _has_failed() -> bool:
	return bool(get_meta("failed", false))