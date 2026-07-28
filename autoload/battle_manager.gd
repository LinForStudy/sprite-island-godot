extends Node

## BattleManager — battle flow state machine with presentation support.
## Phase 1: basic attacks get full lunge presentation; other skills get simplified presentation.
## Flow: use_skill() calculates result -> BattlePresentation plays animation -> apply_player_result() applies state.
## UI never modifies HP directly; BattlePresentation tweens HP bar for display only.
## All damage formulas, element multipliers, enemy AI, energy rules, exp, capture, save are unchanged.

signal battle_state_changed
signal presentation_timed_out

enum BattlePhase {
	NONE,
	INTRO,
	PLAYER_CHOOSE,
	RESOLVING_PLAYER,
	RESOLVING_ENEMY,
	CHECKING_RESULT,
	VICTORY,
	DEFEAT,
	CAPTURE,
	EXITING
}

const ACTION_TIMEOUT_SECONDS: float = 4.0

var battle_state: Dictionary = _default_battle_state()
var battle_result: Dictionary = _default_battle_result()
var return_scene_path: String = "res://scenes/world/test_world.tscn"

var current_phase: BattlePhase = BattlePhase.NONE
var pending_result: BattleActionResult = null
var _input_consumed_this_turn: bool = false
var _result_finalized: bool = false
var _action_timer: SceneTreeTimer = null

func set_return_scene_path(scene_path: String) -> void:
	if scene_path != "":
		return_scene_path = scene_path

func prepare_battle(enemy_spirit_id: String, habitat_id: String) -> bool:
	var captured_ids: Array[String] = SaveManager.get_captured_spirit_ids()
	if captured_ids.is_empty():
		GameState.set_message("先邀请一只萌灵入住，再来挑战吧。")
		return false
	battle_state = _default_battle_state()
	battle_result = _default_battle_result()
	current_phase = BattlePhase.NONE
	pending_result = null
	_input_consumed_this_turn = false
	_result_finalized = false
	_cancel_action_timeout()
	battle_state.habitat_id = habitat_id
	battle_state.enemy_spirit_id = enemy_spirit_id
	if GameState.selected_battle_spirit_id == "" or not SaveManager.has_captured(GameState.selected_battle_spirit_id):
		GameState.selected_battle_spirit_id = captured_ids[0]
	GameState.current_panel = "battle_prep"
	GameState.ui_state_changed.emit(GameState.current_panel)
	battle_state_changed.emit()
	return true

func start_battle(player_spirit_id: String) -> void:
	var player_spirit: SpiritData = GameCatalog.get_spirit_by_id(player_spirit_id)
	var enemy_spirit: SpiritData = GameCatalog.get_spirit_by_id(String(battle_state.enemy_spirit_id))
	var pet: Dictionary = SaveManager.get_pet_state(player_spirit_id)
	if player_spirit == null or enemy_spirit == null or pet.is_empty():
		GameState.set_message("挑战资料还没准备好。")
		return
	battle_state.player_spirit_id = player_spirit_id
	battle_state.player_level = max(1, int(pet.level))
	battle_state.enemy_level = battle_state.player_level
	battle_state.enemy_hp = int(GameCatalog.get_stats(enemy_spirit, int(battle_state.enemy_level)).hp)
	battle_state.player_energy = 0
	battle_state.player_guard_turns = 0
	battle_state.log = ["%s勇敢出战！" % player_spirit.display_name]
	pending_result = null
	_input_consumed_this_turn = false
	_result_finalized = false
	_cancel_action_timeout()
	_set_phase(BattlePhase.PLAYER_CHOOSE)
	GameState.current_panel = "battle"
	GameState.ui_state_changed.emit(GameState.current_panel)
	GameState.set_message("挑战开始，选一个技能吧。")
	battle_state_changed.emit()

func choose_player_position(slot: String) -> void:
	if current_phase != BattlePhase.PLAYER_CHOOSE:
		return
	if slot not in ["left", "center", "right"]:
		return
	battle_state.player_position_slot = slot
	_append_log("站位调整到%s。" % {"left": "左侧", "center": "中央", "right": "右侧"}[slot])
	battle_state_changed.emit()

