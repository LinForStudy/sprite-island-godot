extends RefCounted
class_name GameCatalog

const MAX_LEVEL: int = 20
const UNDISCOVERED_BOOST: float = 3.0
const PITY_THRESHOLD: int = 12
const RARITY_WEIGHTS: Dictionary = {"common": 50, "rare": 30, "legend": 14, "mythic": 6}
const RARITY_EXP_BONUS: Dictionary = {"common": 4, "rare": 10, "legend": 18, "mythic": 28}
const RARITY_EXP_NEED_MULTIPLIER: Dictionary = {"common": 1.0, "rare": 1.12, "legend": 1.28, "mythic": 1.45}
const ADVANTAGE: Dictionary = {"grass": "earth", "earth": "electric", "electric": "water", "water": "fire", "fire": "wind", "wind": "grass"}
const BASE_BY_RARITY: Dictionary = {
	"common": {"hp": 34, "power": 9, "defense": 7, "magic": 8},
	"rare": {"hp": 39, "power": 11, "defense": 9, "magic": 10},
	"legend": {"hp": 45, "power": 14, "defense": 11, "magic": 13},
	"mythic": {"hp": 52, "power": 17, "defense": 14, "magic": 16}
}
const GROWTH_BY_RARITY: Dictionary = {
	"common": {"hp": 5, "power": 2, "defense": 1, "magic": 2},
	"rare": {"hp": 6, "power": 2, "defense": 2, "magic": 2},
	"legend": {"hp": 7, "power": 3, "defense": 2, "magic": 3},
	"mythic": {"hp": 8, "power": 3, "defense": 3, "magic": 3}
}
const ELEMENT_STAT_BIAS: Dictionary = {
	"grass": {"hp": 4, "defense": 1},
	"water": {"hp": 2, "magic": 2},
	"fire": {"power": 3, "magic": 1},
	"electric": {"power": 2, "magic": 2},
	"earth": {"hp": 3, "defense": 3},
	"wind": {"power": 1, "magic": 3}
}
const ELEMENT_SKILL: Dictionary = {
	"grass": {"name": "Leaf Gust", "type": "magic", "power": 8},
	"water": {"name": "Bubble Rush", "type": "magic", "power": 8},
	"fire": {"name": "Warm Charge", "type": "physical", "power": 9},
	"electric": {"name": "Tiny Spark", "type": "magic", "power": 9},
	"earth": {"name": "Pebble Bump", "type": "physical", "power": 8},
	"wind": {"name": "Soft Gale", "type": "magic", "power": 8}
}
const GUARD_SKILL: Dictionary = {
	"grass": {"name": "Leaf Guard"},
	"water": {"name": "Bubble Guard"},
	"fire": {"name": "Warm Guard"},
	"electric": {"name": "Spark Guard"},
	"earth": {"name": "Stone Guard"},
	"wind": {"name": "Gale Guard"}
}
const ULTIMATE_SKILL: Dictionary = {
	"grass": {"name": "Forest Star", "type": "magic", "power": 22},
	"water": {"name": "Moon Tide", "type": "magic", "power": 22},
	"fire": {"name": "Meteor Flame", "type": "magic", "power": 24},
	"electric": {"name": "Thunder Flash", "type": "magic", "power": 24},
	"earth": {"name": "Mountain Heart", "type": "physical", "power": 23},
	"wind": {"name": "Rainbow Gale", "type": "magic", "power": 23}
}
const NORMAL_SKILL_NAMES: Dictionary = {"grass": "Leaf Tap", "water": "Splash Tap", "fire": "Warm Tap", "electric": "Spark Tap", "earth": "Stone Tap", "wind": "Feather Tap"}
const SKILL_DISPLAY_NAMES: Dictionary = {
	"Leaf Tap": "叶叶轻拍",
	"Splash Tap": "水花轻拍",
	"Warm Tap": "暖暖轻拍",
	"Spark Tap": "电电轻拍",
	"Stone Tap": "石石轻拍",
	"Feather Tap": "风风轻拍",
	"Leaf Gust": "叶舞旋风",
	"Bubble Rush": "泡泡冲锋",
	"Warm Charge": "暖暖冲锋",
	"Tiny Spark": "小小电光",
	"Pebble Bump": "石子轻碰",
	"Soft Gale": "柔柔微风",
	"Leaf Guard": "叶叶守护",
	"Bubble Guard": "泡泡守护",
	"Warm Guard": "暖暖守护",
	"Spark Guard": "电电守护",
	"Stone Guard": "石石守护",
	"Gale Guard": "风风守护",
	"Tiny Heal": "小小治愈",
	"Water Hug": "水水抱抱",
	"Forest Star": "森林之星",
	"Moon Tide": "月下潮汐",
	"Meteor Flame": "流星之焰",
	"Thunder Flash": "雷光一闪",
	"Mountain Heart": "山之心",
	"Rainbow Gale": "彩虹之风"
}
const HEALER_IDS: Dictionary = {"leafbun": true, "bubblepup": true, "lanterncub": true, "cloudchick": true, "bloomwhale": true, "starjelly": true}
const BATTLE_CAPTURE_BALLS: Array[Dictionary] = [
	{"id": "star", "name": "Star Ball", "tier": "normal", "multiplier": 1.0, "weight": 48},
	{"id": "pink", "name": "Pink Ball", "tier": "fine", "multiplier": 1.25, "weight": 30},
	{"id": "gold", "name": "Gold Ball", "tier": "rare", "multiplier": 1.55, "weight": 16},
	{"id": "rainbow", "name": "Rainbow Ball", "tier": "legend", "multiplier": 1.85, "weight": 6}
]
const SPIRITS_DATA_PATH: String = "res://data/catalog/spirits_phase1.json"
const HABITATS_DATA_PATH: String = "res://data/catalog/habitats_phase1.json"
const BATTLE_FRAME_DIR: String = "res://resources/battle/spirits"
const LEGACY_BATTLE_FRAME_DIR: String = "res://resources/battle"
const REQUIRED_BATTLE_FRAME_COUNTS: Dictionary = {
	"idle": 4,
	"move": 4,
	"attack": 4,
	"hurt": 2,
	"defeat": 4
}

