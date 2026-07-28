extends Node2D

const FIELD_SCENES: Dictionary = {
	"grassland": "res://scenes/battle/fields/battlefield_grassland.tscn",
	"pond": "res://scenes/battle/fields/battlefield_pond.tscn",
	"warmstone": "res://scenes/battle/fields/battlefield_warmstone.tscn",
	"windmill": "res://scenes/battle/fields/battlefield_windmill.tscn",
	"cave": "res://scenes/battle/fields/battlefield_cave.tscn",
	"cloud": "res://scenes/battle/fields/battlefield_cloud.tscn"
}

const SPIRIT_TEXTURES: Dictionary = {
	"leafbun": "res://assets/spirits/01_ye_tuantuan_叶团团.png",
	"sproutdeer": "res://assets/spirits/02_ya_jiaolu_芽角鹿.png",
	"vinerabbit": "res://assets/spirits/03_teng_ertu_藤耳兔.png",
	"bloomwhale": "res://assets/spirits/04_hua_mianjing_花眠鲸.png",
	"bubblepup": "res://assets/spirits/05_paopao_wang_泡泡汪.png",
	"moonfish": "res://assets/spirits/06_yue_qiyu_月鳍鱼.png",
	"rainseal": "res://assets/spirits/07_yu_ling_haibao_雨铃海豹.png",
	"starjelly": "res://assets/spirits/08_xing_mian_shuimu_星眠水母.png",
	"emberfox": "res://assets/spirits/emberfox_clean/processed/emberfox-1.png",
	"lanterncub": "res://assets/spirits/10_deng_rongxiong_灯绒熊.png",
	"candlemoth": "res://assets/spirits/11_zhu_chie_烛翅蛾.png",
	"sunlion": "res://assets/spirits/12_ri_mianshi_日冕狮.png",
	"sparkmouse": "res://assets/spirits/13_shan_doushu_闪豆鼠.png",
	"bellvolt": "res://assets/spirits/14_ling_dianmao_铃电猫.png",
	"coilowl": "res://assets/spirits/15_xianquan_gu_线圈咕.png",
	"stormalpaca": "res://assets/spirits/16_lei_rongtuo_雷绒驼.png",
	"pebbletot": "res://assets/spirits/17_yuan_shizai_圆石仔.png",
	"mudturtle": "res://assets/spirits/18_ni_ke_gui_泥壳龟.png",
	"crystalbadger": "res://assets/spirits/19_jing_bi_huan_晶鼻獾.png",
	"mountainseed": "res://assets/spirits/20_shan_xinzhong_山心种.png",
	"cloudchick": "res://assets/spirits/21_yun_tuanjiu_云团啾.png",
	"kitehare": "res://assets/spirits/22_fengzheng_tu_风筝兔.png",
	"whistlecrane": "res://assets/spirits/23_shao_yuhe_哨羽鹤.png",
	"auroradrake": "res://assets/spirits/24_jiguang_xiaolong_极光小龙.png"
}

const ELEMENT_COLORS: Dictionary = {
	"grass": Color(0.47, 0.72, 0.29, 1),
	"water": Color(0.29, 0.55, 0.78, 1),
	"fire": Color(0.88, 0.4, 0.22, 1),
	"electric": Color(0.95, 0.82, 0.18, 1),
	"earth": Color(0.62, 0.45, 0.28, 1),
	"wind": Color(0.55, 0.72, 0.82, 1)
}

const BASE_VIEW_SIZE: Vector2 = Vector2(1280.0, 720.0)
const COMMAND_PANEL_HEIGHT: float = 260.0
const STATUS_NORMAL_STYLE: StyleBox = preload("res://resources/themes/battle/battle_status_normal.tres")
const STATUS_ACTIVE_STYLE: StyleBox = preload("res://resources/themes/battle/battle_status_active.tres")
const SKILL_SELECTED_STYLE: StyleBox = preload("res://resources/themes/battle/battle_skill_selected.tres")
const SKILL_DISABLED_STYLE: StyleBox = preload("res://resources/themes/battle/battle_skill_disabled.tres")
const PLAYER_HOME_RATIO: Vector2 = Vector2(0.30, 0.65)
const ENEMY_HOME_RATIO: Vector2 = Vector2(0.64, 0.40)

