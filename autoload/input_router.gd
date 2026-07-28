extends Node

## Unified keyboard and touch input boundary. UI touch controls only write into this router.

var _touch_move: Vector2 = Vector2.ZERO
var _touch_interact_queued: bool = false
var _exploration_input_enabled: bool = true

func _ready() -> void:
	_ensure_input_map()

func get_move_vector() -> Vector2:
	if not _exploration_input_enabled:
		return Vector2.ZERO
	var keyboard: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return _touch_move if _touch_move.length() > keyboard.length() else keyboard

func consume_interact() -> bool:
	if not _exploration_input_enabled:
		return false
	var pressed: bool = Input.is_action_just_pressed("interact") or _touch_interact_queued
	_touch_interact_queued = false
	return pressed

func set_touch_move(value: Vector2) -> void:
	_touch_move = value.limit_length(1.0)

func queue_touch_interact() -> void:
	_touch_interact_queued = true

func set_exploration_input_enabled(enabled: bool) -> void:
	_exploration_input_enabled = enabled
	if not enabled:
		_touch_move = Vector2.ZERO
		_touch_interact_queued = false

func _ensure_input_map() -> void:
	_register_action("move_up", [KEY_W, KEY_UP])
	_register_action("move_down", [KEY_S, KEY_DOWN])
	_register_action("move_left", [KEY_A, KEY_LEFT])
	_register_action("move_right", [KEY_D, KEY_RIGHT])
	_register_action("interact", [KEY_E, KEY_SPACE, KEY_ENTER])

func _register_action(action_name: String, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if InputMap.action_get_events(action_name).is_empty():
		for keycode in keycodes:
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = keycode
			event.keycode = keycode
			InputMap.action_add_event(action_name, event)