func use_skill(skill_index: int) -> void:
	if current_phase != BattlePhase.PLAYER_CHOOSE:
		return
	if _input_consumed_this_turn:
		return
	var player_spirit: SpiritData = GameCatalog.get_spirit_by_id(String(battle_state.player_spirit_id))
	var enemy_spirit: SpiritData = GameCatalog.get_spirit_by_id(String(battle_state.enemy_spirit_id))
	var pet: Dictionary = SaveManager.get_pet_state(String(battle_state.player_spirit_id))
	if player_spirit == null or enemy_spirit == null or pet.is_empty():
		return
	if skill_index < 0 or skill_index >= player_spirit.skills.size():
		return
	var skill: SpiritSkill = player_spirit.skills[skill_index]
	if skill.skill_role == "ultimate" and int(battle_state.player_energy) < 100:
		GameState.set_message("能量还没满，大招先等等。")
		return
	_input_consumed_this_turn = true
	_set_phase(BattlePhase.RESOLVING_PLAYER)
	pending_result = _calculate_player_action(player_spirit, enemy_spirit, pet, skill)
	_start_action_timeout()
	battle_state_changed.emit()

func apply_player_result() -> void:
	if current_phase != BattlePhase.RESOLVING_PLAYER:
		return
	_cancel_action_timeout()
	if pending_result == null:
		return
	var result: BattleActionResult = pending_result
	pending_result = null
	var player_spirit: SpiritData = GameCatalog.get_spirit_by_id(String(battle_state.player_spirit_id))
	var enemy_spirit: SpiritData = GameCatalog.get_spirit_by_id(String(battle_state.enemy_spirit_id))
	var pet: Dictionary = SaveManager.get_pet_state(String(battle_state.player_spirit_id))
	if player_spirit == null or enemy_spirit == null or pet.is_empty():
		_set_phase(BattlePhase.PLAYER_CHOOSE)
		_input_consumed_this_turn = false
		battle_state_changed.emit()
		return
	if result.is_heal:
		pet.current_hp = result.attacker_hp_after
		battle_state.player_guard_turns = result.guard_gained
	SaveManager.update_pet_state(String(battle_state.player_spirit_id), pet, false)
	battle_state.enemy_hp = result.defender_hp_after
	battle_state.player_energy = result.new_energy
	for msg in result.log_messages:
		_append_log(msg)
	if result.defender_defeated:
		_set_phase(BattlePhase.CHECKING_RESULT)
		_finish_battle(true)
		return
	_prepare_enemy_action(player_spirit, enemy_spirit, pet)

func apply_enemy_result() -> void:
	if current_phase != BattlePhase.RESOLVING_ENEMY:
		return
	_cancel_action_timeout()
	if pending_result == null:
		_set_phase(BattlePhase.PLAYER_CHOOSE)
		_input_consumed_this_turn = false
		battle_state_changed.emit()
		return
	var result: BattleActionResult = pending_result
	pending_result = null
	var pet: Dictionary = SaveManager.get_pet_state(String(battle_state.player_spirit_id))
	if result.is_heal:
		battle_state.enemy_hp = result.attacker_hp_after
	else:
		pet.current_hp = result.defender_hp_after
		battle_state.player_energy = result.new_energy
		if result.guard_consumed:
			battle_state.player_guard_turns = 0
	SaveManager.update_pet_state(String(battle_state.player_spirit_id), pet, false)
	for msg in result.log_messages:
		_append_log(msg)
	if result.defender_defeated:
		_set_phase(BattlePhase.CHECKING_RESULT)
		_finish_battle(false)
		return
	_set_phase(BattlePhase.PLAYER_CHOOSE)
	_input_consumed_this_turn = false
	SaveManager.save_now()
	battle_state_changed.emit()

func draw_capture_ball() -> void:
	if battle_result.status != "won":
		battle_result.capture_message = "先赢下挑战，才有战后收服机会。"
		battle_state_changed.emit()
		return
	if bool(battle_result.capture_attempted):
		battle_result.capture_message = "这场挑战已经试过一次收服啦。"
		battle_state_changed.emit()
		return
	if bool(battle_result.capture_already_owned):
		battle_result.capture_status = "already"
		battle_result.capture_message = "%s已经住在小屋里啦。" % battle_result.enemy_name
		battle_state_changed.emit()
		return
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(String(battle_result.enemy_spirit_id))
	if spirit == null:
		return
	var ball: Dictionary = GameCatalog.roll_capture_ball()
	battle_result.capture_status = "ready"
	battle_result.capture_ball = ball
	battle_result.capture_chance = GameCatalog.battle_capture_chance(spirit, ball)
	battle_result.capture_message = "抽到%s，收服机会大约%d%%。" % [String(ball.name), int(round(float(battle_result.capture_chance) * 100.0))]
	GameState.set_message(String(battle_result.capture_message))
	battle_state_changed.emit()