@onready var battle_world: Node2D = $BattleWorld
@onready var field_mount: Node2D = $BattleWorld/FieldMount
@onready var player_spirit: BattleActor = $BattleWorld/PlayerActor
@onready var enemy_spirit: BattleActor = $BattleWorld/EnemyActor
@onready var effect_layer: Node2D = $BattleWorld/EffectLayer
@onready var camera: Camera2D = $Camera2D

@onready var battle_ui: Control = $CanvasLayer/BattleUI
@onready var player_status_card: PanelContainer = $CanvasLayer/BattleUI/PlayerStatusCard
@onready var player_name_label: Label = $CanvasLayer/BattleUI/PlayerStatusCard/StatusMargin/StatusBox/PlayerHeader/PlayerName
@onready var player_level_label: Label = $CanvasLayer/BattleUI/PlayerStatusCard/StatusMargin/StatusBox/PlayerHeader/PlayerLevel
@onready var player_element_icon: Label = $CanvasLayer/BattleUI/PlayerStatusCard/StatusMargin/StatusBox/PlayerHeader/PlayerElementIcon
@onready var player_guard_badge: Label = $CanvasLayer/BattleUI/PlayerStatusCard/StatusMargin/StatusBox/PlayerHeader/PlayerGuardBadge
@onready var player_hp_bar: TextureProgressBar = $CanvasLayer/BattleUI/PlayerStatusCard/StatusMargin/StatusBox/PlayerHpRow/PlayerHpBar
@onready var player_hp_value: Label = $CanvasLayer/BattleUI/PlayerStatusCard/StatusMargin/StatusBox/PlayerHpRow/PlayerHpValue
@onready var player_energy_bar: TextureProgressBar = $CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/EnergyDisplay/EnergyMargin/EnergyBox/EnergyBar
@onready var player_energy_value: Label = $CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/EnergyDisplay/EnergyMargin/EnergyBox/EnergyHeader/EnergyValue

@onready var enemy_status_card: PanelContainer = $CanvasLayer/BattleUI/EnemyStatusCard
@onready var enemy_name_label: Label = $CanvasLayer/BattleUI/EnemyStatusCard/StatusMargin/StatusBox/EnemyHeader/EnemyName
@onready var enemy_level_label: Label = $CanvasLayer/BattleUI/EnemyStatusCard/StatusMargin/StatusBox/EnemyHeader/EnemyLevel
@onready var enemy_element_icon: Label = $CanvasLayer/BattleUI/EnemyStatusCard/StatusMargin/StatusBox/EnemyHeader/EnemyElementIcon
@onready var enemy_hp_bar: TextureProgressBar = $CanvasLayer/BattleUI/EnemyStatusCard/StatusMargin/StatusBox/EnemyHpRow/EnemyHpBar
@onready var enemy_hp_value: Label = $CanvasLayer/BattleUI/EnemyStatusCard/StatusMargin/StatusBox/EnemyHpRow/EnemyHpValue

@onready var command_panel: PanelContainer = $CanvasLayer/BattleUI/CommandPanel
@onready var skill_grid: GridContainer = $CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/SkillArea/SkillGrid
@onready var position_buttons: Array[Button] = [
	$CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/SkillArea/PositionRow/PositionLeft,
	$CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/SkillArea/PositionRow/PositionCenter,
	$CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/SkillArea/PositionRow/PositionRight
]
@onready var round_hint: Label = $CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/BattleInfo/RoundHint
@onready var battle_log: Label = $CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/BattleInfo/BattleLog
@onready var skill_description: Label = $CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/SkillArea/SkillDescriptionPanel/SkillDescriptionLine
@onready var element_advantage: Label = $CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/BattleInfo/ElementAdvantage
@onready var message_toast: PanelContainer = $CanvasLayer/BattleUI/MessageToast
@onready var message_toast_text: Label = $CanvasLayer/BattleUI/MessageToast/Text
@onready var turn_tip: PanelContainer = $CanvasLayer/BattleUI/TurnTip
@onready var turn_tip_text: Label = $CanvasLayer/BattleUI/TurnTip/Text

