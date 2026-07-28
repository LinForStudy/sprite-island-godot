extends Node

## The single registration and polling boundary for keyboard, controller and touch input.
## UI controls write touch intents here; gameplay code consumes semantic actions here.

signal touch_confirm_requested
signal touch_cancel_requested
signal touch_menu_requested

const ACTION_KEYCODES: Dictionary = {
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
	&"ui_accept": [KEY_ENTER, KEY_SPACE],
	&"ui_cancel": [KEY_ESCAPE],
	&"game_menu": [KEY_ESCAPE]
}

var _touch_move: Vector2 = Vector2.ZERO
var _touch_interact_queued: bool = false
var _touch_confirm_queued: bool = false
var _touch_cancel_queued: bool = false
var _touch_menu_queued: bool = false
var _exploration_input_enabled: bool = true
var _exploration_blockers: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_map()


func get_move_vector() -> Vector2:
	if not is_exploration_input_enabled():
		return Vector2.ZERO
	var hardware: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return _touch_move if _touch_move.length() > hardware.length() else hardware


func consume_interact() -> bool:
	var dialogue_open: bool = _is_dialogue_open()
	if not is_exploration_input_enabled() and not dialogue_open:
		_touch_interact_queued = false
		return false
	var pressed: bool = Input.is_action_just_pressed("interact") or _touch_interact_queued
	_touch_interact_queued = false
	return pressed


func consume_confirm(include_hardware: bool = true) -> bool:
	var pressed: bool = (include_hardware and Input.is_action_just_pressed("ui_accept")) or _touch_confirm_queued
	_touch_confirm_queued = false
	return pressed


func consume_cancel(include_hardware: bool = true) -> bool:
	var pressed: bool = (include_hardware and Input.is_action_just_pressed("ui_cancel")) or _touch_cancel_queued
	_touch_cancel_queued = false
	return pressed


func consume_menu(include_hardware: bool = true) -> bool:
	var pressed: bool = (include_hardware and Input.is_action_just_pressed("game_menu")) or _touch_menu_queued
	_touch_menu_queued = false
	return pressed


func set_touch_move(value: Vector2) -> void:
	_touch_move = value.limit_length(1.0) if is_exploration_input_enabled() else Vector2.ZERO


func queue_touch_interact() -> void:
	if is_exploration_input_enabled():
		_touch_interact_queued = true


func queue_touch_confirm() -> void:
	_touch_confirm_queued = true
	touch_confirm_requested.emit()


func queue_touch_cancel() -> void:
	_touch_cancel_queued = true
	touch_cancel_requested.emit()


func queue_touch_menu() -> void:
	_touch_menu_queued = true
	touch_menu_requested.emit()


func set_exploration_input_enabled(enabled: bool) -> void:
	_exploration_input_enabled = enabled
	if not enabled:
		clear_touch_state()


func set_exploration_blocked(source: StringName, blocked: bool) -> void:
	if blocked:
		_exploration_blockers[source] = true
	else:
		_exploration_blockers.erase(source)
	if blocked:
		clear_touch_state()


func is_exploration_input_enabled() -> bool:
	return _exploration_input_enabled and _exploration_blockers.is_empty() and not _runtime_blocks_exploration()


func clear_touch_state() -> void:
	_touch_move = Vector2.ZERO
	_touch_interact_queued = false


func _is_dialogue_open() -> bool:
	var world_state: Node = get_node_or_null("/root/WorldState")
	return world_state != null and bool(world_state.get("dialogue_open"))


func _runtime_blocks_exploration() -> bool:
	if _is_dialogue_open():
		return true
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null and String(game_state.get("current_panel")) != "hud":
		return true
	var scene: Node = get_tree().current_scene
	return scene != null and scene.scene_file_path.begins_with("res://scenes/battle/")


func _ensure_input_map() -> void:
	for action_name: StringName in ACTION_KEYCODES:
		_register_action(action_name, ACTION_KEYCODES[action_name])


func _register_action(action_name: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if not InputMap.action_get_events(action_name).is_empty():
		return
	for keycode: int in keycodes:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = keycode
		event.keycode = keycode
		InputMap.action_add_event(action_name, event)