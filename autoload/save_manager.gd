extends Node

signal save_loaded(save_data: Dictionary)
signal save_changed(save_data: Dictionary)

const SAVE_PATH := "user://sprite-island-save-v1.json"
const BACKUP_PATH := "user://sprite-island-save-v1-backup.json"
const SAVE_VERSION := 1

var save_data: Dictionary = {}

func _ready() -> void:
	_ensure_save_directory()
	load_or_create()

func load_or_create() -> void:
	var loaded: Dictionary = _read_json(SAVE_PATH)
	if loaded.is_empty():
		loaded = _read_json(BACKUP_PATH)
	save_data = _normalize_save_data(loaded if not loaded.is_empty() else _default_save_data())
	save_loaded.emit(save_data)
	save_changed.emit(save_data)
	save_now(false)

func get_save_data() -> Dictionary:
	return save_data

func has_discovered(spirit_id: String) -> bool:
	return Dictionary(save_data.get("discovered", {})).has(spirit_id)

func has_captured(spirit_id: String) -> bool:
	return Dictionary(save_data.get("captured", {})).has(spirit_id)

func get_pet_state(spirit_id: String) -> Dictionary:
	return Dictionary(save_data.get("captured", {})).get(spirit_id, {})

func get_captured_spirit_ids() -> Array[String]:
	var ids: Array[String] = []
	for spirit_id in Dictionary(save_data.get("captured", {})).keys():
		ids.append(String(spirit_id))
	ids.sort()
	return ids

func mark_discovered(spirit_id: String) -> void:
	if has_discovered(spirit_id):
		return
	Dictionary(save_data.get("discovered", {}))[spirit_id] = true
	save_now()

func capture_spirit(spirit: SpiritData) -> bool:
	if spirit == null or has_captured(spirit.spirit_id):
		return false
	var stats: Dictionary = GameCatalog.get_stats(spirit, 1)
	Dictionary(save_data.get("discovered", {}))[spirit.spirit_id] = true
	Dictionary(save_data.get("captured", {}))[spirit.spirit_id] = {
		"affection": 35,
		"hunger": 68,
		"cleanliness": 72,
		"mood": "happy",
		"level": 1,
		"exp": 0,
		"current_hp": int(stats.hp)
	}
	save_now()
	return true

func update_pet_state(spirit_id: String, pet_state: Dictionary, save_immediately: bool = true) -> void:
	Dictionary(save_data.get("captured", {}))[spirit_id] = pet_state
	if save_immediately:
		save_now()

func add_exploration_streak(habitat_id: String) -> int:
	var streaks: Dictionary = Dictionary(save_data.get("exploration_streak", {}))
	var streak: int = int(streaks.get(habitat_id, 0)) + 1
	streaks[habitat_id] = streak
	save_now()
	return streak

func get_exploration_streak(habitat_id: String) -> int:
	return int(Dictionary(save_data.get("exploration_streak", {})).get(habitat_id, 0))

func care_for(spirit: SpiritData, action: String) -> String:
	var pet: Dictionary = get_pet_state(spirit.spirit_id)
	if pet.is_empty():
		return ""
	var max_hp: int = int(GameCatalog.get_stats(spirit, int(pet.level)).hp)
	match action:
		"feed":
			pet.hunger = min(100, int(pet.hunger) + 18)
			pet.affection = min(100, int(pet.affection) + 5)
			pet.current_hp = min(max_hp, int(pet.current_hp) + 5)
			pet.mood = "full"
			update_pet_state(spirit.spirit_id, pet)
			return "%s开心地吃了%s。" % [spirit.display_name, spirit.favorite_food]
		"clean":
			pet.cleanliness = min(100, int(pet.cleanliness) + 22)
			pet.affection = min(100, int(pet.affection) + 4)
			pet.mood = "clean"
			update_pet_state(spirit.spirit_id, pet)
			return "%s变得干干净净啦。" % spirit.display_name
		"pet":
			pet.affection = min(100, int(pet.affection) + 12)
			pet.mood = "close"
			update_pet_state(spirit.spirit_id, pet)
			return "%s更喜欢你了。" % spirit.display_name
	return ""

func restore_all_pets() -> String:
	var captured: Dictionary = Dictionary(save_data.get("captured", {}))
	for spirit_id in captured.keys():
		var spirit: SpiritData = GameCatalog.get_spirit_by_id(String(spirit_id))
		if spirit == null:
			continue
		var pet: Dictionary = captured[spirit_id]
		pet.current_hp = int(GameCatalog.get_stats(spirit, int(pet.level)).hp)
		pet.mood = "rested"
		captured[spirit_id] = pet
	save_now()
	return "所有萌灵都恢复精神啦。"

func save_now(write_backup: bool = true) -> void:
	save_data.version = SAVE_VERSION
	save_data.last_saved_at = Time.get_datetime_string_from_system(false, true)
	if write_backup and _has_progress(save_data):
		_write_json(BACKUP_PATH, save_data)
	_write_json(SAVE_PATH, save_data)
	save_changed.emit(save_data)

func _default_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"last_saved_at": Time.get_datetime_string_from_system(false, true),
		"discovered": {},
		"captured": {},
		"exploration_streak": {}
	}

func _normalize_save_data(raw: Dictionary) -> Dictionary:
	return {
		"version": int(raw.get("version", SAVE_VERSION)),
		"last_saved_at": String(raw.get("last_saved_at", Time.get_datetime_string_from_system(false, true))),
		"discovered": Dictionary(raw.get("discovered", {})),
		"captured": Dictionary(raw.get("captured", {})),
		"exploration_streak": Dictionary(raw.get("exploration_streak", {}))
	}

func _has_progress(candidate: Dictionary) -> bool:
	return not Dictionary(candidate.get("discovered", {})).is_empty() or not Dictionary(candidate.get("captured", {})).is_empty()

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _write_json(path: String, payload: Dictionary) -> void:
	_ensure_save_directory()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager could not open save path: %s" % path)
		return
	file.store_string(JSON.stringify(payload, "\t"))

func _ensure_save_directory() -> void:
	var save_dir: String = ProjectSettings.globalize_path("user://")
	if save_dir == "":
		return
	var error_code: int = DirAccess.make_dir_recursive_absolute(save_dir)
	if error_code != OK:
		push_warning("SaveManager could not prepare save directory: %s" % save_dir)