@onready var result_panel: PanelContainer = $CanvasLayer/BattleUI/ResultPanel
@onready var result_title: Label = $CanvasLayer/BattleUI/ResultPanel/ResultMargin/ResultBox/ResultTitle
@onready var result_summary: Label = $CanvasLayer/BattleUI/ResultPanel/ResultMargin/ResultBox/ResultSummary
@onready var capture_label: Label = $CanvasLayer/BattleUI/ResultPanel/ResultMargin/ResultBox/CaptureLabel
@onready var draw_button: Button = $CanvasLayer/BattleUI/ResultPanel/ResultMargin/ResultBox/ResultActions/DrawButton
@onready var capture_button: Button = $CanvasLayer/BattleUI/ResultPanel/ResultMargin/ResultBox/ResultActions/CaptureButton
@onready var return_button: Button = $CanvasLayer/BattleUI/ResultPanel/ResultMargin/ResultBox/ReturnButton
@onready var capture_panel: PanelContainer = $CanvasLayer/BattleUI/CapturePanel

@onready var battle_presentation: BattlePresentation = $BattlePresentation
@onready var floating_text_layer: Control = $CanvasLayer/BattleUI/FloatingTextLayer

var skill_buttons: Array[Button] = []
var _current_selected_skill: SpiritSkill
var _selected_skill_index: int = -1
var _exiting: bool = false
var _loaded_habitat_id: String = ""
var _active_field: Battlefield = null
var _last_intro_enemy_id: String = ""
var _toast_tween: Tween = null

func _ready() -> void:
	skill_buttons = [
		$CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/SkillArea/SkillGrid/SkillButton0,
		$CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/SkillArea/SkillGrid/SkillButton1,
		$CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/SkillArea/SkillGrid/SkillButton2,
		$CanvasLayer/BattleUI/CommandPanel/CommandMargin/CommandBody/SkillArea/SkillGrid/SkillButton3
	]
	player_spirit.set_target_height(242.0)
	enemy_spirit.set_target_height(214.0)
	_apply_world_layout()
	_load_battlefield()
	if not BattleManager.battle_state_changed.is_connected(_refresh):
		BattleManager.battle_state_changed.connect(_refresh)
	if not DisplayManager.profile_changed.is_connected(_apply_display_profile):
		DisplayManager.profile_changed.connect(_apply_display_profile)
	draw_button.pressed.connect(BattleManager.draw_capture_ball)
	capture_button.pressed.connect(BattleManager.try_capture_after_battle)
	return_button.pressed.connect(_return_to_map)
	for index in range(skill_buttons.size()):
		var skill_index: int = index
		var button: Button = skill_buttons[index]
		button.pressed.connect(func() -> void: BattleManager.use_skill(skill_index))
		button.mouse_entered.connect(func() -> void: _on_skill_hover(skill_index))
		button.mouse_exited.connect(func() -> void: _on_skill_unhover())
	for index in range(position_buttons.size()):
		var position_slot: String = ["left", "center", "right"][index]
		position_buttons[index].pressed.connect(func() -> void: BattleManager.choose_player_position(position_slot))
	_apply_display_profile(DisplayManager.get_active_profile())
	battle_presentation.setup(player_spirit, enemy_spirit, player_hp_bar, enemy_hp_bar, player_hp_value, enemy_hp_value, floating_text_layer, effect_layer, camera)
	for button in skill_buttons:
		button.add_theme_stylebox_override("pressed", SKILL_SELECTED_STYLE)
		button.add_theme_stylebox_override("disabled", SKILL_DISABLED_STYLE)
	if not BattleManager.presentation_timed_out.is_connected(_on_presentation_timed_out):
		BattleManager.presentation_timed_out.connect(_on_presentation_timed_out)
	_refresh()


