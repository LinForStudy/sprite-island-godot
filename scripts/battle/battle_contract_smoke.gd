extends Node

const FIELD_PATHS: Dictionary = {
	"grassland": "res://scenes/battle/fields/battlefield_grassland.tscn",
	"pond": "res://scenes/battle/fields/battlefield_pond.tscn",
	"warmstone": "res://scenes/battle/fields/battlefield_warmstone.tscn",
	"windmill": "res://scenes/battle/fields/battlefield_windmill.tscn",
	"cave": "res://scenes/battle/fields/battlefield_cave.tscn",
	"cloud": "res://scenes/battle/fields/battlefield_cloud.tscn"
}

var _failures: PackedStringArray = PackedStringArray()

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_position_gate()
	_check_capture_reward()
	await _check_battlefields()
	_check_battle_frame_catalog()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("BATTLE_CONTRACT_FAIL:%s" % failure)
		get_tree().quit(1)
		return
	print("BATTLE_CONTRACT_SMOKE_OK")
	get_tree().quit()

func _check_position_gate() -> void:
	var original_state: Dictionary = BattleManager.battle_state
	var original_result: Dictionary = BattleManager.battle_result
	var original_phase: int = BattleManager.current_phase
	var original_pending: BattleActionResult = BattleManager.pending_result
	var original_input_consumed: bool = BattleManager._input_consumed_this_turn
	BattleManager.battle_state = BattleManager._default_battle_state()
	BattleManager.battle_result = BattleManager._default_battle_result()
	BattleManager.current_phase = BattleManager.BattlePhase.PLAYER_CHOOSE
	BattleManager.pending_result = null
	BattleManager._input_consumed_this_turn = false
	BattleManager.use_skill(0)
	_expect(BattleManager.current_phase == BattleManager.BattlePhase.PLAYER_CHOOSE, "未选站位时技能不得改变回合阶段")
	_expect(BattleManager.pending_result == null, "未选站位时技能不得生成结算")
	_expect(not BattleManager.is_player_position_ready(), "新回合默认不得预选中央站位")
	_expect(BattleManager.choose_player_position("left"), "合法左侧站位应可选择")
	_expect(BattleManager.is_player_position_ready(), "选择站位后门禁应解除")
	var first_turn: int = int(BattleManager.battle_state.turn_number)
	BattleManager.call("_begin_player_turn")
	_expect(not BattleManager.is_player_position_ready(), "进入下一玩家回合必须重置站位")
	_expect(String(BattleManager.battle_state.player_position_slot) == "", "下一玩家回合不得保留旧站位")
	_expect(int(BattleManager.battle_state.turn_number) == first_turn + 1, "下一玩家回合编号应递增")
	BattleManager.battle_state = original_state
	BattleManager.battle_result = original_result
	BattleManager.current_phase = original_phase
	BattleManager.pending_result = original_pending
	BattleManager._input_consumed_this_turn = original_input_consumed

func _check_capture_reward() -> void:
	var original_save_data: Dictionary = SaveManager.save_data
	var original_persistence: bool = SaveManager.persistence_enabled
	var original_result: Dictionary = BattleManager.battle_result
	SaveManager.persistence_enabled = false
	SaveManager.save_data = SaveManager._default_save_data()
	BattleManager.battle_result = BattleManager._default_battle_result()
	BattleManager.battle_result.status = "won"
	BattleManager.battle_result.enemy_spirit_id = "leafbun"
	BattleManager.battle_result.enemy_name = "叶团团"
	BattleManager.battle_result.capture_eligible = true
	var awarded: bool = BattleManager._award_capture_ball()
	var ball: Dictionary = Dictionary(BattleManager.battle_result.capture_ball)
	var ball_id: String = String(ball.get("id", ""))
	_expect(awarded and bool(BattleManager.battle_result.capture_ball_awarded), "胜利必须自动发放一颗收服球")
	_expect(ball_id != "" and SaveManager.get_item_count(ball_id) == int(SaveManager.INITIAL_INVENTORY.get(ball_id, 0)) + 1, "收服球奖励必须写入背包")
	var count_after_award: int = SaveManager.get_item_count(ball_id)
	BattleManager.draw_capture_ball()
	_expect(SaveManager.get_item_count(ball_id) == count_after_award, "同一场胜利不得重复领取收服球")
	BattleManager.battle_result = original_result
	SaveManager.save_data = original_save_data
	SaveManager.persistence_enabled = original_persistence

func _check_battlefields() -> void:
	_expect(FIELD_PATHS.size() == 6, "必须配置六个独立战场")
	var signatures: Dictionary = {}
	for habitat_id in FIELD_PATHS:
		var scene_path: String = String(FIELD_PATHS[habitat_id])
		var packed: PackedScene = load(scene_path) as PackedScene
		if packed == null:
			_failures.append("战场无法加载：%s" % scene_path)
			continue
		var field: Battlefield = packed.instantiate() as Battlefield
		if field == null:
			_failures.append("战场根节点不是 Battlefield：%s" % scene_path)
			continue
		get_tree().root.add_child(field)
		await get_tree().process_frame
		var issues: PackedStringArray = field.validate_contract(String(habitat_id))
		for issue in issues:
			_failures.append("%s：%s" % [habitat_id, issue])
		var foundation: TileMapLayer = field.get_node_or_null("FoundationTiles") as TileMapLayer
		_expect(foundation != null and not foundation.get_used_cells().is_empty(), "%s 的 TileMap 地基不能为空" % habitat_id)
		_expect(not signatures.has(field.field_signature), "%s 与其他战场重复 field_signature" % habitat_id)
		signatures[field.field_signature] = habitat_id
		field.queue_free()
		await get_tree().process_frame

func _check_battle_frame_catalog() -> void:
	var spirits: Array[SpiritData] = GameCatalog.get_spirits()
	_expect(spirits.size() == 24, "战斗资源目录必须覆盖 24 个 spirit_id")
	var strict: bool = "--strict-battle-frames" in OS.get_cmdline_user_args()
	var pending_count: int = 0
	for spirit in spirits:
		var issues: PackedStringArray = GameCatalog.get_battle_frame_issues(spirit.spirit_id)
		if issues.is_empty():
			continue
		pending_count += 1
		print("BATTLE_FRAMES_PENDING:%s:%s" % [spirit.spirit_id, "；".join(issues)])
		if strict:
			for issue in issues:
				_failures.append(issue)
	for ready_spirit_id in ["leafbun", "emberfox"]:
		_expect(GameCatalog.get_battle_frame_issues(ready_spirit_id).is_empty(), "%s 的 18 帧必须满足 idle4/move4/attack4/hurt2/defeat4" % ready_spirit_id)
		var frames: SpriteFrames = GameCatalog.get_battle_frames(ready_spirit_id)
		if frames == null:
			continue
		for action in GameCatalog.REQUIRED_BATTLE_FRAME_COUNTS:
			_expect(frames.has_animation(StringName(action)) and frames.get_frame_count(StringName(action)) == int(GameCatalog.REQUIRED_BATTLE_FRAME_COUNTS[action]), "%s 的 %s 动作帧数不符合契约" % [ready_spirit_id, action])
	print("BATTLE_FRAME_CONTRACT:%d/24 ready, %d pending, strict=%s" % [24 - pending_count, pending_count, strict])

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)