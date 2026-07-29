extends Node

signal save_loaded(save_data: Dictionary)
signal save_changed(save_data: Dictionary)

const SAVE_PATH := "user://sprite-island-save-v1.json"
const BACKUP_PATH := "user://sprite-island-save-v1-backup.json"
const SAVE_VERSION := 2
const MAX_PARTY_SIZE := 3
const STARTER_SPIRIT_ID := "leafbun"
const INITIAL_INVENTORY: Dictionary = {
	"star": 5,
	"food": 3,
	"cleaning_tool": 3,
	"healing_item": 1
}
const HABITAT_IDS: Array[String] = ["grassland", "pond", "warmstone", "windmill", "cave", "cloud"]

var save_data: Dictionary = {}
var persistence_enabled: bool = true

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

func get_party_ids() -> Array[String]:
	var ids: Array[String] = []
	for spirit_id in Array(save_data.get("party", [])):
		ids.append(String(spirit_id))
	return ids

func set_party(party_ids: Array) -> bool:
	if party_ids.size() > MAX_PARTY_SIZE:
		return false
	var captured: Dictionary = Dictionary(save_data.get("captured", {}))
	if party_ids.is_empty() and not captured.is_empty():
		return false
	var normalized_party: Array[String] = []
	for raw_spirit_id in party_ids:
		var spirit_id: String = String(raw_spirit_id)
		if spirit_id == "" or normalized_party.has(spirit_id) or not captured.has(spirit_id):
			return false
		normalized_party.append(spirit_id)
	if normalized_party == get_party_ids():
		return true
	save_data["party"] = normalized_party
	save_now()
	return true

func get_item_count(item_id: String) -> int:
	return max(0, int(Dictionary(save_data.get("inventory", {})).get(item_id, 0)))

func add_item(item_id: String, amount: int = 1) -> bool:
	if item_id == "" or amount <= 0:
		return false
	var inventory: Dictionary = Dictionary(save_data.get("inventory", {}))
	inventory[item_id] = max(0, int(inventory.get(item_id, 0))) + amount
	save_data["inventory"] = inventory
	save_now()
	return true

func consume_item(item_id: String, amount: int = 1) -> bool:
	if item_id == "" or amount <= 0:
		return false
	var inventory: Dictionary = Dictionary(save_data.get("inventory", {}))
	var current_count: int = max(0, int(inventory.get(item_id, 0)))
	if current_count < amount:
		return false
	inventory[item_id] = current_count - amount
	save_data["inventory"] = inventory
	save_now()
	return true

func is_prototype_complete() -> bool:
	return bool(get_tutorial_progress().get("prototype_completed", false))

func get_prototype_completion_summary() -> String:
	var completed_regions: int = 0
	var capture_counts: Dictionary = Dictionary(save_data.get("habitat_capture_counts", {}))
	for habitat_id in HABITAT_IDS:
		if int(capture_counts.get(habitat_id, 0)) > 0:
			completed_regions += 1
	var party_count: int = get_party_ids().size()
	return "主线原型完成！\n地区进度：%d/%d · 图鉴：%d/%d · 队伍：%d/%d\n云台的风把新的旅程带到了小岛上，仍可继续自由收集。" % [completed_regions, HABITAT_IDS.size(), get_captured_spirit_ids().size(), GameCatalog.get_spirits().size(), party_count, MAX_PARTY_SIZE]

func is_habitat_unlocked(habitat_id: String) -> bool:
	return bool(Dictionary(save_data.get("unlocked_habitats", {"grassland": true})).get(habitat_id, false))

func unlock_habitat(habitat_id: String) -> bool:
	var unlocked: Dictionary = Dictionary(save_data.get("unlocked_habitats", {"grassland": true}))
	if bool(unlocked.get(habitat_id, false)):
		return false
	unlocked[habitat_id] = true
	save_data["unlocked_habitats"] = unlocked
	save_now()
	return true

func get_tutorial_progress() -> Dictionary:
	return Dictionary(save_data.get("tutorial_progress", {}))

func set_tutorial_flag(flag: String) -> void:
	var progress: Dictionary = get_tutorial_progress()
	if bool(progress.get(flag, false)):
		return
	progress[flag] = true
	save_data["tutorial_progress"] = progress
	recalculate_unlocks(false)
	save_now()

func mark_discovered(spirit_id: String) -> void:
	if has_discovered(spirit_id):
		return
	Dictionary(save_data.get("discovered", {}))[spirit_id] = true
	save_now()