func _exit_tree() -> void:
	if BattleManager.battle_state_changed.is_connected(_refresh):
		BattleManager.battle_state_changed.disconnect(_refresh)
	if DisplayManager.profile_changed.is_connected(_apply_display_profile):
		DisplayManager.profile_changed.disconnect(_apply_display_profile)
	if BattleManager.presentation_timed_out.is_connected(_on_presentation_timed_out):
		BattleManager.presentation_timed_out.disconnect(_on_presentation_timed_out)

func _load_battlefield() -> void:
	var habitat_id: String = String(BattleManager.battle_state.get("habitat_id", "grassland"))
	if habitat_id == "":
		habitat_id = "grassland"
	if habitat_id == _loaded_habitat_id and is_instance_valid(_active_field):
		return
	for child in field_mount.get_children():
		field_mount.remove_child(child)
		child.queue_free()
	_active_field = null
	if not FIELD_SCENES.has(habitat_id):
		push_error("未配置独立战场：%s" % habitat_id)
		habitat_id = "grassland"
	var field_path: String = String(FIELD_SCENES[habitat_id])
	var packed_field: PackedScene = load(field_path) as PackedScene
	if packed_field == null:
		push_error("战场场景加载失败：%s" % field_path)
		return
	var field: Node = packed_field.instantiate()
	field_mount.add_child(field)
	_active_field = field as Battlefield
	if _active_field == null:
		push_error("战场根节点必须使用 Battlefield：%s" % field_path)
	else:
		var issues: PackedStringArray = _active_field.validate_contract(habitat_id)
		if not issues.is_empty():
			push_error("战场契约错误 %s：%s" % [field_path, "；".join(issues)])
	_loaded_habitat_id = habitat_id

func _apply_world_layout() -> void:
	var view_size: Vector2 = get_viewport_rect().size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		view_size = BASE_VIEW_SIZE
	camera.position = view_size * 0.5
	battle_world.position = Vector2.ZERO
	var field_scale: Vector2 = Vector2(view_size.x / BASE_VIEW_SIZE.x, view_size.y / BASE_VIEW_SIZE.y)
	field_mount.scale = field_scale
	var slot: String = String(BattleManager.battle_state.get("player_position_slot", "center"))
	if slot not in ["left", "center", "right"]:
		slot = "center"
	if is_instance_valid(_active_field):
		player_spirit.set_home_position(_active_field.get_player_spawn(slot) * field_scale)
		enemy_spirit.set_home_position(_active_field.get_enemy_spawn() * field_scale)
	else:
		var slot_offset: float = {"left": -96.0, "center": 0.0, "right": 96.0}.get(slot, 0.0)
		player_spirit.set_home_position(Vector2(view_size.x * PLAYER_HOME_RATIO.x + slot_offset, view_size.y - COMMAND_PANEL_HEIGHT - 58.0))
		enemy_spirit.set_home_position(Vector2(view_size.x * ENEMY_HOME_RATIO.x, view_size.y * ENEMY_HOME_RATIO.y))