func try_capture_after_battle() -> String:
	if battle_result.status != "won" or not bool(battle_result.capture_eligible):
		return "none"
	if bool(battle_result.capture_already_owned):
		battle_result.capture_status = "already"
		battle_result.capture_message = "%s已经住在小屋里啦。" % battle_result.enemy_name
		battle_state_changed.emit()
		return "already"
	if bool(battle_result.capture_attempted):
		battle_result.capture_message = "这场挑战已经试过一次收服啦。"
		battle_state_changed.emit()
		return "failed"
	if Dictionary(battle_result.capture_ball).is_empty():
		draw_capture_ball()
	var enemy_spirit: SpiritData = GameCatalog.get_spirit_by_id(String(battle_result.enemy_spirit_id))
	if enemy_spirit == null:
		return "none"
	battle_result.capture_attempted = true
	var success: bool = randf() <= float(battle_result.capture_chance)
	if success and SaveManager.capture_spirit(enemy_spirit):
		battle_result.capture_status = "captured"
		battle_result.capture_eligible = false
		battle_result.capture_message = "%s愿意住进小屋啦！" % enemy_spirit.display_name
		GameState.set_message(String(battle_result.capture_message))
		battle_state_changed.emit()
		return "captured"
	battle_result.capture_status = "failed"
	battle_result.capture_message = "%s还想再练习一下，下次再试吧。" % enemy_spirit.display_name
	GameState.set_message(String(battle_result.capture_message))
	battle_state_changed.emit()
	return "failed"

func close_battle_result() -> void:
	if current_phase == BattlePhase.EXITING:
		return
	_cancel_action_timeout()
	pending_result = null
	current_phase = BattlePhase.EXITING
	battle_state = _default_battle_state()
	battle_result = _default_battle_result()
	_result_finalized = false
	_input_consumed_this_turn = false
	current_phase = BattlePhase.NONE
	GameState.clear_encounter()
	GameState.close_panel()
	battle_state_changed.emit()

func _set_phase(phase: BattlePhase) -> void:
	current_phase = phase
	match phase:
		BattlePhase.NONE, BattlePhase.INTRO, BattlePhase.EXITING:
			battle_state.status = "idle"
		BattlePhase.PLAYER_CHOOSE, BattlePhase.RESOLVING_PLAYER, BattlePhase.RESOLVING_ENEMY, BattlePhase.CHECKING_RESULT:
			battle_state.status = "active"
		BattlePhase.VICTORY, BattlePhase.CAPTURE:
			battle_state.status = "won"
		BattlePhase.DEFEAT:
			battle_state.status = "lost"

func _prepare_enemy_action(player_spirit: SpiritData, enemy_spirit: SpiritData, player_pet: Dictionary) -> void:
	var enemy_skill: SpiritSkill = _pick_enemy_skill(enemy_spirit, int(battle_state.enemy_hp), int(GameCatalog.get_stats(enemy_spirit, int(battle_state.enemy_level)).hp))
	pending_result = _calculate_enemy_action(enemy_spirit, player_spirit, enemy_skill, player_pet)
	_set_phase(BattlePhase.RESOLVING_ENEMY)
	_start_action_timeout()
	battle_state_changed.emit()

func _calculate_player_action(player_spirit: SpiritData, enemy_spirit: SpiritData, pet: Dictionary, skill: SpiritSkill) -> BattleActionResult:
	var result: BattleActionResult = BattleActionResult.new()
	result.attacker_side = "player"
	result.defender_side = "enemy"
	result.skill = skill
	result.skill_display_name = skill.display_name if skill.display_name != "" else skill.skill_name
	result.attacker_hp_before = int(pet.current_hp)
	result.defender_hp_before = int(battle_state.enemy_hp)
	result.is_heal = skill.skill_type == "heal"
	var calc: Dictionary = GameCatalog.calculate_skill_result(player_spirit, int(battle_state.player_level), enemy_spirit, int(battle_state.enemy_level), int(battle_state.enemy_hp), int(pet.current_hp), skill)
	if result.is_heal:
		result.heal = int(calc.heal)
		result.attacker_hp_after = int(calc.next_attacker_hp)
		result.defender_hp_after = result.defender_hp_before
		result.guard_gained = 1
		result.log_messages.append("%s使用%s，恢复%d点生命。" % [player_spirit.display_name, result.skill_display_name, result.heal])
	else:
		result.damage = int(calc.damage)
		result.multiplier = float(calc.multiplier)
		result.defender_hp_after = int(calc.next_defender_hp)
		result.attacker_hp_after = result.attacker_hp_before
		result.log_messages.append("%s使用%s，造成%d点伤害。" % [player_spirit.display_name, result.skill_display_name, result.damage])
		if result.multiplier > 1.0:
			result.log_messages.append("属性很合适！")
		elif result.multiplier < 1.0:
			result.log_messages.append("属性有点吃力。")
	result.defender_defeated = not result.is_heal and result.defender_hp_after <= 0
	result.new_energy = 0 if skill.skill_role == "ultimate" else min(100, int(battle_state.player_energy) + 34)
	return result

