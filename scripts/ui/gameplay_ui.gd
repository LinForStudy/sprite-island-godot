extends CanvasLayer

const BATTLE_SCENE_PATH: String = "res://scenes/battle/battle_scene.tscn"
const BASE_HUD_MARGIN: int = 24
const BASE_HUD_SPACING: int = 12
const BASE_LOCATION_CARD_SIZE: Vector2 = Vector2(228.0, 48.0)
const BASE_LOCATION_FONT: int = 24
const BASE_ACTION_BUTTON_SIZE: Vector2 = Vector2(56.0, 52.0)
const BASE_ACTION_ICON_WIDTH: int = 26
const BASE_TOAST_WIDTH: float = 264.0
const BASE_TOAST_TOP: float = 28.0
const BASE_TOAST_TITLE_FONT: int = 24
const BASE_TOAST_SUBTITLE_FONT: int = 20
const BASE_QUEST_CARD_WIDTH: float = 280.0
const BASE_QUEST_TITLE_FONT: int = 22
const BASE_QUEST_BODY_FONT: int = 19
const INTRO_FADE_IN: float = 0.35
const INTRO_HOLD: float = 2.0
const INTRO_FADE_OUT: float = 0.35
const BASE_PANEL_TITLE_FONT: int = 28
const BASE_PANEL_BODY_FONT: int = 20
const BASE_PANEL_STATUS_FONT: int = 19
const BASE_BUTTON_HEIGHT: int = 60
const BASE_LARGE_BUTTON_HEIGHT: int = 64
const BASE_DEX_LIST_SIZE: Vector2 = Vector2(320.0, 340.0)
const BASE_DEX_DETAIL_SIZE: Vector2 = Vector2(520.0, 340.0)
const BASE_HOME_LIST_SIZE: Vector2 = Vector2(320.0, 332.0)
const BASE_HOME_DETAIL_SIZE: Vector2 = Vector2(540.0, 332.0)