func _refresh() -> void:
	_load_battlefield()
	if not _is_presentation_playing():
		_apply_world_layout()
	var player_data: SpiritData = GameCatalog.get_spirit_by_id(String(BattleManager.battle_state.player_spirit_id))
	var enemy_data: SpiritData = GameCatalog.get_spirit_by_id(String(BattleManager.battle_state.enemy_spirit_id))
	if player_data == null or enemy_data == null:
		_show_missing_battle()
		return
	var player_pet: Dictionary = SaveManager.get_pet_state(player_data.spirit_id)
	if player_pet.is_empty():
		_show_missing_battle()
		return
	_set_actor_texture(player_spirit, player_data.spirit_id)
	_set_actor_texture(enemy_spirit, enemy_data.spirit_id)
	_show_intro_once(enemy_data)
	var player_stats: Dictionary = GameCatalog.get_stats(player_data, int(BattleManager.battle_state.player_level))
	var enemy_stats: Dictionary = GameCatalog.get_stats(enemy_data, int(BattleManager.battle_state.enemy_level))
	var player_hp: int = int(player_pet.current_hp)
	var player_max_hp: int = int(player_stats.hp)
	var enemy_hp: int = int(BattleManager.battle_state.enemy_hp)
	var enemy_max_hp: int = int(enemy_stats.hp)
	var player_level: int = int(BattleManager.battle_state.player_level)
	var enemy_level: int = int(BattleManager.battle_state.enemy_level)
	player_name_label.text = player_data.display_name
	player_level_label.text = "Lv.%d" % player_level
	player_element_icon.text = _element_label(player_data.element)
	player_element_icon.add_theme_color_override("font_color", ELEMENT_COLORS.get(player_data.element, Color.WHITE))
	if not _is_presentation_playing():
		_set_bar(player_hp_bar, player_hp, player_max_hp)
		player_hp_value.text = "%d / %d" % [player_hp, player_max_hp]
	_set_bar(player_energy_bar, int(BattleManager.battle_state.player_energy), 100)
	player_energy_value.text = "%d / 100" % int(BattleManager.battle_state.player_energy)
	if int(BattleManager.battle_state.player_guard_turns) > 0:
		player_guard_badge.text = "[守护]"
	else:
		player_guard_badge.text = ""
	enemy_name_label.text = enemy_data.display_name
	enemy_level_label.text = "Lv.%d" % enemy_level
	enemy_element_icon.text = _element_label(enemy_data.element)
	enemy_element_icon.add_theme_color_override("font_color", ELEMENT_COLORS.get(enemy_data.element, Color.WHITE))
	if not _is_presentation_playing():
		_set_bar(enemy_hp_bar, enemy_hp, enemy_max_hp)
		enemy_hp_value.text = "%d / %d" % [enemy_hp, enemy_max_hp]
	_refresh_battle_info(player_data, enemy_data)
	_refresh_skill_buttons(player_data)
	_refresh_result_panel()
	_refresh_status_card_styles()
	_try_start_presentation()

func _refresh_battle_info(player_data: SpiritData, enemy_data: SpiritData) -> void:
	turn_tip.visible = BattleManager.current_phase == BattleManager.BattlePhase.PLAYER_CHOOSE or BattleManager.current_phase == BattleManager.BattlePhase.RESOLVING_ENEMY
	turn_tip_text.text = "玩家回合" if BattleManager.current_phase == BattleManager.BattlePhase.PLAYER_CHOOSE else "%s回合" % enemy_data.display_name
	match BattleManager.current_phase:
		BattleManager.BattlePhase.PLAYER_CHOOSE:
			round_hint.text = "选择左 / 中 / 右站位" if not BattleManager.is_player_position_ready() else "站位已确定，选择技能"
		BattleManager.BattlePhase.RESOLVING_PLAYER:
			round_hint.text = "你的萌灵正在行动..."
		BattleManager.BattlePhase.RESOLVING_ENEMY:
			round_hint.text = "对手正在行动..."
		BattleManager.BattlePhase.VICTORY:
			round_hint.text = "挑战胜利！"
		BattleManager.BattlePhase.DEFEAT:
			round_hint.text = "挑战结束"
		_:
			round_hint.text = ""
	var log: Array = BattleManager.battle_state.log
	var log_lines: Array[String] = []
	for i in range(min(3, log.size())):
		log_lines.append(String(log[i]))
	battle_log.text = "\n".join(PackedStringArray(log_lines))
	if _current_selected_skill != null:
		_show_skill_detail(_current_selected_skill, player_data, enemy_data)
	else:
		skill_description.text = ""
		element_advantage.text = ""