func grant_starter_once(spirit_id: String = STARTER_SPIRIT_ID) -> bool:
	var progress: Dictionary = get_tutorial_progress()
	var captured: Dictionary = Dictionary(save_data.get("captured", {}))
	if bool(progress.get("starter_received", false)) or not captured.is_empty():
		if not bool(progress.get("starter_received", false)):
			progress["starter_received"] = true
			save_data["tutorial_progress"] = progress
			save_now()
		return false
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(spirit_id)
	if spirit == null:
		return false
	Dictionary(save_data.get("discovered", {}))[spirit.spirit_id] = true
	captured[spirit.spirit_id] = _new_pet_state(spirit, "starter")
	save_data["captured"] = captured
	save_data["party"] = [spirit.spirit_id]
	progress["starter_received"] = true
	save_data["tutorial_progress"] = progress
	_ensure_initial_inventory()
	save_now()
	return true

func capture_spirit(spirit: SpiritData, origin_habitat_id: String = "") -> bool:
	if spirit == null or has_captured(spirit.spirit_id):
		return false
	var habitat_id: String = origin_habitat_id if origin_habitat_id != "" else spirit.habitat_id
	Dictionary(save_data.get("discovered", {}))[spirit.spirit_id] = true
	Dictionary(save_data.get("captured", {}))[spirit.spirit_id] = _new_pet_state(spirit, habitat_id)
	var party: Array[String] = get_party_ids()
	if party.size() < MAX_PARTY_SIZE:
		party.append(spirit.spirit_id)
		save_data["party"] = party
	_record_wild_capture_in(habitat_id)
	save_now()
	return true

func record_wild_capture(habitat_id: String) -> bool:
	if not HABITAT_IDS.has(habitat_id):
		return false
	_record_wild_capture_in(habitat_id)
	save_now()
	return true

func recalculate_unlocks(save_immediately: bool = true) -> bool:
	var changed: bool = _recalculate_unlocks_in(save_data)
	if changed and save_immediately:
		save_now()
	return changed

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
	if spirit == null:
		return ""
	var pet: Dictionary = get_pet_state(spirit.spirit_id).duplicate(true)
	if pet.is_empty():
		return ""
	var item_id: String = {"feed": "food", "clean": "cleaning_tool"}.get(action, "")
	if item_id != "" and get_item_count(item_id) < 1:
		return "食物不足。" if action == "feed" else "清洁工具不足。"
	var max_hp: int = int(GameCatalog.get_stats(spirit, int(pet.level)).hp)
	var message: String = ""
	match action:
		"feed":
			pet.hunger = min(100, int(pet.hunger) + 18)
			pet.affection = min(100, int(pet.affection) + 5)
			pet.current_hp = min(max_hp, int(pet.current_hp) + 5)
			pet.mood = "full"
			message = "%s开心地吃了%s。" % [spirit.display_name, spirit.favorite_food]
		"clean":
			pet.cleanliness = min(100, int(pet.cleanliness) + 22)
			pet.affection = min(100, int(pet.affection) + 4)
			pet.mood = "clean"
			message = "%s变得干干净净啦。" % spirit.display_name
		"pet":
			pet.affection = min(100, int(pet.affection) + 12)
			pet.mood = "close"
			message = "%s更喜欢你了。" % spirit.display_name
		_:
			return ""
	if item_id != "":
		var inventory: Dictionary = Dictionary(save_data.get("inventory", {}))
		inventory[item_id] = get_item_count(item_id) - 1
		save_data["inventory"] = inventory
	Dictionary(save_data.get("captured", {}))[spirit.spirit_id] = pet
	_mark_first_care_completed()
	save_now()
	return message

func restore_all_pets() -> String:
	var captured: Dictionary = Dictionary(save_data.get("captured", {}))
	if captured.is_empty():
		return "还没有萌灵需要恢复。"
	if get_item_count("healing_item") < 1:
		return "恢复道具不足。"
	for spirit_id in captured.keys():
		var spirit: SpiritData = GameCatalog.get_spirit_by_id(String(spirit_id))
		if spirit == null:
			continue
		var pet: Dictionary = Dictionary(captured[spirit_id]).duplicate(true)
		pet.current_hp = int(GameCatalog.get_stats(spirit, int(pet.level)).hp)
		pet.mood = "rested"
		captured[spirit_id] = pet
	var inventory: Dictionary = Dictionary(save_data.get("inventory", {}))
	inventory["healing_item"] = get_item_count("healing_item") - 1
	save_data["inventory"] = inventory
	_mark_first_care_completed()
	save_now()
	return "所有萌灵都恢复精神啦。"