func _calculate_enemy_action(enemy_spirit: SpiritData, player_spirit: SpiritData, enemy_skill: SpiritSkill, player_pet: Dictionary) -> BattleActionResult:
	var result: BattleActionResult = BattleActionResult.new()
	result.attacker_side = "enemy"
	result.defender_side = "player"
	result.skill = enemy_skill
	result.skill_display_name = enemy_skill.display_name if enemy_skill.display_name != "" else enemy_skill.skill_name
	result.attacker_hp_before = int(battle_state.enemy_hp)
	result.defender_hp_before = int(player_pet.current_hp)
	result.is_heal = enemy_skill.skill_type == "heal"
	var calc: Dictionary = GameCatalog.calculate_skill_result(enemy_spirit, int(battle_state.enemy_level), player_spirit, int(battle_state.player_level), int(player_pet.current_hp), int(battle_state.enemy_hp), enemy_skill)
	if result.is_heal:
		result.heal = int(calc.heal)
		result.attacker_hp_after = int(calc.next_attacker_hp)
		result.defender_hp_after = result.defender_hp_before
		result.log_messages.append("野外的%s使用%s，恢复%d点生命。" % [enemy_spirit.display_name, result.skill_display_name, result.heal])
	else:
		result.damage = int(calc.damage)
		result.multiplier = float(calc.multiplier)
		if int(battle_state.player_guard_turns) > 0:
			result.damage = max(1, int(ceil(float(result.damage) * 0.55)))
			result.guard_consumed = true
		result.defender_hp_after = max(0, result.defender_hp_before - result.damage)
		result.attacker_hp_after = result.attacker_hp_before
		result.new_energy = min(100, int(battle_state.player_energy) + 20)
		result.log_messages.append("野外的%s使用%s，造成%d点伤害。" % [enemy_spirit.display_name, result.skill_display_name, result.damage])
	result.defender_defeated = not result.is_heal and result.defender_hp_after <= 0
	return result

func _pick_enemy_skill(enemy_spirit: SpiritData, enemy_hp: int, enemy_max_hp: int) -> SpiritSkill:
	if enemy_hp < int(enemy_max_hp * 0.35):
		for skill in enemy_spirit.skills:
			if skill.skill_role == "guard":
				return skill
	for skill in enemy_spirit.skills:
		if skill.skill_role == "element":
			return skill
	return enemy_spirit.skills[0]

func _start_action_timeout() -> void:
	_cancel_action_timeout()
	_action_timer = get_tree().create_timer(ACTION_TIMEOUT_SECONDS)
	_action_timer.timeout.connect(_on_action_timeout)

func _cancel_action_timeout() -> void:
	if _action_timer != null:
		if _action_timer.timeout.is_connected(_on_action_timeout):
			_action_timer.timeout.disconnect(_on_action_timeout)
		_action_timer = null

func _on_action_timeout() -> void:
	presentation_timed_out.emit()
	match current_phase:
		BattlePhase.RESOLVING_PLAYER:
			apply_player_result()
		BattlePhase.RESOLVING_ENEMY:
			apply_enemy_result()
		_:
			pass