func _show_skill_detail(skill: SpiritSkill, player_data: SpiritData, enemy_data: SpiritData) -> void:
	var desc: String = skill.description
	if desc == "":
		desc = "%s · %s" % [_skill_type_label(skill.skill_type), _skill_role_label(skill.skill_role)]
	skill_description.text = "%s: %s" % [skill.display_name if skill.display_name != "" else skill.skill_name, desc]
	var player_element: String = player_data.element
	var enemy_element: String = enemy_data.element
	var skill_element: String = skill.element if skill.element != "" else player_element
	var mult: float = GameCatalog.element_multiplier(skill_element, enemy_element)
	if mult > 1.0:
		element_advantage.text = "%s 克制 %s！伤害 ×%.1f" % [_element_label(skill_element), _element_label(enemy_element), mult]
	elif mult < 1.0:
		element_advantage.text = "%s 对 %s 效果不佳，伤害 ×%.2f" % [_element_label(skill_element), _element_label(enemy_element), mult]
	else:
		element_advantage.text = "属性正常"

func _on_skill_hover(skill_index: int) -> void:
	var player_data: SpiritData = GameCatalog.get_spirit_by_id(String(BattleManager.battle_state.player_spirit_id))
	var enemy_data: SpiritData = GameCatalog.get_spirit_by_id(String(BattleManager.battle_state.enemy_spirit_id))
	if player_data == null or enemy_data == null:
		return
	if skill_index < 0 or skill_index >= player_data.skills.size():
		return
	_current_selected_skill = player_data.skills[skill_index]
	_show_skill_detail(_current_selected_skill, player_data, enemy_data)

func _on_skill_unhover() -> void:
	_current_selected_skill = null
	skill_description.text = ""
	element_advantage.text = ""

func _show_intro_once(enemy_data: SpiritData) -> void:
	if enemy_data.spirit_id == _last_intro_enemy_id:
		return
	_last_intro_enemy_id = enemy_data.spirit_id
	message_toast_text.text = "野外的%s出现了！" % enemy_data.display_name
	message_toast.visible = true
	message_toast.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.4)
	_toast_tween.tween_property(message_toast, "modulate:a", 0.0, 0.45)
	_toast_tween.tween_callback(func() -> void: message_toast.visible = false)

func _show_missing_battle() -> void:
	player_name_label.text = "还没有挑战"
	enemy_name_label.text = ""
	battle_log.text = "从地图上遇见萌灵后，再进入挑战。"
	round_hint.text = ""
	for button in skill_buttons:
		button.disabled = true
	result_panel.visible = true
	result_title.text = "没有挑战"
	result_summary.text = "请返回地图继续探索。"
	capture_label.text = ""
	draw_button.disabled = true
	capture_button.disabled = true

func _set_actor_texture(actor: BattleActor, spirit_id: String) -> void:
	var path: String = String(SPIRIT_TEXTURES.get(spirit_id, ""))
	if path == "":
		actor.set_spirit_texture(null)
		return
	var texture: Texture2D = load(path) as Texture2D
	actor.set_spirit_id(spirit_id, texture)

func _is_presentation_playing() -> bool:
	return battle_presentation != null and battle_presentation.is_playing()

func _try_start_presentation() -> void:
	if battle_presentation == null:
		return
	if battle_presentation.is_playing():
		return
	if BattleManager.pending_result == null:
		return
	match BattleManager.current_phase:
		BattleManager.BattlePhase.RESOLVING_PLAYER:
			battle_presentation.play_action(BattleManager.pending_result, _on_player_presentation_done)
		BattleManager.BattlePhase.RESOLVING_ENEMY:
			battle_presentation.play_action(BattleManager.pending_result, _on_enemy_presentation_done)
		_:
			pass

