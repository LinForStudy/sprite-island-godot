extends Area2D

# SceneExit switches scenes as soon as the player steps into the trigger.
# Spawn IDs keep the destination placement data outside hard-coded coordinates.

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_id: String = "entry_default"
@export var current_exit_id: String = ""
@export var display_name: String = "前往下一张地图"
@export var required_habitat_id: String = ""
@export_multiline var locked_message: String = "这条路暂时还没有开放。"

@onready var name_label: Label = $NameLabel

var transition_locked: bool = false


func _ready() -> void:
	if name_label != null:
		name_label.text = display_name
		name_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _on_body_entered(body: Node2D) -> void:
	if transition_locked:
		return
	if not body.is_in_group("player"):
		return
	if target_scene_path == "":
		push_warning("SceneExit is missing target_scene_path.")
		return
	if required_habitat_id != "" and not SaveManager.is_habitat_unlocked(required_habitat_id):
		GameState.set_message(locked_message)
		if name_label != null:
			name_label.text = locked_message
			name_label.visible = true
		return

	transition_locked = true
	if body.has_method("get_facing_direction"):
		WorldState.remember_player_state(body.global_position, str(body.call("get_facing_direction")))
	else:
		WorldState.remember_player_state(body.global_position, "down")
	WorldState.set_next_spawn(target_scene_path, target_spawn_id)
	get_tree().change_scene_to_file(target_scene_path)

func _on_body_exited(body: Node2D) -> void:
	if name_label != null and body.is_in_group("player"):
		name_label.visible = false


func _on_area_entered(area: Area2D) -> void:
	if name_label != null and _is_player_interaction_area(area):
		name_label.visible = true


func _on_area_exited(area: Area2D) -> void:
	if name_label != null and _is_player_interaction_area(area):
		name_label.visible = false


func _is_player_interaction_area(area: Area2D) -> bool:
	var owner: Node = area.get_parent()
	return owner != null and owner.is_in_group("player")
