extends SceneTree

const GameCatalogScript: GDScript = preload("res://scripts/core/game_catalog.gd")
const SaveManagerScript: GDScript = preload("res://autoload/save_manager.gd")

var failure_count: int = 0
var test_managers: Array[Node] = []

func _init() -> void:
	_check_defaults_and_starter()
	_check_legacy_migration()
	_check_unlock_sequence()
	_check_party_constraints()
	_check_inventory_and_care_atomicity()
	_cleanup_test_managers()
	if failure_count == 0:
		print("save v2 runtime check passed.")
		quit(0)
	else:
		push_error("save v2 runtime check failed with %d issue(s)." % failure_count)
		quit(1)

func _check_defaults_and_starter() -> void:
	var manager: Node = _fresh_manager()
	var initial: Dictionary = manager.get_save_data()
	_expect(int(initial.get("version", 0)) == 2, "new save should use version 2")
	_expect(manager.get_item_count("star") == 5, "new save should start with 5 star balls")
	_expect(manager.get_item_count("food") == 3, "new save should start with 3 food")
	_expect(manager.get_item_count("cleaning_tool") == 3, "new save should start with 3 cleaning tools")
	_expect(manager.get_item_count("healing_item") == 1, "new save should start with 1 healing item")
	_expect(manager.grant_starter_once("leafbun"), "fresh save should receive leafbun once")
	_expect(not manager.grant_starter_once("leafbun"), "starter grant should be idempotent")
	_expect(manager.has_captured("leafbun"), "starter should be captured")
	_expect(manager.get_party_ids() == ["leafbun"], "starter should occupy party slot one")
	_expect(String(manager.get_pet_state("leafbun").get("origin_habitat_id", "")) == "starter", "starter origin should be recorded")
	_expect(int(Dictionary(manager.get_save_data().get("habitat_capture_counts", {})).get("grassland", -1)) == 0, "starter must not count as wild capture")
	_expect(not manager.is_habitat_unlocked("pond"), "starter must not unlock pond")
	_expect(manager.get_item_count("star") == 5, "repeated starter grant must not duplicate items")

func _check_legacy_migration() -> void:
	var manager: Node = _manager_from({
		"version": 1,
		"captured": {
			"bubblepup": {"affection": 40, "hunger": 60, "cleanliness": 70, "mood": "happy", "level": 1, "exp": 0, "current_hp": 40}
		},
		"unlocked_habitats": {"grassland": true, "warmstone": true, "cave": true},
		"tutorial_progress": {}
	})
	var migrated: Dictionary = manager.get_save_data()
	_expect(int(migrated.get("version", 0)) == 2, "legacy save should migrate to version 2")
	_expect(bool(Dictionary(migrated.get("tutorial_progress", {})).get("starter_received", false)), "legacy capture should mark starter flow complete")
	_expect(not manager.grant_starter_once("leafbun"), "legacy save must not receive starter again")
	_expect(not manager.has_captured("leafbun"), "migration must not inject leafbun into an existing save")
	_expect(String(manager.get_pet_state("bubblepup").get("origin_habitat_id", "")) == "pond", "legacy captured origin should be inferred")
	_expect(int(Dictionary(migrated.get("habitat_capture_counts", {})).get("pond", 0)) >= 1, "legacy captures should seed non-regressing counts")
	_expect(manager.is_habitat_unlocked("warmstone"), "migration must preserve warmstone unlock")
	_expect(manager.is_habitat_unlocked("cave"), "migration must preserve later unlocks")
	_expect(manager.get_party_ids() == ["bubblepup"], "legacy captured spirits should seed a usable party")
	_expect(manager.get_item_count("star") == 5, "v1 migration should add initial star balls")
	var v2_partial: Node = _manager_from({"version": 2, "inventory": {"star": 2}})
	_expect(v2_partial.get_item_count("star") == 2, "v2 migration must preserve existing inventory counts")
	_expect(v2_partial.get_item_count("food") == 0, "v2 normalization must not top up missing inventory")
	_expect(v2_partial.grant_starter_once("leafbun"), "starter gift should repair missing initial supplies on an unstarted v2 save")
	_expect(v2_partial.get_item_count("star") == 5 and v2_partial.get_item_count("food") == 3, "starter gift should provide the fixed initial supplies")

