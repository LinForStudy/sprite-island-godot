extends Area2D

# The test NPC exposes a single interact() method so the player script
# can reuse the same interaction flow for future NPCs, signs and objects.

@export var speaker_name: String = "向导"
@export_multiline var dialogue_text: String = "你好，欢迎来到萌灵小岛。"

@onready var name_label: Label = $NameLabel

func _ready() -> void:
	add_to_group("interactable")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	if name_label != null:
		name_label.visible = false

func interact(_player: CharacterBody2D) -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.has_method("toggle_dialogue_panel"):
		current_scene.call("toggle_dialogue_panel", speaker_name, dialogue_text)

func _on_area_entered(area: Area2D) -> void:
	if name_label != null and _is_player_interaction_area(area):
		name_label.visible = true

func _on_area_exited(area: Area2D) -> void:
	if name_label != null and _is_player_interaction_area(area):
		name_label.visible = false

func _is_player_interaction_area(area: Area2D) -> bool:
	var owner: Node = area.get_parent()
	return owner != null and owner.is_in_group("player")