@onready var root: Control = $Root
@onready var hud_margin: MarginContainer = $Root/HUDMargin
@onready var screen_layout: VBoxContainer = $Root/HUDMargin/ScreenLayout
@onready var top_hud: HBoxContainer = $Root/HUDMargin/ScreenLayout/TopHUD
@onready var location_card: PanelContainer = $Root/HUDMargin/ScreenLayout/TopHUD/LocationCard
@onready var location_label: Label = $Root/HUDMargin/ScreenLayout/TopHUD/LocationCard/LocationPadding/LocationLabel
@onready var action_buttons: HBoxContainer = $Root/HUDMargin/ScreenLayout/TopHUD/ActionButtons
@onready var dex_button: Button = $Root/HUDMargin/ScreenLayout/TopHUD/ActionButtons/DexButton
@onready var home_button: Button = $Root/HUDMargin/ScreenLayout/TopHUD/ActionButtons/HomeButton
@onready var quest_card: PanelContainer = $Root/HUDMargin/ScreenLayout/BottomHUD/QuestCard
@onready var quest_title: Label = $Root/HUDMargin/ScreenLayout/BottomHUD/QuestCard/QuestPadding/QuestBox/QuestTitle
@onready var quest_body: Label = $Root/HUDMargin/ScreenLayout/BottomHUD/QuestCard/QuestPadding/QuestBox/QuestBody
@onready var area_intro_toast: PanelContainer = $Root/AreaIntroToast
@onready var toast_title: Label = $Root/AreaIntroToast/ToastPadding/ToastBox/ToastTitle
@onready var toast_subtitle: Label = $Root/AreaIntroToast/ToastPadding/ToastBox/ToastSubtitle
@onready var animation_player: AnimationPlayer = $Root/AnimationPlayer
@onready var habitat_panel: PanelContainer = $Root/HabitatPanel
@onready var habitat_margin: MarginContainer = $Root/HabitatPanel/HabitatMargin
@onready var habitat_box: VBoxContainer = $Root/HabitatPanel/HabitatMargin/HabitatBox
@onready var habitat_split: HBoxContainer = $Root/HabitatPanel/HabitatMargin/HabitatBox/HabitatSplit
@onready var habitat_icon: TextureRect = $Root/HabitatPanel/HabitatMargin/HabitatBox/HabitatSplit/HabitatIcon
@onready var habitat_info: VBoxContainer = $Root/HabitatPanel/HabitatMargin/HabitatBox/HabitatSplit/HabitatInfo
@onready var habitat_title: Label = $Root/HabitatPanel/HabitatMargin/HabitatBox/HabitatSplit/HabitatInfo/HabitatTitle
@onready var habitat_body: Label = $Root/HabitatPanel/HabitatMargin/HabitatBox/HabitatSplit/HabitatInfo/HabitatBody
@onready var habitat_status: Label = $Root/HabitatPanel/HabitatMargin/HabitatBox/HabitatSplit/HabitatInfo/HabitatStatus
@onready var habitat_buttons: HBoxContainer = $Root/HabitatPanel/HabitatMargin/HabitatBox/HabitatButtons
@onready var habitat_explore_button: Button = $Root/HabitatPanel/HabitatMargin/HabitatBox/HabitatButtons/HabitatExploreButton
@onready var habitat_back_button: Button = $Root/HabitatPanel/HabitatMargin/HabitatBox/HabitatButtons/HabitatBackButton
@onready var encounter_panel: PanelContainer = $Root/EncounterPanel
@onready var encounter_margin: MarginContainer = $Root/EncounterPanel/EncounterMargin
@onready var encounter_box: VBoxContainer = $Root/EncounterPanel/EncounterMargin/EncounterBox
@onready var encounter_title: Label = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterTitle
@onready var encounter_body: Label = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterBody
@onready var encounter_stats: Label = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterStats
@onready var encounter_capture_button: Button = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterCaptureButton
@onready var encounter_observe_button: Button = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterObserveButton
@onready var encounter_battle_button: Button = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterBattleButton
@onready var encounter_back_button: Button = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterBackButton
@onready var dex_panel: PanelContainer = $Root/DexPanel
@onready var dex_margin: MarginContainer = $Root/DexPanel/DexMargin
@onready var dex_box: VBoxContainer = $Root/DexPanel/DexMargin/DexBox
@onready var dex_header: Label = $Root/DexPanel/DexMargin/DexBox/DexHeader
@onready var dex_list: ItemList = $Root/DexPanel/DexMargin/DexBox/DexSplit/DexList
@onready var dex_detail: Label = $Root/DexPanel/DexMargin/DexBox/DexSplit/DexDetail
@onready var dex_back_button: Button = $Root/DexPanel/DexMargin/DexBox/DexBackButton
@onready var home_panel: PanelContainer = $Root/HomePanel
@onready var home_margin: MarginContainer = $Root/HomePanel/HomeMargin
@onready var home_box: VBoxContainer = $Root/HomePanel/HomeMargin/HomeBox
@onready var home_header: Label = $Root/HomePanel/HomeMargin/HomeBox/HomeHeader
@onready var home_list: ItemList = $Root/HomePanel/HomeMargin/HomeBox/HomeSplit/HomeList
@onready var home_detail: Label = $Root/HomePanel/HomeMargin/HomeBox/HomeSplit/HomeDetail
@onready var home_actions: HBoxContainer = $Root/HomePanel/HomeMargin/HomeBox/HomeActions
@onready var home_feed_button: Button = $Root/HomePanel/HomeMargin/HomeBox/HomeActions/HomeFeedButton
@onready var home_clean_button: Button = $Root/HomePanel/HomeMargin/HomeBox/HomeActions/HomeCleanButton
@onready var home_pet_button: Button = $Root/HomePanel/HomeMargin/HomeBox/HomeActions/HomePetButton
@onready var home_restore_button: Button = $Root/HomePanel/HomeMargin/HomeBox/HomeActions/HomeRestoreButton
@onready var home_back_button: Button = $Root/HomePanel/HomeMargin/HomeBox/HomeBackButton
@onready var battle_prep_panel: PanelContainer = $Root/BattlePrepPanel
@onready var battle_prep_margin: MarginContainer = $Root/BattlePrepPanel/BattlePrepMargin
@onready var battle_prep_box: VBoxContainer = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox
@onready var battle_prep_title: Label = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattlePrepTitle
@onready var battle_prep_info: Label = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattlePrepInfo
@onready var battle_spirit_select: OptionButton = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattleSpiritSelect
@onready var battle_prep_start_button: Button = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattlePrepStartButton
@onready var battle_prep_back_button: Button = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattlePrepBackButton

var dex_spirit_ids: Array[String] = []
var home_spirit_ids: Array[String] = []