static var _spirits: Array[SpiritData] = []
static var _spirit_lookup: Dictionary = {}
static var _habitats: Array[HabitatData] = []
static var _habitat_lookup: Dictionary = {}

static func get_spirits() -> Array[SpiritData]:
	_ensure_data()
	return _spirits

static func get_spirit_by_id(spirit_id: String) -> SpiritData:
	_ensure_data()
	return _spirit_lookup.get(spirit_id) as SpiritData

static func get_habitats() -> Array[HabitatData]:
	_ensure_data()
	return _habitats

static func get_habitat_by_id(habitat_id: String) -> HabitatData:
	_ensure_data()
	return _habitat_lookup.get(habitat_id) as HabitatData

static func get_battle_frames(spirit_id: String) -> SpriteFrames:
	for resource_path in get_battle_frame_paths(spirit_id):
		if not ResourceLoader.exists(resource_path):
			continue
		var frames: SpriteFrames = load(resource_path) as SpriteFrames
		if frames == null:
			push_error("战斗动画资源不是 SpriteFrames：%s" % resource_path)
		return frames
	return null

static func get_battle_frame_paths(spirit_id: String) -> PackedStringArray:
	return PackedStringArray([
		"%s/%s_combat_frames.tres" % [BATTLE_FRAME_DIR, spirit_id],
		"%s/%s_combat_frames.tres" % [LEGACY_BATTLE_FRAME_DIR, spirit_id]
	])

static func get_battle_frame_issues(spirit_id: String) -> PackedStringArray:
	var issues: PackedStringArray = PackedStringArray()
	if get_spirit_by_id(spirit_id) == null:
		issues.append("未知萌灵 ID：%s" % spirit_id)
		return issues
	var frames: SpriteFrames = get_battle_frames(spirit_id)
	if frames == null:
		issues.append("缺少 SpriteFrames：%s" % get_battle_frame_paths(spirit_id)[0])
		return issues
	for action in REQUIRED_BATTLE_FRAME_COUNTS:
		var animation_name: StringName = StringName(action)
		if action == "defeat" and not frames.has_animation(animation_name) and frames.has_animation(&"exit"):
			animation_name = &"exit"
		if not frames.has_animation(animation_name):
			issues.append("%s 缺少动作 %s" % [spirit_id, action])
			continue
		var expected_count: int = int(REQUIRED_BATTLE_FRAME_COUNTS[action])
		var actual_count: int = frames.get_frame_count(animation_name)
		if actual_count != expected_count:
			issues.append("%s/%s 帧数应为 %d，当前为 %d" % [spirit_id, action, expected_count, actual_count])
		for frame_index in range(actual_count):
			if frames.get_frame_texture(animation_name, frame_index) == null:
				issues.append("%s/%s 第 %d 帧纹理为空" % [spirit_id, action, frame_index])
	return issues

static func validate_battle_frame_catalog() -> Dictionary:
	var report: Dictionary = {}
	for spirit in get_spirits():
		var issues: PackedStringArray = get_battle_frame_issues(spirit.spirit_id)
		if not issues.is_empty():
			report[spirit.spirit_id] = issues
	return report