func save_now(write_backup: bool = true) -> void:
	save_data.version = SAVE_VERSION
	save_data.last_saved_at = Time.get_datetime_string_from_system(false, true)
	if persistence_enabled:
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
		"party": [],
		"inventory": INITIAL_INVENTORY.duplicate(true),
		"habitat_capture_counts": _empty_habitat_capture_counts(),
		"exploration_streak": {},
		"unlocked_habitats": {"grassland": true},
		"tutorial_progress": {
			"starter_received": false,
			"first_care_completed": false,
			"prototype_completed": false
		}
	}

func _normalize_save_data(raw: Dictionary) -> Dictionary:
	var raw_version: int = int(raw.get("version", 1))
	var captured: Dictionary = _normalize_captured(Dictionary(raw.get("captured", {})))
	var tutorial_progress: Dictionary = Dictionary(raw.get("tutorial_progress", {})).duplicate(true)
	if not captured.is_empty():
		tutorial_progress["starter_received"] = true
	else:
		tutorial_progress["starter_received"] = bool(tutorial_progress.get("starter_received", false))
	tutorial_progress["first_care_completed"] = bool(tutorial_progress.get("first_care_completed", false))
	tutorial_progress["prototype_completed"] = bool(tutorial_progress.get("prototype_completed", false))
	var normalized: Dictionary = {
		"version": SAVE_VERSION,
		"last_saved_at": String(raw.get("last_saved_at", Time.get_datetime_string_from_system(false, true))),
		"discovered": Dictionary(raw.get("discovered", {})).duplicate(true),
		"captured": captured,
		"party": _normalize_party(Array(raw.get("party", [])), captured),
		"inventory": _normalize_inventory(Dictionary(raw.get("inventory", {})), raw_version),
		"habitat_capture_counts": _normalize_capture_counts(Dictionary(raw.get("habitat_capture_counts", {})), captured, raw_version),
		"exploration_streak": Dictionary(raw.get("exploration_streak", {})).duplicate(true),
		"unlocked_habitats": _normalize_unlocked_habitats(Dictionary(raw.get("unlocked_habitats", {}))),
		"tutorial_progress": tutorial_progress
	}
	_recalculate_unlocks_in(normalized)
	return normalized

func _normalize_unlocked_habitats(raw: Dictionary) -> Dictionary:
	var unlocked: Dictionary = raw.duplicate(true)
	unlocked["grassland"] = true
	return unlocked

func _normalize_captured(raw: Dictionary) -> Dictionary:
	var captured: Dictionary = raw.duplicate(true)
	for raw_spirit_id in captured.keys():
		var spirit_id: String = String(raw_spirit_id)
		var pet: Dictionary = Dictionary(captured[raw_spirit_id]).duplicate(true)
		if not pet.has("origin_habitat_id"):
			var spirit: SpiritData = GameCatalog.get_spirit_by_id(spirit_id)
			pet["origin_habitat_id"] = spirit.habitat_id if spirit != null else ""
		captured[raw_spirit_id] = pet
	return captured

func _normalize_party(raw: Array, captured: Dictionary) -> Array[String]:
	var party: Array[String] = []
	for raw_spirit_id in raw:
		var spirit_id: String = String(raw_spirit_id)
		if spirit_id != "" and captured.has(spirit_id) and not party.has(spirit_id):
			party.append(spirit_id)
			if party.size() == MAX_PARTY_SIZE:
				break
	if party.is_empty() and not captured.is_empty():
		var captured_ids: Array[String] = []
		for raw_spirit_id in captured.keys():
			captured_ids.append(String(raw_spirit_id))
		captured_ids.sort()
		for spirit_id in captured_ids:
			party.append(spirit_id)
			if party.size() == MAX_PARTY_SIZE:
				break
	return party

func _normalize_inventory(raw: Dictionary, raw_version: int) -> Dictionary:
	var inventory: Dictionary = {}
	for raw_item_id in raw.keys():
		inventory[String(raw_item_id)] = max(0, int(raw[raw_item_id]))
	for item_id in INITIAL_INVENTORY.keys():
		if not inventory.has(item_id):
			inventory[item_id] = int(INITIAL_INVENTORY[item_id]) if raw_version < SAVE_VERSION else 0
	return inventory