func _ready() -> void:
	GameState.ui_state_changed.connect(_on_ui_state_changed)
	GameState.message_changed.connect(_on_message_changed)
	SaveManager.save_changed.connect(_on_save_changed)
	BattleManager.battle_state_changed.connect(_on_battle_state_changed)
	DisplayManager.profile_changed.connect(_apply_display_profile)
	dex_button.pressed.connect(GameState.open_dex)
	home_button.pressed.connect(_open_home)
	habitat_explore_button.pressed.connect(_start_explore)
	habitat_back_button.pressed.connect(GameState.close_panel)
	encounter_observe_button.pressed.connect(_observe_encounter)
	encounter_battle_button.pressed.connect(_open_battle_from_encounter)
	encounter_back_button.pressed.connect(_leave_encounter)
	dex_list.item_selected.connect(_on_dex_selected)
	dex_back_button.pressed.connect(GameState.close_panel)
	home_list.item_selected.connect(_on_home_selected)
	home_feed_button.pressed.connect(func() -> void: _care_for("feed"))
	home_clean_button.pressed.connect(func() -> void: _care_for("clean"))
	home_pet_button.pressed.connect(func() -> void: _care_for("pet"))
	home_restore_button.pressed.connect(_restore_all)
	home_back_button.pressed.connect(GameState.close_panel)
	battle_spirit_select.item_selected.connect(_on_battle_spirit_selected)
	battle_prep_start_button.pressed.connect(_start_battle)
	battle_prep_back_button.pressed.connect(_return_to_encounter)
	_configure_static_hud()
	_setup_intro_toast_animation()
	_apply_display_profile(DisplayManager.get_active_profile())
	_refresh_all()
	_play_area_intro_toast()

func _exit_tree() -> void:
	if DisplayManager.profile_changed.is_connected(_apply_display_profile):
		DisplayManager.profile_changed.disconnect(_apply_display_profile)

func _on_ui_state_changed(_panel: String) -> void:
	_refresh_all()

func _on_message_changed(_message: String) -> void:
	_refresh_hud()

func _on_save_changed(_save_data: Dictionary) -> void:
	_refresh_all()

func _on_battle_state_changed() -> void:
	_refresh_battle_prep_panel()

func _refresh_all() -> void:
	_refresh_hud()
	_refresh_visibility()
	_refresh_habitat_panel()
	_refresh_encounter_panel()
	_refresh_dex_panel()
	_refresh_home_panel()
	_refresh_battle_prep_panel()

func _refresh_hud() -> void:
	location_label.text = _scene_location_label(WorldState.current_scene_id)
	var intro_parts: PackedStringArray = _scene_intro_parts(WorldState.current_scene_id)
	toast_title.text = intro_parts[0]
	toast_subtitle.text = intro_parts[1]
	quest_card.visible = not _is_intro_task_complete() and GameState.current_panel == "hud"
	quest_title.text = "新手指引"
	quest_body.text = "找到一个探索点"

func _refresh_visibility() -> void:
	habitat_panel.visible = GameState.current_panel == "habitat"
	encounter_panel.visible = GameState.current_panel == "encounter"
	dex_panel.visible = GameState.current_panel == "dex"
	home_panel.visible = GameState.current_panel == "home"
	battle_prep_panel.visible = GameState.current_panel == "battle_prep"

func _refresh_habitat_panel() -> void:
	var habitat: HabitatData = GameCatalog.get_habitat_by_id(GameState.active_habitat_id)
	if habitat == null:
		return
	habitat_title.text = habitat.display_name
	habitat_body.text = habitat.intro_text
	var discovered_count: int = 0
	var captured_count: int = 0
	for spirit_id in habitat.encounter_pool:
		if SaveManager.has_discovered(spirit_id):
			discovered_count += 1
		if SaveManager.has_captured(spirit_id):
			captured_count += 1
	habitat_status.text = "已发现 %d/%d　已入住 %d/%d" % [discovered_count, habitat.encounter_pool.size(), captured_count, habitat.encounter_pool.size()]

func _refresh_encounter_panel() -> void:
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(GameState.current_encounter_id)
	if spirit == null:
		return
	encounter_title.text = "遇见 %s" % spirit.display_name
	var status: String = "首次发现"
	if SaveManager.has_captured(spirit.spirit_id):
		status = "已入住"
	elif SaveManager.has_discovered(spirit.spirit_id):
		status = "已发现"
	encounter_body.text = spirit.description
	encounter_stats.text = "属性：%s | 稀有度：%s | %s\n等级与你的萌灵相近" % [_element_label(spirit.element), _rarity_label(spirit.rarity), status]
	encounter_capture_button.visible = false