static func element_multiplier(attacker: String, defender: String) -> float:
	if attacker == defender:
		return 1.0
	if String(ADVANTAGE.get(attacker, "")) == defender:
		return 1.5
	if String(ADVANTAGE.get(defender, "")) == attacker:
		return 0.75
	return 1.0

static func get_stats(spirit: SpiritData, level: int) -> Dictionary:
	var extra_levels: int = max(level - 1, 0)
	return {
		"hp": int(spirit.base_stats.hp) + int(spirit.growth_stats.hp) * extra_levels,
		"power": int(spirit.base_stats.power) + int(spirit.growth_stats.power) * extra_levels,
		"defense": int(spirit.base_stats.defense) + int(spirit.growth_stats.defense) * extra_levels,
		"magic": int(spirit.base_stats.magic) + int(spirit.growth_stats.magic) * extra_levels
	}

static func exp_to_next(level: int, rarity: String) -> int:
	if level >= MAX_LEVEL:
		return 0
	return int(round(level * 30.0 * float(RARITY_EXP_NEED_MULTIPLIER.get(rarity, 1.0))))

static func exp_reward(enemy_level: int, enemy_rarity: String) -> int:
	return enemy_level * 12 + int(RARITY_EXP_BONUS.get(enemy_rarity, 4))

static func calculate_skill_result(attacker: SpiritData, attacker_level: int, defender: SpiritData, defender_level: int, defender_hp: int, attacker_hp: int, skill: SpiritSkill, damage_bonus_rate: float = 0.0, heal_bonus_rate: float = 0.0) -> Dictionary:
	var attacker_stats: Dictionary = get_stats(attacker, attacker_level)
	var defender_stats: Dictionary = get_stats(defender, defender_level)
	var attacker_max_hp: int = int(attacker_stats.hp)
	if skill.skill_type == "heal":
		var base_heal: int = int(skill.power) + int(floor(int(attacker_stats.magic) * 0.55))
		var boosted_heal: int = int(round(base_heal * (1.0 + heal_bonus_rate)))
		var heal: int = min(attacker_max_hp - attacker_hp, boosted_heal)
		return {"damage": 0, "heal": heal, "multiplier": 1.0, "next_defender_hp": defender_hp, "next_attacker_hp": min(attacker_max_hp, attacker_hp + heal)}
	var raw_damage: int = max(1, int(attacker_stats.power) + int(skill.power) - int(defender_stats.defense)) if skill.skill_type == "physical" else max(1, int(attacker_stats.magic) + int(skill.power) - int(floor(int(defender_stats.defense) * 0.6)))
	var multiplier: float = element_multiplier(skill.element if skill.element != "" else attacker.element, defender.element)
	var damage: int = max(1, int(round(raw_damage * multiplier * (1.0 + damage_bonus_rate))))
	return {"damage": damage, "heal": 0, "multiplier": multiplier, "next_defender_hp": max(0, defender_hp - damage), "next_attacker_hp": attacker_hp}

static func roll_encounter(habitat_id: String, discovered: Dictionary, current_streak: int = 0) -> SpiritData:
	_ensure_data()
	var habitat: HabitatData = get_habitat_by_id(habitat_id)
	if habitat == null or habitat.encounter_pool.is_empty():
		return null
	var weighted: Array[Dictionary] = []
	var total_weight: float = 0.0
	for spirit_id in habitat.encounter_pool:
		var spirit: SpiritData = get_spirit_by_id(spirit_id)
		if spirit == null:
			continue
		var weight: float = float(RARITY_WEIGHTS.get(spirit.rarity, 1))
		if not discovered.has(spirit.spirit_id):
			weight *= UNDISCOVERED_BOOST
		if current_streak >= PITY_THRESHOLD and spirit.rarity != "common":
			weight *= 1.25
		weighted.append({"spirit": spirit, "weight": weight})
		total_weight += weight
	if weighted.is_empty():
		return null
	var roll: float = randf() * total_weight
	for item in weighted:
		roll -= float(item.weight)
		if roll <= 0.0:
			return item.spirit as SpiritData
	return weighted[0].spirit as SpiritData

static func roll_capture_ball() -> Dictionary:
	var total_weight: float = 0.0
	for item in BATTLE_CAPTURE_BALLS:
		total_weight += float(item.weight)
	var roll: float = randf() * total_weight
	for item in BATTLE_CAPTURE_BALLS:
		roll -= float(item.weight)
		if roll <= 0.0:
			return item
	return BATTLE_CAPTURE_BALLS[0]

static func battle_capture_chance(spirit: SpiritData, ball: Dictionary) -> float:
	var base_rate: float = spirit.catch_rate + 0.12
	return clamp(base_rate * float(ball.multiplier), 0.18, 0.96)

