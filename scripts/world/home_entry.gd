extends Area2D

@export var display_name: String = "萌灵小屋"
@export_multiline var empty_message: String = "还没有 captured spirit，暂时无法进入小屋。"

@onready var name_label: Label = $NameLabel

func _ready() -> void:
	add_to_group("interactable")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	if name_label != null:
		name_label.text = display_name
		name_label.visible = false

func interact(_player: CharacterBody2D) -> void:
	if SaveManager.get_captured_spirit_ids().is_empty():
		GameState.set_message(empty_message)
		return
	GameState.open_home()

func _on_area_entered(area: Area2D) -> void:
	if name_label != null and _is_player_interaction_area(area):
		name_label.visible = true

func _on_area_exited(area: Area2D) -> void:
	if name_label != null and _is_player_interaction_area(area):
		name_label.visible = false

func _is_player_interaction_area(area: Area2D) -> bool:
	var owner: Node = area.get_parent()
	return owner != null and owner.is_in_group("player")
