extends Resource
class_name SpiritData

@export var spirit_id: String = ""
@export var display_name: String = ""
@export var element: String = "grass"
@export var rarity: String = "common"
@export var habitat_id: String = ""
@export var catch_rate: float = 0.5
@export_multiline var description: String = ""
@export var favorite_food: String = ""
@export var base_stats: Dictionary = {"hp": 30, "power": 8, "defense": 8, "magic": 8}
@export var growth_stats: Dictionary = {"hp": 5, "power": 2, "defense": 2, "magic": 2}
@export var skills: Array[SpiritSkill] = []