func _refresh_dex_panel() -> void:
	dex_list.clear()
	dex_spirit_ids.clear()
	for spirit in GameCatalog.get_spirits():
		var status: String = "未发现"
		if SaveManager.has_captured(spirit.spirit_id):
			status = "已入住"
		elif SaveManager.has_discovered(spirit.spirit_id):
			status = "已发现"
		dex_list.add_item("[%s] %s" % [status, spirit.display_name])
		dex_spirit_ids.append(spirit.spirit_id)
	if dex_list.item_count > 0:
		if not dex_list.is_anything_selected():
			dex_list.select(0)
		var selected_items: PackedInt32Array = dex_list.get_selected_items()
		_update_dex_detail(selected_items[0] if not selected_items.is_empty() else 0)

func _refresh_home_panel() -> void:
	home_list.clear()
	home_spirit_ids.clear()
	var captured_ids: Array[String] = SaveManager.get_captured_spirit_ids()
	for spirit_id in captured_ids:
		var spirit: SpiritData = GameCatalog.get_spirit_by_id(spirit_id)
		var pet: Dictionary = SaveManager.get_pet_state(spirit_id)
		if spirit == null or pet.is_empty():
			continue
		home_list.add_item("%s Lv.%d" % [spirit.display_name, int(pet.level)])
		home_spirit_ids.append(spirit_id)
	var has_pets: bool = not home_spirit_ids.is_empty()
	home_feed_button.disabled = not has_pets
	home_clean_button.disabled = not has_pets
	home_pet_button.disabled = not has_pets
	home_restore_button.disabled = not has_pets
	if not has_pets:
		home_detail.text = "小屋里还没有萌灵。先去探索，邀请第一位朋友吧。"
		return
	if GameState.home_selected_spirit_id == "" or not SaveManager.has_captured(GameState.home_selected_spirit_id):
		GameState.home_selected_spirit_id = home_spirit_ids[0]
	var selected_index: int = home_spirit_ids.find(GameState.home_selected_spirit_id)
	if selected_index >= 0:
		home_list.select(selected_index)
		_update_home_detail(selected_index)

func _refresh_battle_prep_panel() -> void:
	battle_spirit_select.clear()
	var captured_ids: Array[String] = SaveManager.get_captured_spirit_ids()
	for spirit_id in captured_ids:
		var spirit: SpiritData = GameCatalog.get_spirit_by_id(spirit_id)
		var pet: Dictionary = SaveManager.get_pet_state(spirit_id)
		if spirit == null or pet.is_empty():
			continue
		battle_spirit_select.add_item("%s Lv.%d" % [spirit.display_name, int(pet.level)])
		battle_spirit_select.set_item_metadata(battle_spirit_select.item_count - 1, spirit_id)
	if battle_spirit_select.item_count <= 0:
		battle_prep_info.text = "先邀请一只萌灵入住吧。"
		battle_prep_start_button.disabled = true
		return
	var selected_index: int = max(captured_ids.find(GameState.selected_battle_spirit_id), 0)
	battle_spirit_select.select(selected_index)
	GameState.selected_battle_spirit_id = String(battle_spirit_select.get_item_metadata(selected_index))
	battle_prep_start_button.disabled = false
	var enemy_spirit: SpiritData = GameCatalog.get_spirit_by_id(String(BattleManager.battle_state.enemy_spirit_id))
	battle_prep_info.text = "对手：%s。等级会和你差不多。" % enemy_spirit.display_name if enemy_spirit != null else "选择一只出战萌灵。"

func _start_explore() -> void:
	GameState.start_explore()

func _observe_encounter() -> void:
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(GameState.current_encounter_id)
	if spirit == null:
		return
	var status: String = "首次发现"
	if SaveManager.has_captured(spirit.spirit_id):
		status = "已入住"
	elif SaveManager.has_discovered(spirit.spirit_id):
		status = "已发现"
	encounter_body.text = "%s\n属性：%s | 稀有度：%s | %s\n\n%s\n\n仔细观察中，先见一面再决定下一步。" % [spirit.display_name, _element_label(spirit.element), _rarity_label(spirit.rarity), status, spirit.description]

func _open_battle_from_encounter() -> void:
	if GameState.current_encounter_id != "":
		BattleManager.prepare_battle(GameState.current_encounter_id, GameState.current_encounter_habitat_id)

