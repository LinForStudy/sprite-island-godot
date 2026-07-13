extends Node

# WorldState only stores scene-transition and dialogue state for this phase.
# Combat, encounter and save data are intentionally left for later milestones.

const DEFAULT_SPAWN_ID := "entry_default"

var next_scene_path: String = ""
var next_spawn_id: String = DEFAULT_SPAWN_ID
var current_scene_id: String = ""
var previous_scene_id: String = ""
var last_player_position: Vector2 = Vector2.ZERO
var last_player_facing: String = "down"
var dialogue_open: bool = false


func _ready() -> void:
	_ensure_input_map()


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


func register_scene(scene_id: String) -> void:
	previous_scene_id = current_scene_id
	current_scene_id = scene_id


func remember_player_state(world_position: Vector2, facing: String) -> void:
	last_player_position = world_position
	last_player_facing = facing


func set_next_spawn(scene_path: String, spawn_id: String) -> void:
	next_scene_path = scene_path
	next_spawn_id = spawn_id


func consume_spawn_id(fallback_spawn_id: String = DEFAULT_SPAWN_ID) -> String:
	var spawn_id: String = next_spawn_id if next_spawn_id != "" else fallback_spawn_id
	next_spawn_id = fallback_spawn_id
	return spawn_id


func set_dialogue_open(is_open: bool) -> void:
	dialogue_open = is_open


func clear_dialogue() -> void:
	dialogue_open = false
