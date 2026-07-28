extends Area2D

@export var starter_spirit_id: String = "leafbun"
@export var speaker_name: String = "迎风向导"
@export_multiline var first_dialogue_text: String = "叶团团愿意陪你一起出发！它已经入住小屋，并加入队伍第一格。"
@export_multiline var repeat_dialogue_text: String = "叶团团会一直陪着你。先去草丛认识第一位野外朋友吧。"

@onready var name_label: Label = $NameLabel


func _ready() -> void:
	add_to_group("interactable")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	if name_label != null:
		name_label.visible = false


func interact(_player: CharacterBody2D) -> void:
	var granted: bool = SaveManager.grant_starter_once(starter_spirit_id)
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(starter_spirit_id)
	var spirit_name: String = spirit.display_name if spirit != null else "叶团团"
	var text: String = first_dialogue_text if granted else repeat_dialogue_text
	if granted:
		text = text.replace("叶团团", spirit_name)
		GameState.set_message("%s加入了队伍，初始物资也已放入背包。" % spirit_name)
	_show_dialogue(text)


func _show_dialogue(text: String) -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.has_method("toggle_dialogue_panel"):
		current_scene.call("toggle_dialogue_panel", speaker_name, text)


func _on_area_entered(area: Area2D) -> void:
	if name_label != null and _is_player_interaction_area(area):
		name_label.visible = true


func _on_area_exited(area: Area2D) -> void:
	if name_label != null and _is_player_interaction_area(area):
		name_label.visible = false


func _is_player_interaction_area(area: Area2D) -> bool:
	var owner: Node = area.get_parent()
	return owner != null and owner.is_in_group("player")