func _leave_encounter() -> void:
	GameState.leave_encounter()

func _return_to_encounter() -> void:
	GameState.current_panel = "encounter"
	GameState.ui_state_changed.emit(GameState.current_panel)

func _open_home() -> void:
	if SaveManager.get_captured_spirit_ids().is_empty():
		GameState.set_message("先邀请一只萌灵入住，再来小屋看看。")
		return
	GameState.open_home()

func _start_battle() -> void:
	if battle_spirit_select.selected < 0:
		return
	var current_scene_path: String = get_tree().current_scene.scene_file_path if get_tree().current_scene != null else "res://scenes/world/test_world.tscn"
	var spirit_id: String = String(battle_spirit_select.get_item_metadata(battle_spirit_select.selected))
	GameState.selected_battle_spirit_id = spirit_id
	BattleManager.set_return_scene_path(current_scene_path)
	BattleManager.start_battle(spirit_id)
	if BattleManager.battle_state.status == "active":
		var error_code: int = get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
		if error_code != OK:
			GameState.set_message("战斗场景打开失败，请再试一次。")

func _care_for(action: String) -> void:
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(GameState.home_selected_spirit_id)
	if spirit == null:
		return
	GameState.set_message(SaveManager.care_for(spirit, action))
	_refresh_home_panel()

func _restore_all() -> void:
	GameState.set_message(SaveManager.restore_all_pets())
	_refresh_home_panel()

func _on_dex_selected(index: int) -> void:
	_update_dex_detail(index)

func _on_home_selected(index: int) -> void:
	if index >= 0 and index < home_spirit_ids.size():
		GameState.home_selected_spirit_id = home_spirit_ids[index]
	_update_home_detail(index)

func _on_battle_spirit_selected(index: int) -> void:
	GameState.selected_battle_spirit_id = String(battle_spirit_select.get_item_metadata(index))

func _update_dex_detail(index: int) -> void:
	if index < 0 or index >= dex_spirit_ids.size():
		return
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(dex_spirit_ids[index])
	if spirit == null:
		return
	var status: String = "未发现"
	if SaveManager.has_captured(spirit.spirit_id):
		status = "已入住"
	elif SaveManager.has_discovered(spirit.spirit_id):
		status = "已发现"
	dex_detail.text = "%s\n%s / %s\n状态：%s\n\n%s" % [spirit.display_name, _element_label(spirit.element), _rarity_label(spirit.rarity), status, spirit.description]

func _update_home_detail(index: int) -> void:
	if index < 0 or index >= home_spirit_ids.size():
		return
	var spirit_id: String = home_spirit_ids[index]
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(spirit_id)
	var pet: Dictionary = SaveManager.get_pet_state(spirit_id)
	if spirit == null or pet.is_empty():
		return
	var need: int = GameCatalog.exp_to_next(int(pet.level), spirit.rarity)
	var max_hp: int = int(GameCatalog.get_stats(spirit, int(pet.level)).hp)
	home_detail.text = "%s\nLv.%d　经验 %d/%d\n生命 %d/%d\n亲密 %d　饱腹 %d　清洁 %d\n心情：%s\n最爱：%s\n\n%s" % [spirit.display_name, int(pet.level), int(pet.exp), need, int(pet.current_hp), max_hp, int(pet.affection), int(pet.hunger), int(pet.cleanliness), _mood_label(String(pet.mood)), spirit.favorite_food, spirit.description]

func _scene_location_label(scene_id: String) -> String:
	match scene_id:
		"test_world":
			return "新手岛 · 迎风广场"
		"grove_gate":
			return "第二探索区 · 林间入口"
		"":
			return "萌灵小岛"
		_:
			return "萌灵小岛 · %s" % scene_id

func _scene_intro_parts(scene_id: String) -> PackedStringArray:
	match scene_id:
		"test_world":
			return PackedStringArray(["新手岛", "迎风广场"])
		"grove_gate":
			return PackedStringArray(["第二探索区", "林间入口"])
		_:
			return PackedStringArray(["萌灵小岛", "开始探索"])

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

func _rarity_label(rarity: String) -> String:
	match rarity:
		"common":
			return "常见"
		"rare":
			return "稀有"
		"legend":
			return "传奇"
		"mythic":
			return "神话"
		_:
			return rarity