func _check_unlock_sequence() -> void:
	var manager: Node = _fresh_manager()
	manager.grant_starter_once("leafbun")
	_expect(manager.capture_spirit(GameCatalogScript.get_spirit_by_id("sproutdeer"), "grassland"), "grassland wild capture should succeed")
	_expect(manager.get_item_count("healing_item") == 2, "first capture in a habitat should reward one healing item")
	_expect(manager.is_habitat_unlocked("pond"), "first grassland wild capture should unlock pond")
	_expect(not manager.is_habitat_unlocked("warmstone"), "first wild capture should not unlock warmstone")
	_expect(manager.capture_spirit(GameCatalogScript.get_spirit_by_id("bubblepup"), "pond"), "pond wild capture should succeed")
	_expect(manager.is_habitat_unlocked("warmstone"), "second wild capture should unlock warmstone")
	_expect(manager.capture_spirit(GameCatalogScript.get_spirit_by_id("emberfox"), "warmstone"), "warmstone wild capture should succeed")
	_expect(manager.is_habitat_unlocked("grove_gate"), "first three habitats should unlock grove gate")
	_expect(manager.is_habitat_unlocked("windmill"), "grove entry should open windmill first")
	_expect(not manager.is_habitat_unlocked("cave"), "cave should remain locked before windmill capture")
	manager.capture_spirit(GameCatalogScript.get_spirit_by_id("sparkmouse"), "windmill")
	_expect(manager.is_habitat_unlocked("cave"), "windmill capture should unlock cave")
	_expect(not manager.is_habitat_unlocked("cloud"), "cloud should remain locked before cave capture")
	manager.capture_spirit(GameCatalogScript.get_spirit_by_id("pebbletot"), "cave")
	_expect(manager.is_habitat_unlocked("cloud"), "cave capture should unlock cloud")
	_expect(not manager.is_prototype_complete(), "prototype should remain incomplete before cloud capture")
	manager.capture_spirit(GameCatalogScript.get_spirit_by_id("cloudchick"), "cloud")
	_expect(manager.is_prototype_complete(), "cloud capture should complete the prototype")
	_expect(String(manager.get_prototype_completion_summary()).contains("地区进度：6/6"), "prototype completion summary should expose completed region progress")
	_expect(manager.get_party_ids().size() == 3, "automatic party fill must stop at three")
	_expect(String(manager.get_pet_state("cloudchick").get("origin_habitat_id", "")) == "cloud", "wild capture should record origin habitat")

func _check_party_constraints() -> void:
	var manager: Node = _fresh_manager()
	manager.grant_starter_once("leafbun")
	manager.capture_spirit(GameCatalogScript.get_spirit_by_id("sproutdeer"), "grassland")
	manager.capture_spirit(GameCatalogScript.get_spirit_by_id("bubblepup"), "pond")
	manager.capture_spirit(GameCatalogScript.get_spirit_by_id("emberfox"), "warmstone")
	_expect(manager.get_party_ids() == ["leafbun", "sproutdeer", "bubblepup"], "captures should auto-fill party in capture order")
	_expect(manager.set_party(["emberfox", "leafbun", "bubblepup"]), "owned unique party should be accepted")
	var accepted_party: Array[String] = manager.get_party_ids()
	_expect(not manager.set_party(["leafbun", "leafbun"]), "duplicate party members should be rejected")
	_expect(manager.get_party_ids() == accepted_party, "duplicate rejection must not write")
	_expect(not manager.set_party(["not-owned"]), "unowned party member should be rejected")
	_expect(manager.get_party_ids() == accepted_party, "unowned rejection must not write")
	_expect(not manager.set_party(["leafbun", "sproutdeer", "bubblepup", "emberfox"]), "party larger than three should be rejected")
	_expect(not manager.set_party([]), "captured roster must not allow an empty party")
	_expect(manager.get_party_ids() == accepted_party, "invalid party requests must preserve the accepted party")