func _finish_battle(player_won: bool) -> void:
	if _result_finalized:
		return
	_result_finalized = true
	_cancel_action_timeout()
	pending_result = null
	var player_spirit: SpiritData = GameCatalog.get_spirit_by_id(String(battle_state.player_spirit_id))
	var enemy_spirit: SpiritData = GameCatalog.get_spirit_by_id(String(battle_state.enemy_spirit_id))
	var player_pet: Dictionary = SaveManager.get_pet_state(String(battle_state.player_spirit_id))
	if player_spirit == null or enemy_spirit == null or player_pet.is_empty():
		return
	if player_won:
		var reward: int = GameCatalog.exp_reward(int(battle_state.enemy_level), enemy_spirit.rarity)
		var level_messages: Array[String] = _grant_battle_exp(player_spirit, player_pet, reward)
		battle_result = {"status": "won", "player_name": player_spirit.display_name, "player_level": int(player_pet.level), "player_hp": int(player_pet.current_hp), "player_max_hp": int(GameCatalog.get_stats(player_spirit, int(player_pet.level)).hp), "enemy_name": enemy_spirit.display_name, "enemy_level": int(battle_state.enemy_level), "enemy_spirit_id": enemy_spirit.spirit_id, "exp_gained": reward, "level_messages": level_messages, "capture_eligible": not SaveManager.has_captured(enemy_spirit.spirit_id), "capture_already_owned": SaveManager.has_captured(enemy_spirit.spirit_id), "capture_status": "idle", "capture_ball": {}, "capture_chance": 0.0, "capture_attempted": false, "capture_message": "可以进行一次战后收服。", "equipment_drop": "", "message": "挑战胜利！"}
		GameState.set_message("%s获得%d点经验。" % [player_spirit.display_name, reward])
		SaveManager.save_now()
		_set_phase(BattlePhase.VICTORY)
	else:
		player_pet.current_hp = 0
		SaveManager.update_pet_state(player_spirit.spirit_id, player_pet, false)
		battle_result = {"status": "lost", "player_name": player_spirit.display_name, "player_level": int(player_pet.level), "player_hp": 0, "player_max_hp": int(GameCatalog.get_stats(player_spirit, int(player_pet.level)).hp), "enemy_name": enemy_spirit.display_name, "enemy_level": int(battle_state.enemy_level), "enemy_spirit_id": enemy_spirit.spirit_id, "exp_gained": 0, "level_messages": [], "capture_eligible": false, "capture_already_owned": SaveManager.has_captured(enemy_spirit.spirit_id), "capture_status": "locked", "capture_ball": {}, "capture_chance": 0.0, "capture_attempted": false, "capture_message": "回小屋恢复一下，再来试试。", "equipment_drop": "", "message": "挑战失败。"}
		GameState.set_message("挑战失败也没关系，图鉴和入住记录都不会丢。")
		SaveManager.save_now()
		_set_phase(BattlePhase.DEFEAT)
	GameState.current_panel = "battle_result"
	GameState.ui_state_changed.emit(GameState.current_panel)
	battle_state_changed.emit()

func _grant_battle_exp(player_spirit: SpiritData, pet: Dictionary, reward: int) -> Array[String]:
	var messages: Array[String] = []
	pet.exp = int(pet.exp) + reward
	var previous_level: int = int(pet.level)
	while int(pet.level) < GameCatalog.MAX_LEVEL:
		var need: int = GameCatalog.exp_to_next(int(pet.level), player_spirit.rarity)
		if need <= 0 or int(pet.exp) < need:
			break
		pet.exp = int(pet.exp) - need
		pet.level = int(pet.level) + 1
		messages.append("%s升到Lv.%d啦。" % [player_spirit.display_name, int(pet.level)])
	if int(pet.level) != previous_level:
		pet.current_hp = int(GameCatalog.get_stats(player_spirit, int(pet.level)).hp)
	SaveManager.update_pet_state(player_spirit.spirit_id, pet, false)
	return messages

func _append_log(line: String) -> void:
	var log: Array = battle_state.log
	log.push_front(line)
	if log.size() > 6:
		log.resize(6)
	battle_state.log = log

func _default_battle_state() -> Dictionary:
	return {"status": "idle", "habitat_id": "", "player_spirit_id": "", "enemy_spirit_id": "", "player_level": 1, "enemy_level": 1, "enemy_hp": 0, "player_energy": 0, "player_guard_turns": 0, "player_position_slot": "center", "log": []}

func _default_battle_result() -> Dictionary:
	return {"status": "idle", "player_name": "", "player_level": 1, "player_hp": 0, "player_max_hp": 0, "enemy_name": "", "enemy_level": 1, "enemy_spirit_id": "", "exp_gained": 0, "level_messages": [], "capture_eligible": false, "capture_already_owned": false, "capture_status": "locked", "capture_ball": {}, "capture_chance": 0.0, "capture_attempted": false, "capture_message": "", "equipment_drop": "", "message": ""}