static func _ensure_data() -> void:
	if not _spirits.is_empty() and not _habitats.is_empty():
		return
	_load_habitats()
	_load_spirits()

static func _load_habitats() -> void:
	_habitats.clear()
	_habitat_lookup.clear()
	for entry in _read_json_array(HABITATS_DATA_PATH):
		var habitat: HabitatData = HabitatData.new()
		habitat.habitat_id = String(entry.get("habitat_id", ""))
		habitat.display_name = String(entry.get("display_name", ""))
		habitat.scene_id = String(entry.get("scene_id", ""))
		habitat.intro_text = String(entry.get("intro_text", ""))
		habitat.encounter_pool = Array(entry.get("encounter_pool", []), TYPE_STRING, "", null)
		_habitats.append(habitat)
		_habitat_lookup[habitat.habitat_id] = habitat

static func _load_spirits() -> void:
	_spirits.clear()
	_spirit_lookup.clear()
	for entry in _read_json_array(SPIRITS_DATA_PATH):
		var spirit: SpiritData = SpiritData.new()
		spirit.spirit_id = String(entry.get("spirit_id", ""))
		spirit.display_name = String(entry.get("display_name", ""))
		spirit.element = String(entry.get("element", "grass"))
		spirit.rarity = String(entry.get("rarity", "common"))
		spirit.habitat_id = String(entry.get("habitat_id", ""))
		spirit.catch_rate = float(entry.get("catch_rate", 0.5))
		spirit.description = String(entry.get("description", ""))
		spirit.favorite_food = String(entry.get("favorite_food", ""))
		spirit.base_stats = _merge_stats(Dictionary(BASE_BY_RARITY.get(spirit.rarity, BASE_BY_RARITY["common"])), Dictionary(ELEMENT_STAT_BIAS.get(spirit.element, {})))
		spirit.growth_stats = _merge_stats(Dictionary(GROWTH_BY_RARITY.get(spirit.rarity, GROWTH_BY_RARITY["common"])), Dictionary(ELEMENT_STAT_BIAS.get(spirit.element, {})))
		spirit.skills = _make_skills(spirit.spirit_id, spirit.element)
		_spirits.append(spirit)
		_spirit_lookup[spirit.spirit_id] = spirit

static func _read_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_ARRAY else []

static func _merge_stats(base_stats: Dictionary, bias: Dictionary) -> Dictionary:
	return {"hp": int(base_stats.hp) + int(bias.get("hp", 0)), "power": int(base_stats.power) + int(bias.get("power", 0)), "defense": int(base_stats.defense) + int(bias.get("defense", 0)), "magic": int(base_stats.magic) + int(bias.get("magic", 0))}

static func _make_skills(spirit_id: String, element: String) -> Array[SpiritSkill]:
	var skills: Array[SpiritSkill] = []
	skills.append(_skill("%s-tap" % spirit_id, String(NORMAL_SKILL_NAMES.get(element, "Tap")), "physical", "basic", 6, "", "A steady basic move."))
	var element_skill: Dictionary = Dictionary(ELEMENT_SKILL.get(element, ELEMENT_SKILL["grass"]))
	skills.append(_skill("%s-element" % spirit_id, String(element_skill.name), String(element_skill.type), "element", int(element_skill.power), element, "An elemental move."))
	var guard_skill: Dictionary = Dictionary(GUARD_SKILL.get(element, GUARD_SKILL["grass"]))
	var heal_name: String = "Water Hug" if spirit_id == "bubblepup" else "Tiny Heal"
	var is_healer: bool = HEALER_IDS.has(spirit_id)
	skills.append(_skill("%s-guard" % spirit_id, heal_name if is_healer else String(guard_skill.name), "heal", "guard", 14 if is_healer else 9, element, "Recover HP and reduce the next hit."))
	var ultimate_skill: Dictionary = Dictionary(ULTIMATE_SKILL.get(element, ULTIMATE_SKILL["grass"]))
	skills.append(_skill("%s-ultimate" % spirit_id, String(ultimate_skill.name), String(ultimate_skill.type), "ultimate", int(ultimate_skill.power), element, "A full-energy ultimate move."))
	return skills

static func _skill(skill_id: String, skill_name: String, skill_type: String, skill_role: String, power: int, element: String, description: String) -> SpiritSkill:
	var skill: SpiritSkill = SpiritSkill.new()
	skill.skill_id = skill_id
	skill.skill_name = skill_name
	skill.display_name = String(SKILL_DISPLAY_NAMES.get(skill_name, skill_name))
	skill.skill_type = skill_type
	skill.skill_role = skill_role
	skill.power = power
	skill.element = element
	skill.description = description
	return skill