extends SceneTree

const GameCatalogScript: GDScript = preload("res://scripts/core/game_catalog.gd")
const SaveManagerScript: GDScript = preload("res://autoload/save_manager.gd")

var failure_count: int = 0

func _init() -> void:
	_run_checks()
	if failure_count == 0:
		print("phase-1 rules runtime check passed.")
		quit(0)
	else:
		push_error("phase-1 rules runtime check failed with %d issue(s)." % failure_count)
		quit(1)

func _run_checks() -> void:
	_check_catalog_counts()
	_check_habitat_pools()
	_check_element_rules()
	_check_spirit_stats_and_skills()
	_check_exp_and_capture_rules()
	_check_save_defaults()

func _check_catalog_counts() -> void:
	var spirits: Array[SpiritData] = GameCatalogScript.get_spirits()
	var habitats: Array[HabitatData] = GameCatalogScript.get_habitats()
	_expect(spirits.size() == 24, "expected 24 phase-1 spirits")
	_expect(habitats.size() == 6, "expected 6 phase-1 habitats")

func _check_habitat_pools() -> void:
	var expected_habitats: Array[String] = ["grassland", "pond", "warmstone", "windmill", "cave", "cloud"]
	for habitat_id in expected_habitats:
		var habitat: HabitatData = GameCatalogScript.get_habitat_by_id(habitat_id)
		_expect(habitat != null, "missing habitat %s" % habitat_id)
		if habitat != null:
			_expect(habitat.encounter_pool.size() == 4, "habitat %s should keep 4 rarity slots" % habitat_id)
			var encountered: SpiritData = GameCatalogScript.roll_encounter(habitat_id, {}, 0)
			_expect(encountered != null, "habitat %s should roll an encounter" % habitat_id)

func _check_element_rules() -> void:
	_expect(is_equal_approx(GameCatalogScript.element_multiplier("grass", "earth"), 1.5), "grass should beat earth")
	_expect(is_equal_approx(GameCatalogScript.element_multiplier("earth", "electric"), 1.5), "earth should beat electric")
	_expect(is_equal_approx(GameCatalogScript.element_multiplier("electric", "water"), 1.5), "electric should beat water")
	_expect(is_equal_approx(GameCatalogScript.element_multiplier("water", "fire"), 1.5), "water should beat fire")
	_expect(is_equal_approx(GameCatalogScript.element_multiplier("fire", "wind"), 1.5), "fire should beat wind")
	_expect(is_equal_approx(GameCatalogScript.element_multiplier("wind", "grass"), 1.5), "wind should beat grass")
	_expect(is_equal_approx(GameCatalogScript.element_multiplier("earth", "grass"), 0.75), "reverse advantage should be resisted")
	_expect(is_equal_approx(GameCatalogScript.element_multiplier("grass", "grass"), 1.0), "same element should be neutral")

func _check_spirit_stats_and_skills() -> void:
	var leafbun: SpiritData = GameCatalogScript.get_spirit_by_id("leafbun")
	var sunlion: SpiritData = GameCatalogScript.get_spirit_by_id("sunlion")
	_expect(leafbun != null, "leafbun should load")
	_expect(sunlion != null, "sunlion should load")
	if leafbun != null:
		_expect(leafbun.skills.size() == 4, "leafbun should have 4 skills")
		_expect(leafbun.skills[0].skill_role == "basic", "first skill should be basic")
		_expect(leafbun.skills[1].skill_role == "element", "second skill should be element")
		_expect(leafbun.skills[2].skill_role == "guard", "third skill should be guard")
		_expect(leafbun.skills[3].skill_role == "ultimate", "fourth skill should be ultimate")
		var level_one_stats: Dictionary = GameCatalogScript.get_stats(leafbun, 1)
		var level_two_stats: Dictionary = GameCatalogScript.get_stats(leafbun, 2)
		_expect(int(level_two_stats.hp) > int(level_one_stats.hp), "stats should grow by level")
	if leafbun != null and sunlion != null:
		var result: Dictionary = GameCatalogScript.calculate_skill_result(leafbun, 1, sunlion, 1, 20, 20, leafbun.skills[0])
		_expect(int(result.damage) >= 1, "damage result should always deal at least 1")

func _check_exp_and_capture_rules() -> void:
	var leafbun: SpiritData = GameCatalogScript.get_spirit_by_id("leafbun")
	_expect(GameCatalogScript.exp_to_next(1, "common") > 0, "level 1 should need exp")
	_expect(GameCatalogScript.exp_to_next(GameCatalogScript.MAX_LEVEL, "common") == 0, "max level should not need exp")
	_expect(GameCatalogScript.exp_reward(3, "rare") > GameCatalogScript.exp_reward(1, "common"), "higher enemy should reward more exp")
	var ball: Dictionary = GameCatalogScript.roll_capture_ball()
	_expect(not ball.is_empty(), "capture ball roll should return a ball")
	if leafbun != null:
		var chance: float = GameCatalogScript.battle_capture_chance(leafbun, {"multiplier": 1.0})
		_expect(chance >= 0.18 and chance <= 0.96, "battle capture chance should be clamped")

func _check_save_defaults() -> void:
	var save_manager: Node = SaveManagerScript.new()
	var normalized: Dictionary = save_manager.call("_normalize_save_data", {})
	_expect(int(normalized.version) == 2, "save version should default to 2")
	_expect(normalized.has("discovered"), "save should include discovered")
	_expect(normalized.has("captured"), "save should include captured")
	_expect(normalized.has("party"), "save should include party")
	_expect(normalized.has("inventory"), "save should include inventory")
	_expect(normalized.has("habitat_capture_counts"), "save should include habitat capture counts")
	_expect(normalized.has("exploration_streak"), "save should include exploration streak")
	save_manager.queue_free()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failure_count += 1
	push_error(message)