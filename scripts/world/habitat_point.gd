extends Area2D

const HABITAT_TEXTURES: Dictionary = {
	"grassland": "res://assets/exploration_points/01_grassland_草丛探索点.png",
	"pond": "res://assets/exploration_points/02_pond_池塘探索点.png",
	"warmstone": "res://assets/exploration_points/03_warm_stone_暖石探索点.png",
	"windmill": "res://assets/exploration_points/04_windmill_风车探索点.png",
	"cave": "res://assets/exploration_points/05_cave_山洞探索点.png",
	"cloud": "res://assets/exploration_points/06_cloud_platform_云台探索点.png"
}

@export var habitat_id: String = ""
@export var display_name: String = "探索点"
@export_multiline var interaction_text: String = "按确认键开始探索。"

@onready var point_sprite: Sprite2D = $PointSprite
@onready var name_label: Label = $NameLabel

func _ready() -> void:
	add_to_group("interactable")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	if name_label != null:
		name_label.text = "探索%s" % display_name
		name_label.visible = false
	_apply_visuals()

func interact(_player: CharacterBody2D) -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.has_method("open_habitat_panel"):
		current_scene.call("open_habitat_panel", habitat_id)

func _apply_visuals() -> void:
	if point_sprite == null:
		return
	var texture_path: String = String(HABITAT_TEXTURES.get(habitat_id, ""))
	if texture_path == "":
		point_sprite.texture = null
		return
	point_sprite.texture = load(texture_path) as Texture2D

func _on_area_entered(area: Area2D) -> void:
	if name_label != null and _is_player_interaction_area(area):
		name_label.visible = true

func _on_area_exited(area: Area2D) -> void:
	if name_label != null and _is_player_interaction_area(area):
		name_label.visible = false

func _is_player_interaction_area(area: Area2D) -> bool:
	var owner: Node = area.get_parent()
	return owner != null and owner.is_in_group("player")
