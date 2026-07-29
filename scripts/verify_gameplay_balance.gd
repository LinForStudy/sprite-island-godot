extends SceneTree

var failure_count: int = 0

func _init() -> void:
	_check_catalog_shape()
	_check_capture_economy()
	_check_progression_numbers()
	_check_element_and_skill_numbers()
	if failure_count == 0:
		print("GAMEPLAY_BALANCE_SMOKE_OK")
		quit(0)
	else:
		push_error("Gameplay balance smoke failed with %d issue(s)." % failure_count)
		quit(1)


func _check_catalog_shape() -> void:
	var spirits: Array[SpiritData] = GameCatalog.get_spirits()
	var habitats: Array[HabitatData] = GameCatalog.get_habitats()
	_expect(spirits.size() == 24, "prototype catalog should contain exactly 24 spirits")
	_expect(habitats.size() == 6, "prototype catalog should contain exactly 6 habitats")
	for habitat in habitats:
		_expect(habitat.encounter_pool.size() == 4, "%s should expose four encounter spirits" % habitat.habitat_id)


func _check_capture_economy() -> void:
	var expected_ids: Array[String] = ["star", "pink", "gold", "rainbow"]
	var expected_weights: Array[int] = [48, 30, 16, 6]
	var total_weight: int = 0
	var previous_multiplier: float = 0.0
	for index in range(GameCatalog.BATTLE_CAPTURE_BALLS.size()):
		var ball: Dictionary = GameCatalog.BATTLE_CAPTURE_BALLS[index]
		_expect(String(ball.get("id", "")) == expected_ids[index], "capture-ball order should stay stable")
		_expect(int(ball.get("weight", 0)) == expected_weights[index], "capture-ball reward weight should stay balanced")
		_expect(float(ball.get("multiplier", 0.0)) > previous_multiplier, "capture-ball multipliers should increase by tier")
		previous_multiplier = float(ball.get("multiplier", 0.0))
		total_weight += int(ball.get("weight", 0))
	_expect(total_weight == 100, "capture-ball reward weights should sum to 100")
	var leafbun: SpiritData = GameCatalog.get_spirit_by_id("leafbun")
	var auroradrake: SpiritData = GameCatalog.get_spirit_by_id("auroradrake")
	var star_ball: Dictionary = GameCatalog.BATTLE_CAPTURE_BALLS[0]
	var rainbow_ball: Dictionary = GameCatalog.BATTLE_CAPTURE_BALLS[3]
	_expect(is_equal_approx(GameCatalog.battle_capture_chance(auroradrake, star_ball), 0.22), "mythic normal-ball capture chance should be 22%")
	_expect(is_equal_approx(GameCatalog.battle_capture_chance(leafbun, rainbow_ball), 0.96), "capture chance should retain the 96% cap")


func _check_progression_numbers() -> void:
	_expect(GameCatalog.exp_to_next(1, "common") == 30, "common level-one requirement should be 30 EXP")
	_expect(GameCatalog.exp_to_next(1, "mythic") == 44, "mythic level-one requirement should be 44 EXP")
	_expect(GameCatalog.exp_to_next(GameCatalog.MAX_LEVEL, "common") == 0, "maximum level should require no EXP")
	_expect(GameCatalog.exp_reward(1, "common") == 16, "common level-one reward should be 16 EXP")
	_expect(GameCatalog.exp_reward(1, "mythic") == 40, "mythic level-one reward should be 40 EXP")
	_expect(GameCatalog.exp_reward(5, "common") == 64, "level scaling should add 12 EXP per level")


func _check_element_and_skill_numbers() -> void:
	_expect(is_equal_approx(GameCatalog.element_multiplier("grass", "earth"), 1.5), "element advantage should be 1.5x")
	_expect(is_equal_approx(GameCatalog.element_multiplier("earth", "grass"), 0.75), "element disadvantage should be 0.75x")
	_expect(is_equal_approx(GameCatalog.element_multiplier("grass", "grass"), 1.0), "same element should be neutral")
	var leafbun: SpiritData = GameCatalog.get_spirit_by_id("leafbun")
	var pebbletot: SpiritData = GameCatalog.get_spirit_by_id("pebbletot")
	var basic: SpiritSkill = leafbun.skills[0]
	var max_hp: int = int(GameCatalog.get_stats(pebbletot, 1).hp)
	var result: Dictionary = GameCatalog.calculate_skill_result(leafbun, 1, pebbletot, 1, max_hp, int(GameCatalog.get_stats(leafbun, 1).hp), basic)
	_expect(int(result.get("damage", 0)) > 0, "every basic skill should deal at least one point of damage")
	_expect(is_equal_approx(float(result.get("multiplier", 0.0)), 1.5), "leafbun basic attack should use grass advantage against earth")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failure_count += 1
	push_error(message)