func _on_player_presentation_done() -> void:
	BattleManager.apply_player_result()

func _on_enemy_presentation_done() -> void:
	BattleManager.apply_enemy_result()

func _on_presentation_timed_out() -> void:
	if battle_presentation != null:
		battle_presentation.force_cancel()

func _set_bar(bar: TextureProgressBar, value: int, max_value: int) -> void:
	bar.max_value = max(1, max_value)
	bar.value = clamp(value, 0, max_value)

func _refresh_status_card_styles() -> void:
	var player_active: bool = BattleManager.current_phase == BattleManager.BattlePhase.PLAYER_CHOOSE
	var enemy_active: bool = BattleManager.current_phase == BattleManager.BattlePhase.RESOLVING_ENEMY
	player_status_card.add_theme_stylebox_override("panel", STATUS_ACTIVE_STYLE if player_active else STATUS_NORMAL_STYLE)
	enemy_status_card.add_theme_stylebox_override("panel", STATUS_ACTIVE_STYLE if enemy_active else STATUS_NORMAL_STYLE)

func _refresh_skill_buttons(player_data: SpiritData) -> void:
	var can_act: bool = BattleManager.current_phase == BattleManager.BattlePhase.PLAYER_CHOOSE
	var position_ready: bool = BattleManager.is_player_position_ready()
	var selected_slot: String = String(BattleManager.battle_state.get("player_position_slot", ""))
	for index in range(position_buttons.size()):
		var slot: String = ["left", "center", "right"][index]
		position_buttons[index].disabled = not can_act
		position_buttons[index].button_pressed = slot == selected_slot
	for index in range(skill_buttons.size()):
		var button: Button = skill_buttons[index]
		if index < player_data.skills.size():
			var skill: SpiritSkill = player_data.skills[index]
			button.visible = true
			var display_name: String = skill.display_name if skill.display_name != "" else skill.skill_name
			var icons: Array[String] = ["💧", "💦", "🫧", "🌙"]
			var subtitle: String = "%s  %s · %s" % [icons[index], _skill_role_label(skill.skill_role), _skill_type_label(skill.skill_type)]
			if skill.power > 0:
				subtitle += " · 威力%d" % skill.power
			if skill.skill_role == "ultimate":
				button.text = "%s\n%s\n需要 100 大招能量" % [display_name, subtitle]
			else:
				button.text = "%s\n%s" % [display_name, subtitle]
			var is_ultimate_locked: bool = skill.skill_role == "ultimate" and int(BattleManager.battle_state.player_energy) < 100
			button.disabled = not can_act or not position_ready or is_ultimate_locked
		else:
			button.visible = false

func _refresh_result_panel() -> void:
	var has_result: bool = BattleManager.current_phase == BattleManager.BattlePhase.VICTORY or BattleManager.current_phase == BattleManager.BattlePhase.DEFEAT
	result_panel.visible = has_result
	capture_panel.visible = false
	if not has_result:
		return
	result_title.text = "挑战胜利" if BattleManager.current_phase == BattleManager.BattlePhase.VICTORY else "挑战结束"
	result_summary.text = "%s\n经验 +%d" % [String(BattleManager.battle_result.message), int(BattleManager.battle_result.exp_gained)]
	if not Array(BattleManager.battle_result.level_messages).is_empty():
		result_summary.text += "\n" + "\n".join(PackedStringArray(BattleManager.battle_result.level_messages))
	capture_label.text = String(BattleManager.battle_result.capture_message)
	var ball_awarded: bool = bool(BattleManager.battle_result.capture_ball_awarded)
	draw_button.text = "已获得收服球" if ball_awarded else "重试奖励结算"
	draw_button.disabled = BattleManager.battle_result.status != "won" or bool(BattleManager.battle_result.capture_attempted) or ball_awarded or not Dictionary(BattleManager.battle_result.capture_ball).is_empty()
	capture_button.disabled = BattleManager.battle_result.status != "won" or bool(BattleManager.battle_result.capture_attempted) or bool(BattleManager.battle_result.capture_already_owned) or Dictionary(BattleManager.battle_result.capture_ball).is_empty()