func _mood_label(mood: String) -> String:
	match mood:
		"happy":
			return "开心"
		"full":
			return "吃饱啦"
		"clean":
			return "清爽"
		"close":
			return "亲近"
		"rested":
			return "精神满满"
		_:
			return mood

func _apply_display_profile(profile: DeviceProfile) -> void:
	var ui_scale: float = profile.ui_scale if profile != null else 1.0
	var font_scale: float = profile.font_scale if profile != null else 1.0
	var safe_margins: Vector4i = profile.get_safe_margins() if profile != null else Vector4i.ZERO
	_apply_hud_layout(ui_scale, font_scale, safe_margins)
	_apply_panel_typography(ui_scale, font_scale)
	_apply_button_sizes(ui_scale)
	_apply_list_sizes(ui_scale)

func _apply_hud_layout(ui_scale: float, font_scale: float, safe_margins: Vector4i) -> void:
	hud_margin.add_theme_constant_override("margin_left", int(round(BASE_HUD_MARGIN * ui_scale)) + safe_margins.x)
	hud_margin.add_theme_constant_override("margin_top", int(round(BASE_HUD_MARGIN * ui_scale)) + safe_margins.y)
	hud_margin.add_theme_constant_override("margin_right", int(round(BASE_HUD_MARGIN * ui_scale)) + safe_margins.z)
	hud_margin.add_theme_constant_override("margin_bottom", int(round(BASE_HUD_MARGIN * ui_scale)) + safe_margins.w)
	screen_layout.add_theme_constant_override("separation", int(round(12 * ui_scale)))
	top_hud.add_theme_constant_override("separation", int(round(BASE_HUD_SPACING * ui_scale)))
	action_buttons.add_theme_constant_override("separation", int(round(BASE_HUD_SPACING * ui_scale)))
	location_card.custom_minimum_size = BASE_LOCATION_CARD_SIZE * ui_scale
	location_label.add_theme_font_size_override("font_size", int(round(BASE_LOCATION_FONT * font_scale)))
	for button in [dex_button, home_button]:
		button.custom_minimum_size = BASE_ACTION_BUTTON_SIZE * ui_scale
	quest_card.custom_minimum_size.x = BASE_QUEST_CARD_WIDTH * ui_scale
	quest_title.add_theme_font_size_override("font_size", int(round(BASE_QUEST_TITLE_FONT * font_scale)))
	quest_body.add_theme_font_size_override("font_size", int(round(BASE_QUEST_BODY_FONT * font_scale)))
	area_intro_toast.offset_left = -BASE_TOAST_WIDTH * 0.5 * ui_scale
	area_intro_toast.offset_top = BASE_TOAST_TOP + float(safe_margins.y)
	area_intro_toast.offset_right = BASE_TOAST_WIDTH * 0.5 * ui_scale
	area_intro_toast.offset_bottom = area_intro_toast.offset_top + (84.0 * ui_scale)
	toast_title.add_theme_font_size_override("font_size", int(round(BASE_TOAST_TITLE_FONT * font_scale)))
	toast_subtitle.add_theme_font_size_override("font_size", int(round(BASE_TOAST_SUBTITLE_FONT * font_scale)))

func _apply_panel_typography(ui_scale: float, font_scale: float) -> void:
	for margin in [habitat_margin, encounter_margin, dex_margin, home_margin, battle_prep_margin]:
		margin.add_theme_constant_override("margin_left", int(round(24 * ui_scale)))
		margin.add_theme_constant_override("margin_top", int(round(24 * ui_scale)))
		margin.add_theme_constant_override("margin_right", int(round(24 * ui_scale)))
		margin.add_theme_constant_override("margin_bottom", int(round(24 * ui_scale)))
	for box in [habitat_box, encounter_box, dex_box, home_box, battle_prep_box]:
		box.add_theme_constant_override("separation", int(round(14 * ui_scale)))
	for label in [habitat_title, encounter_title, dex_header, home_header, battle_prep_title]:
		label.add_theme_font_size_override("font_size", int(round(BASE_PANEL_TITLE_FONT * font_scale)))
	for label in [habitat_body, encounter_body, dex_detail, home_detail, battle_prep_info]:
		label.add_theme_font_size_override("font_size", int(round(BASE_PANEL_BODY_FONT * font_scale)))
	for label in [habitat_status, encounter_stats]:
		label.add_theme_font_size_override("font_size", int(round(BASE_PANEL_STATUS_FONT * font_scale)))
	home_actions.add_theme_constant_override("separation", int(round(12 * ui_scale)))
	battle_spirit_select.add_theme_font_size_override("font_size", int(round(BASE_PANEL_BODY_FONT * font_scale)))
	dex_list.add_theme_font_size_override("font_size", int(round(BASE_PANEL_BODY_FONT * font_scale)))
	home_list.add_theme_font_size_override("font_size", int(round(BASE_PANEL_BODY_FONT * font_scale)))