func _normalize_capture_counts(raw: Dictionary, captured: Dictionary, raw_version: int) -> Dictionary:
	var counts: Dictionary = _empty_habitat_capture_counts()
	for raw_habitat_id in raw.keys():
		var habitat_id: String = String(raw_habitat_id)
		counts[habitat_id] = max(0, int(raw[raw_habitat_id]))
	if raw_version < SAVE_VERSION:
		var inferred_counts: Dictionary = _empty_habitat_capture_counts()
		for raw_spirit_id in captured.keys():
			var pet: Dictionary = Dictionary(captured[raw_spirit_id])
			var habitat_id: String = String(pet.get("origin_habitat_id", ""))
			if HABITAT_IDS.has(habitat_id):
				inferred_counts[habitat_id] = int(inferred_counts.get(habitat_id, 0)) + 1
		for habitat_id in HABITAT_IDS:
			counts[habitat_id] = max(int(counts.get(habitat_id, 0)), int(inferred_counts.get(habitat_id, 0)))
	return counts

func _empty_habitat_capture_counts() -> Dictionary:
	var counts: Dictionary = {}
	for habitat_id in HABITAT_IDS:
		counts[habitat_id] = 0
	return counts

func _new_pet_state(spirit: SpiritData, origin_habitat_id: String) -> Dictionary:
	var stats: Dictionary = GameCatalog.get_stats(spirit, 1)
	return {
		"affection": 35,
		"hunger": 68,
		"cleanliness": 72,
		"mood": "happy",
		"level": 1,
		"exp": 0,
		"current_hp": int(stats.hp),
		"origin_habitat_id": origin_habitat_id
	}

func _ensure_initial_inventory() -> void:
	var inventory: Dictionary = Dictionary(save_data.get("inventory", {}))
	for item_id in INITIAL_INVENTORY.keys():
		inventory[item_id] = max(max(0, int(inventory.get(item_id, 0))), int(INITIAL_INVENTORY[item_id]))
	save_data["inventory"] = inventory

func _record_wild_capture_in(habitat_id: String) -> void:
	var counts: Dictionary = Dictionary(save_data.get("habitat_capture_counts", _empty_habitat_capture_counts()))
	var previous_count: int = max(0, int(counts.get(habitat_id, 0)))
	counts[habitat_id] = previous_count + 1
	save_data["habitat_capture_counts"] = counts
	if previous_count == 0:
		var inventory: Dictionary = Dictionary(save_data.get("inventory", {}))
		inventory["healing_item"] = max(0, int(inventory.get("healing_item", 0))) + 1
		save_data["inventory"] = inventory
	recalculate_unlocks(false)

func _mark_first_care_completed() -> void:
	var progress: Dictionary = get_tutorial_progress()
	progress["first_care_completed"] = true
	save_data["tutorial_progress"] = progress
	recalculate_unlocks(false)

func _recalculate_unlocks_in(candidate: Dictionary) -> bool:
	var changed: bool = false
	var unlocked: Dictionary = Dictionary(candidate.get("unlocked_habitats", {}))
	var counts: Dictionary = Dictionary(candidate.get("habitat_capture_counts", {}))
	var progress: Dictionary = Dictionary(candidate.get("tutorial_progress", {}))
	changed = _unlock_in(unlocked, "grassland") or changed
	if int(counts.get("grassland", 0)) >= 1:
		changed = _unlock_in(unlocked, "pond") or changed
	var total_wild_captures: int = 0
	for habitat_id in HABITAT_IDS:
		total_wild_captures += max(0, int(counts.get(habitat_id, 0)))
	if bool(unlocked.get("pond", false)) and (total_wild_captures >= 2 or bool(progress.get("first_care_completed", false))):
		changed = _unlock_in(unlocked, "warmstone") or changed
	if int(counts.get("grassland", 0)) >= 1 and int(counts.get("pond", 0)) >= 1 and int(counts.get("warmstone", 0)) >= 1:
		changed = _unlock_in(unlocked, "grove_gate") or changed
		changed = _unlock_in(unlocked, "windmill") or changed
	if bool(unlocked.get("windmill", false)) and int(counts.get("windmill", 0)) >= 1:
		changed = _unlock_in(unlocked, "cave") or changed
	if bool(unlocked.get("cave", false)) and int(counts.get("cave", 0)) >= 1:
		changed = _unlock_in(unlocked, "cloud") or changed
	if bool(unlocked.get("cloud", false)) and int(counts.get("cloud", 0)) >= 1 and not bool(progress.get("prototype_completed", false)):
		progress["prototype_completed"] = true
		changed = true
	candidate["unlocked_habitats"] = unlocked
	candidate["tutorial_progress"] = progress
	return changed

func _unlock_in(unlocked: Dictionary, habitat_id: String) -> bool:
	if bool(unlocked.get(habitat_id, false)):
		return false
	unlocked[habitat_id] = true
	return true

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