func _return_to_map() -> void:
	if _exiting:
		return
	_exiting = true
	var scene_path: String = BattleManager.return_scene_path
	BattleManager.close_battle_result()
	var error_code: int = get_tree().change_scene_to_file(scene_path)
	if error_code != OK:
		get_tree().change_scene_to_file("res://scenes/world/test_world.tscn")

func _skill_type_label(skill_type: String) -> String:
	match skill_type:
		"physical":
			return "物理"
		"magic":
			return "魔法"
		"heal":
			return "治愈"
		_:
			return skill_type

func _skill_role_label(skill_role: String) -> String:
	match skill_role:
		"basic":
			return "普通"
		"element":
			return "属性"
		"guard":
			return "守护"
		"ultimate":
			return "大招"
		_:
			return skill_role

func _element_label(element: String) -> String:
	match element:
		"grass":
			return "草"
		"water":
			return "水"
		"fire":
			return "火"
		"electric":
			return "电"
		"earth":
			return "土"
		"wind":
			return "风"
		_:
			return element

func _apply_display_profile(profile: DeviceProfile) -> void:
	var ui_scale: float = profile.ui_scale if profile != null else 1.0
	var font_scale: float = profile.font_scale if profile != null else 1.0
	for button in skill_buttons:
		button.custom_minimum_size = Vector2(194, 92) * ui_scale
		button.add_theme_font_size_override("font_size", int(round(17 * font_scale)))
	for button in position_buttons:
		button.custom_minimum_size = Vector2(96, 38) * ui_scale
		button.add_theme_font_size_override("font_size", int(round(15 * font_scale)))
	player_name_label.add_theme_font_size_override("font_size", int(round(20 * font_scale)))
	player_level_label.add_theme_font_size_override("font_size", int(round(18 * font_scale)))
	player_element_icon.add_theme_font_size_override("font_size", int(round(16 * font_scale)))
	player_guard_badge.add_theme_font_size_override("font_size", int(round(15 * font_scale)))
	enemy_name_label.add_theme_font_size_override("font_size", int(round(20 * font_scale)))
	enemy_level_label.add_theme_font_size_override("font_size", int(round(18 * font_scale)))
	enemy_element_icon.add_theme_font_size_override("font_size", int(round(16 * font_scale)))
	player_hp_bar.custom_minimum_size.y = int(round(20 * ui_scale))
	player_energy_bar.custom_minimum_size.y = int(round(16 * ui_scale))
	enemy_hp_bar.custom_minimum_size.y = int(round(20 * ui_scale))
	round_hint.add_theme_font_size_override("font_size", int(round(15 * font_scale)))
	battle_log.add_theme_font_size_override("font_size", int(round(15 * font_scale)))
	skill_description.add_theme_font_size_override("font_size", int(round(14 * font_scale)))
	element_advantage.add_theme_font_size_override("font_size", int(round(14 * font_scale)))
	message_toast_text.add_theme_font_size_override("font_size", int(round(22 * font_scale)))
	result_title.add_theme_font_size_override("font_size", int(round(30 * font_scale)))
	result_summary.add_theme_font_size_override("font_size", int(round(21 * font_scale)))
	capture_label.add_theme_font_size_override("font_size", int(round(21 * font_scale)))
	for button in [draw_button, capture_button, return_button]:
		button.custom_minimum_size.y = int(round(64 * ui_scale))
	if draw_button != null:
		draw_button.custom_minimum_size.x = int(round(210 * ui_scale))
	if capture_button != null:
		capture_button.custom_minimum_size.x = int(round(210 * ui_scale))