func _apply_button_sizes(ui_scale: float) -> void:
	for button in [habitat_explore_button, habitat_back_button, encounter_observe_button, encounter_battle_button, encounter_back_button, dex_back_button, home_back_button, battle_prep_back_button]:
		button.custom_minimum_size.y = BASE_BUTTON_HEIGHT * ui_scale
	for button in [home_feed_button, home_clean_button, home_pet_button]:
		button.custom_minimum_size = Vector2(132 * ui_scale, BASE_BUTTON_HEIGHT * ui_scale)
	home_restore_button.custom_minimum_size = Vector2(168 * ui_scale, BASE_BUTTON_HEIGHT * ui_scale)
	battle_spirit_select.custom_minimum_size.y = BASE_BUTTON_HEIGHT * ui_scale
	battle_prep_start_button.custom_minimum_size.y = BASE_LARGE_BUTTON_HEIGHT * ui_scale

func _apply_list_sizes(ui_scale: float) -> void:
	dex_list.custom_minimum_size = BASE_DEX_LIST_SIZE * ui_scale
	dex_detail.custom_minimum_size = BASE_DEX_DETAIL_SIZE * ui_scale
	home_list.custom_minimum_size = BASE_HOME_LIST_SIZE * ui_scale
	home_detail.custom_minimum_size = BASE_HOME_DETAIL_SIZE * ui_scale

func _configure_static_hud() -> void:
	var card_style: StyleBoxFlat = _build_card_style(Color(0.964706, 0.933333, 0.862745, 0.96))
	var toast_style: StyleBoxFlat = _build_card_style(Color(0.964706, 0.933333, 0.862745, 0.92))
	location_card.add_theme_stylebox_override("panel", card_style)
	quest_card.add_theme_stylebox_override("panel", card_style)
	area_intro_toast.add_theme_stylebox_override("panel", toast_style)
	area_intro_toast.modulate = Color(1.0, 1.0, 1.0, 0.0)
	dex_button.text = ""
	home_button.text = ""
	dex_button.tooltip_text = "图鉴"
	home_button.tooltip_text = "小屋"

func _build_card_style(background: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.541176, 0.403922, 0.25098, 1.0)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.shadow_color = Color(0.180392, 0.141176, 0.101961, 0.14)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style

func _setup_intro_toast_animation() -> void:
	var library: AnimationLibrary = null
	if animation_player.has_animation_library(""):
		library = animation_player.get_animation_library("")
	else:
		library = AnimationLibrary.new()
		animation_player.add_animation_library("", library)
	if library.has_animation("area_intro"):
		library.remove_animation("area_intro")
	var animation: Animation = Animation.new()
	animation.length = INTRO_FADE_IN + INTRO_HOLD + INTRO_FADE_OUT
	var track: int = animation.add_track(Animation.TYPE_VALUE)
	animation_player.root_node = NodePath("..")
	animation.track_set_path(track, NodePath("AreaIntroToast:modulate"))
	animation.track_insert_key(track, 0.0, Color(1.0, 1.0, 1.0, 0.0))
	animation.track_insert_key(track, INTRO_FADE_IN, Color(1.0, 1.0, 1.0, 1.0))
	animation.track_insert_key(track, INTRO_FADE_IN + INTRO_HOLD, Color(1.0, 1.0, 1.0, 1.0))
	animation.track_insert_key(track, animation.length, Color(1.0, 1.0, 1.0, 0.0))
	library.add_animation("area_intro", animation)

func _play_area_intro_toast() -> void:
	if animation_player.has_animation("area_intro"):
		animation_player.play("area_intro")

func _is_intro_task_complete() -> bool:
	if GameState.active_habitat_id != "":
		return true
	var discovered: Dictionary = Dictionary(SaveManager.get_save_data().get("discovered", {}))
	var captured: Dictionary = Dictionary(SaveManager.get_save_data().get("captured", {}))
	return not discovered.is_empty() or not captured.is_empty()