func _check_inventory_and_care_atomicity() -> void:
	var manager: Node = _fresh_manager()
	manager.grant_starter_once("leafbun")
	_expect(manager.consume_item("star", 2), "inventory should consume available items")
	_expect(manager.get_item_count("star") == 3, "star ball count should decrease")
	var before_failed_consume: Dictionary = manager.get_save_data().duplicate(true)
	_expect(not manager.consume_item("star", 4), "inventory should reject insufficient consumption")
	_expect(manager.get_save_data() == before_failed_consume, "insufficient consumption must be a no-write path")
	_expect(manager.add_item("star", 2), "inventory should add items")
	_expect(manager.get_item_count("star") == 5, "added items should be visible")
	var leafbun: SpiritData = GameCatalogScript.get_spirit_by_id("leafbun")
	var food_before: int = manager.get_item_count("food")
	_expect(manager.care_for(leafbun, "feed") != "", "feeding should succeed with food")
	_expect(manager.get_item_count("food") == food_before - 1, "feeding should consume one food")
	var cleaning_before: int = manager.get_item_count("cleaning_tool")
	_expect(manager.care_for(leafbun, "clean") != "", "cleaning should succeed with a cleaning tool")
	_expect(manager.get_item_count("cleaning_tool") == cleaning_before - 1, "cleaning should consume one cleaning tool")
	var inventory_before_pet: Dictionary = Dictionary(manager.get_save_data().get("inventory", {})).duplicate(true)
	_expect(manager.care_for(leafbun, "pet") != "", "petting should remain available")
	_expect(Dictionary(manager.get_save_data().get("inventory", {})) == inventory_before_pet, "petting should not consume an item")
	_expect(bool(Dictionary(manager.get_save_data().get("tutorial_progress", {})).get("first_care_completed", false)), "successful care should set first-care progress")
	_expect(not manager.is_habitat_unlocked("warmstone"), "care must not skip the pond gate")
	manager.capture_spirit(GameCatalogScript.get_spirit_by_id("sproutdeer"), "grassland")
	_expect(manager.is_habitat_unlocked("warmstone"), "stored first-care progress should unlock warmstone after pond opens")
	var empty_food_manager: Node = _fresh_manager()
	empty_food_manager.grant_starter_once("leafbun")
	empty_food_manager.consume_item("food", 3)
	var before_failed_care: Dictionary = empty_food_manager.get_save_data().duplicate(true)
	_expect(empty_food_manager.care_for(leafbun, "feed") == "食物不足。", "feeding should report insufficient food")
	_expect(empty_food_manager.get_save_data() == before_failed_care, "failed care must not modify pet, progress, or inventory")
	var healing_before: int = manager.get_item_count("healing_item")
	_expect(manager.restore_all_pets() != "恢复道具不足。", "restore should succeed with a healing item")
	_expect(manager.get_item_count("healing_item") == healing_before - 1, "restore should consume one healing item")

func _fresh_manager() -> Node:
	return _manager_from({})

func _manager_from(raw: Dictionary) -> Node:
	var manager: Node = SaveManagerScript.new()
	manager.set("persistence_enabled", false)
	manager.set("save_data", manager.call("_normalize_save_data", raw))
	test_managers.append(manager as Node)
	return manager

func _cleanup_test_managers() -> void:
	for manager in test_managers:
		if is_instance_valid(manager):
			manager.free()
	test_managers.clear()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failure_count += 1
	push_error(message)