extends CanvasLayer

const PORTRAIT_CATALOG: Script = preload("res://scripts/ui/components/spirit_portrait_catalog.gd")
const MODAL_SHELL_SCENE: PackedScene = preload("res://scenes/ui/components/game_modal_shell.tscn")

const BATTLE_SCENE_PATH: String = "res://scenes/battle/battle_scene.tscn"
const HABITAT_ART_PATHS: Dictionary = {
	"grassland": "res://assets/exploration_points/01_grassland_草丛探索点.png",
	"pond": "res://assets/exploration_points/02_pond_池塘探索点.png",
	"warmstone": "res://assets/exploration_points/03_warm_stone_暖石探索点.png"
}
const BASE_HUD_MARGIN: int = 24
const BASE_HUD_SPACING: int = 12
const BASE_LOCATION_CARD_SIZE: Vector2 = Vector2(240.0, 68.0)
const BASE_LOCATION_FONT: int = 20
const BASE_ACTION_BUTTON_SIZE: Vector2 = Vector2(76.0, 76.0)
const BASE_ACTION_ICON_WIDTH: int = 28
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

const BASE_MODAL_PADDING: float = 32.0
const HABITAT_MODAL_SIZE: Vector2 = Vector2(920.0, 520.0)
const ENCOUNTER_MODAL_SIZE: Vector2 = Vector2(720.0, 460.0)
const BATTLE_PREP_MODAL_SIZE: Vector2 = Vector2(1040.0, 610.0)
const HABITAT_PREVIEW_CARD_SIZE: Vector2 = Vector2(104.0, 104.0)
const HABITAT_PREVIEW_PORTRAIT_SIZE: Vector2 = Vector2(56.0, 56.0)
const BATTLE_CARD_SIZE: Vector2 = Vector2(132.0, 96.0)
const BATTLE_PORTRAIT_SIZE: Vector2 = Vector2(56.0, 56.0)

@onready var root: Control = $Root
@onready var hud_margin: MarginContainer = $Root/HUDMargin
@onready var screen_layout: VBoxContainer = $Root/HUDMargin/ScreenLayout
@onready var top_hud: HBoxContainer = $Root/HUDMargin/ScreenLayout/TopHUD
@onready var location_card: PanelContainer = $Root/HUDMargin/ScreenLayout/TopHUD/LocationCard
@onready var island_label: Label = $Root/HUDMargin/ScreenLayout/TopHUD/LocationCard/LocationPadding/AreaLayout/AreaText/IslandLabel
@onready var location_label: Label = $Root/HUDMargin/ScreenLayout/TopHUD/LocationCard/LocationPadding/AreaLayout/AreaText/LocationLabel
@onready var action_buttons: HBoxContainer = $Root/HUDMargin/ScreenLayout/TopHUD/ActionButtons
@onready var dex_button: Button = $Root/HUDMargin/ScreenLayout/TopHUD/ActionButtons/DexButton
@onready var dex_icon: TextureRect = $Root/HUDMargin/ScreenLayout/TopHUD/ActionButtons/DexButton/Content/Icon
@onready var home_button: Button = $Root/HUDMargin/ScreenLayout/TopHUD/ActionButtons/HomeButton
@onready var home_icon: TextureRect = $Root/HUDMargin/ScreenLayout/TopHUD/ActionButtons/HomeButton/Content/Icon
@onready var quest_card: PanelContainer = $Root/HUDMargin/ScreenLayout/BottomHUD/QuestCard
@onready var quest_title: Label = $Root/HUDMargin/ScreenLayout/BottomHUD/QuestCard/QuestPadding/QuestBox/QuestTitle
@onready var quest_body: Label = $Root/HUDMargin/ScreenLayout/BottomHUD/QuestCard/QuestPadding/QuestBox/QuestBody
@onready var interaction_prompt: PanelContainer = $Root/InteractionPrompt
@onready var interaction_prompt_label: Label = $Root/InteractionPrompt/PromptPadding/PromptLayout/ActionText
@onready var interaction_input_badge: PanelContainer = $Root/InteractionPrompt/PromptPadding/PromptLayout/InputBadge
@onready var area_intro_toast: PanelContainer = $Root/AreaIntroToast
@onready var toast_title: Label = $Root/AreaIntroToast/ToastPadding/ToastBox/ToastTitle
@onready var toast_subtitle: Label = $Root/AreaIntroToast/ToastPadding/ToastBox/ToastSubtitle
@onready var animation_player: AnimationPlayer = $Root/AnimationPlayer

@onready var habitat_panel: PanelContainer = $Root/HabitatPanel
@onready var habitat_margin: MarginContainer = $Root/HabitatPanel/HabitatMargin
@onready var habitat_box: VBoxContainer = $Root/HabitatPanel/HabitatMargin/HabitatBox
@onready var habitat_split: HBoxContainer = $Root/HabitatPanel/HabitatMargin/HabitatBox/HabitatSplit
@onready var habitat_icon: TextureRect = $Root/HabitatPanel/HabitatMargin/HabitatBox/HabitatSplit/HabitatIcon
@onready var habitat_preview_row: HBoxContainer = $Root/HabitatPanel/HabitatMargin/HabitatBox/HabitatPreview/PreviewRow
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
@onready var encounter_portrait: TextureRect = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterPortrait
@onready var encounter_body: Label = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterBody
@onready var encounter_stats: Label = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterStats
@onready var encounter_capture_button: Button = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterActionRow/EncounterCaptureButton
@onready var encounter_battle_button: Button = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterActionRow/EncounterBattleButton
@onready var encounter_back_button: Button = $Root/EncounterPanel/EncounterMargin/EncounterBox/EncounterActionRow/EncounterBackButton
@onready var dex_page: Control = $Root/DexPage
@onready var home_page: Control = $Root/HomePage
@onready var touch_controls: Control = $Root/TouchControls
@onready var main_menu: Control = $Root/MainMenu
@onready var main_menu_party_tab: Button = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/Tabs/PartyTab
@onready var main_menu_inventory_tab: Button = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/Tabs/InventoryTab
@onready var main_menu_settings_tab: Button = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/Tabs/SettingsTab
@onready var main_menu_party_page: VBoxContainer = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost/PartyPage
@onready var main_menu_inventory_page: VBoxContainer = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost/InventoryPage
@onready var main_menu_settings_page: VBoxContainer = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost/SettingsPage
@onready var main_menu_party_list: VBoxContainer = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost/PartyPage/PartyList
@onready var main_menu_inventory_list: VBoxContainer = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost/InventoryPage/InventoryList
@onready var main_menu_page_host: Control = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost
@onready var main_menu_close_button: Button = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/Footer/CloseButton
@onready var master_slider: HSlider = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost/SettingsPage/MasterRow/Slider
@onready var master_value: Label = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost/SettingsPage/MasterRow/Value
@onready var music_slider: HSlider = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost/SettingsPage/MusicRow/Slider
@onready var music_value: Label = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost/SettingsPage/MusicRow/Value
@onready var sfx_slider: HSlider = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost/SettingsPage/SfxRow/Slider
@onready var sfx_value: Label = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost/SettingsPage/SfxRow/Value
@onready var fullscreen_check: CheckButton = $Root/MainMenu/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/MenuLayout/PageHost/SettingsPage/FullscreenCheck
@onready var battle_prep_panel: PanelContainer = $Root/BattlePrepPanel
@onready var battle_prep_margin: MarginContainer = $Root/BattlePrepPanel/BattlePrepMargin
@onready var battle_prep_box: VBoxContainer = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox
@onready var battle_prep_title: Label = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattlePrepTitle
@onready var battle_prep_info: Label = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattlePrepInfo
@onready var battle_spirit_select: OptionButton = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattleSpiritSelect
@onready var battle_empty_label: Label = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattleEmptyLabel
@onready var battle_spirit_scroll: ScrollContainer = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattleSpiritScroll
@onready var battle_spirit_grid: GridContainer = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattleSpiritScroll/BattleSpiritGrid
@onready var battle_scroll_hint: Label = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattleScrollHint
@onready var battle_prep_footer: HBoxContainer = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattlePrepFooter
@onready var battle_prep_start_button: Button = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattlePrepFooter/BattlePrepStartButton
@onready var battle_prep_back_button: Button = $Root/BattlePrepPanel/BattlePrepMargin/BattlePrepBox/BattlePrepFooter/BattlePrepBackButton

var habitat_modal: Control = null
var encounter_modal: Control = null
var battle_prep_modal: Control = null
var _settings_syncing: bool = false
var _main_menu_page: String = "party"
var interaction_prompt_tween: Tween = null
var area_plaque_tween: Tween = null
var current_area_key: String = ""
var habitat_discovered_badge: Label = null
var habitat_resident_badge: Label = null

func _ready() -> void:
	GameState.ui_state_changed.connect(_on_ui_state_changed)
	GameState.message_changed.connect(_on_message_changed)
	SaveManager.save_changed.connect(_on_save_changed)
	BattleManager.battle_state_changed.connect(_on_battle_state_changed)
	DisplayManager.profile_changed.connect(_apply_display_profile)
	InputRouter.touch_menu_requested.connect(_on_touch_menu_requested)
	InputRouter.touch_confirm_requested.connect(_on_touch_confirm_requested)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	dex_button.pressed.connect(_open_dex)
	home_button.pressed.connect(_open_home)
	dex_button.mouse_entered.connect(_set_world_action_hover.bind(dex_button, true))
	dex_button.mouse_exited.connect(_set_world_action_hover.bind(dex_button, false))
	home_button.mouse_entered.connect(_set_world_action_hover.bind(home_button, true))
	home_button.mouse_exited.connect(_set_world_action_hover.bind(home_button, false))
	for world_button in [dex_button, home_button]:
		world_button.focus_entered.connect(_set_world_action_hover.bind(world_button, true))
		world_button.focus_exited.connect(_set_world_action_hover.bind(world_button, false))
		world_button.button_down.connect(_set_world_action_pressed.bind(world_button, true))
		world_button.button_up.connect(_set_world_action_pressed.bind(world_button, false))
	interaction_prompt.gui_input.connect(_on_interaction_prompt_gui_input)
	habitat_explore_button.pressed.connect(_start_explore)
	habitat_back_button.pressed.connect(GameState.close_panel)
	encounter_capture_button.pressed.connect(_observe_encounter)
	encounter_battle_button.pressed.connect(_open_battle_from_encounter)
	encounter_back_button.pressed.connect(_leave_encounter)
	battle_spirit_select.item_selected.connect(_on_battle_spirit_selected)
	battle_prep_start_button.pressed.connect(_start_battle)
	battle_prep_back_button.pressed.connect(_return_to_encounter)
	main_menu.connect("close_requested", _on_main_menu_closed)
	main_menu_close_button.pressed.connect(_request_close_main_menu)
	main_menu_party_tab.pressed.connect(_set_main_menu_page.bind("party", true))
	main_menu_inventory_tab.pressed.connect(_set_main_menu_page.bind("inventory", true))
	main_menu_settings_tab.pressed.connect(_set_main_menu_page.bind("settings", true))
	_configure_static_hud()
	_configure_modal_panels()
	_setup_settings_controls()
	_setup_intro_toast_animation()
	_apply_display_profile(DisplayManager.get_active_profile())
	_set_main_menu_page("party", false)
	_refresh_all()


func _unhandled_input(event: InputEvent) -> void:
	if WorldState.dialogue_open:
		return
	if event.is_action_pressed("game_menu") or event.is_action_pressed("ui_cancel"):
		if main_menu.visible:
			main_menu.call("close")
			get_viewport().set_input_as_handled()
		elif GameState.current_panel == "hud":
			_open_main_menu()
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST or WorldState.dialogue_open:
		return
	if main_menu.visible:
		main_menu.call("close")
	elif GameState.current_panel == "hud":
		_open_main_menu()


func _exit_tree() -> void:
	InputRouter.set_exploration_blocked(&"gameplay_ui", false)
	if DisplayManager.profile_changed.is_connected(_apply_display_profile):
		DisplayManager.profile_changed.disconnect(_apply_display_profile)
	if InputRouter.touch_menu_requested.is_connected(_on_touch_menu_requested):
		InputRouter.touch_menu_requested.disconnect(_on_touch_menu_requested)
	if InputRouter.touch_confirm_requested.is_connected(_on_touch_confirm_requested):
		InputRouter.touch_confirm_requested.disconnect(_on_touch_confirm_requested)
	if get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.disconnect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
	_apply_display_profile(DisplayManager.get_active_profile())

func _on_ui_state_changed(_panel: String) -> void:
	InputRouter.set_exploration_blocked(&"gameplay_ui", _panel != "hud" or main_menu.visible)
	_refresh_all()
	if _panel in ["habitat", "encounter", "battle_prep"]:
		_play_storybook_open(_panel)

func _on_message_changed(_message: String) -> void:
	_refresh_hud()

func _on_save_changed(_save_data: Dictionary) -> void:
	_refresh_all()
	if main_menu.visible:
		_refresh_main_menu_data()

func _on_battle_state_changed() -> void:
	_refresh_battle_prep_panel()

func _refresh_all() -> void:
	_refresh_hud()
	_refresh_visibility()
	_refresh_habitat_panel()
	_refresh_encounter_panel()
	if GameState.current_panel == "dex":
		dex_page.call("refresh")
	if GameState.current_panel == "home":
		home_page.call("refresh")
	_refresh_battle_prep_panel()

func show_interaction_prompt(text: String = "互动") -> void:
	if GameState.current_panel != "hud":
		return
	var clean_text: String = text.replace("按 [E]", "").replace("按确认键", "").strip_edges()
	if clean_text.ends_with("。"):
		clean_text = clean_text.left(-1)
	if clean_text == "":
		clean_text = "互动"
	if interaction_prompt.visible and interaction_prompt_label.text == clean_text:
		return
	interaction_prompt_label.text = clean_text
	interaction_input_badge.visible = not DisplayManager.is_mobile_layout()
	interaction_prompt.mouse_filter = Control.MOUSE_FILTER_STOP if DisplayManager.is_mobile_layout() else Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(interaction_prompt_tween):
		interaction_prompt_tween.kill()
	interaction_prompt.visible = true
	interaction_prompt.modulate.a = 0.0
	var target_y: float = interaction_prompt.position.y
	interaction_prompt.position.y = target_y + 8.0
	interaction_prompt_tween = create_tween().set_parallel(true)
	interaction_prompt_tween.tween_property(interaction_prompt, "modulate:a", 1.0, 0.18)
	interaction_prompt_tween.tween_property(interaction_prompt, "position:y", target_y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func hide_interaction_prompt() -> void:
	if not interaction_prompt.visible:
		return
	if is_instance_valid(interaction_prompt_tween):
		interaction_prompt_tween.kill()
	interaction_prompt_tween = create_tween()
	interaction_prompt_tween.tween_property(interaction_prompt, "modulate:a", 0.0, 0.14)
	interaction_prompt_tween.tween_callback(_finish_hide_interaction_prompt)

func _finish_hide_interaction_prompt() -> void:
	interaction_prompt.visible = false

func _on_interaction_prompt_gui_input(event: InputEvent) -> void:
	if not DisplayManager.is_mobile_layout():
		return
	if event is InputEventScreenTouch and event.pressed:
		InputRouter.queue_touch_interact()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		InputRouter.queue_touch_interact()
		get_viewport().set_input_as_handled()
func refresh_world_hud() -> void:
	var intro_parts: PackedStringArray = _scene_intro_parts(WorldState.current_scene_id)
	set_area_info(intro_parts[0], intro_parts[1])
	toast_title.text = intro_parts[0]
	toast_subtitle.text = intro_parts[1]
	quest_card.visible = false

func _refresh_hud() -> void:
	refresh_world_hud()

func set_area_info(island_name: String, area_name: String) -> void:
	var next_key: String = island_name + "|" + area_name
	if current_area_key == "":
		_apply_area_info(island_name, area_name, next_key)
		return
	if current_area_key == next_key:
		return
	if is_instance_valid(area_plaque_tween):
		area_plaque_tween.kill()
	area_plaque_tween = create_tween()
	area_plaque_tween.tween_property(location_card, "modulate:a", 0.0, 0.12)
	area_plaque_tween.tween_callback(_apply_area_info.bind(island_name, area_name, next_key))
	area_plaque_tween.tween_property(location_card, "modulate:a", 1.0, 0.14)

func _apply_area_info(island_name: String, area_name: String, area_key: String) -> void:
	island_label.text = island_name
	location_label.text = area_name
	current_area_key = area_key

func set_world_hud_visible(is_visible: bool) -> void:
	location_card.modulate = Color.WHITE if is_visible else Color(1.0, 1.0, 1.0, 0.42)
	action_buttons.visible = is_visible
	if not is_visible:
		hide_interaction_prompt()
func _refresh_visibility() -> void:
	var is_hud: bool = GameState.current_panel == "hud" and not main_menu.visible
	set_world_hud_visible(is_hud)
	if habitat_modal != null:
		habitat_modal.visible = GameState.current_panel == "habitat"
	if encounter_modal != null:
		encounter_modal.visible = GameState.current_panel == "encounter"
	if battle_prep_modal != null:
		battle_prep_modal.visible = GameState.current_panel == "battle_prep"
	habitat_panel.visible = true
	encounter_panel.visible = true
	battle_prep_panel.visible = true
	dex_page.visible = GameState.current_panel == "dex"
	home_page.visible = GameState.current_panel == "home"
	touch_controls.call("set_menu_open", main_menu.visible)
	InputRouter.set_exploration_blocked(&"gameplay_ui", not is_hud)


func _play_storybook_open(panel_name: String) -> void:
	var shell: Control = habitat_modal if panel_name == "habitat" else encounter_modal if panel_name == "encounter" else battle_prep_modal
	if shell == null:
		return
	var panel: Control = shell.get_node("ModalCenter/ModalPanel") as Control
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.94, 0.94)
	panel.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.14)

func _refresh_habitat_panel() -> void:
	var habitat: HabitatData = GameCatalog.get_habitat_by_id(GameState.active_habitat_id)
	if habitat == null:
		return
	habitat_title.text = "%s · 探索点" % habitat.display_name
	_set_storybook_title(habitat_panel, habitat.display_name)
	habitat_body.text = habitat.intro_text + "\n草叶轻轻摇曳，似乎藏着许多小小的惊喜。" if habitat.habitat_id == "grassland" else habitat.intro_text
	habitat_icon.texture = load(String(HABITAT_ART_PATHS.get(habitat.habitat_id, ""))) as Texture2D
	var discovered_count: int = 0
	var captured_count: int = 0
	for spirit_id in habitat.encounter_pool:
		if SaveManager.has_discovered(spirit_id):
			discovered_count += 1
		if SaveManager.has_captured(spirit_id):
			captured_count += 1
	habitat_status.text = "探索进度：已发现 %d/%d · 已入住 %d/%d" % [discovered_count, habitat.encounter_pool.size(), captured_count, habitat.encounter_pool.size()]
	if habitat_discovered_badge != null:
		habitat_discovered_badge.text = "已发现  %d/%d" % [discovered_count, habitat.encounter_pool.size()]
	if habitat_resident_badge != null:
		habitat_resident_badge.text = "已入住  %d/%d" % [captured_count, habitat.encounter_pool.size()]
	for child in habitat_preview_row.get_children():
		child.queue_free()
	for spirit_id in habitat.encounter_pool:
		habitat_preview_row.add_child(_make_habitat_preview_card(spirit_id))

func _make_habitat_preview_card(spirit_id: String) -> PanelContainer:
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(spirit_id)
	var display_name: String = spirit.display_name if spirit != null else "????"
	var discovered: bool = SaveManager.has_discovered(spirit_id)
	var captured: bool = SaveManager.has_captured(spirit_id)
	var compact: bool = DisplayManager.is_mobile_layout() or get_viewport().get_visible_rect().size.y < 560.0
	var density: float = DisplayManager.get_canvas_density_scale() if compact else 1.0
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(72.0, 82.0) * density if compact else HABITAT_PREVIEW_CARD_SIZE
	card.add_theme_stylebox_override("panel", _build_button_style(Color("fff6df") if discovered else Color("efe5d2"), Color("76a95a") if discovered else Color("bda886")))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)

	var portrait: TextureRect = TextureRect.new()
	portrait.custom_minimum_size = Vector2(44.0, 40.0) * density if compact else HABITAT_PREVIEW_PORTRAIT_SIZE
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = PORTRAIT_CATALOG.get_texture(spirit_id)
	portrait.modulate = Color(1.0, 1.0, 1.0, 1.0) if discovered else Color(0.22, 0.2, 0.16, 0.35)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(portrait)

	var name_label: Label = Label.new()
	name_label.text = display_name if discovered else "????"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", int(round((11.0 * density) if compact else 16.0)))
	name_label.add_theme_color_override("font_color", Color("5b4028"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	var status_label: Label = Label.new()
	status_label.text = "已入住" if captured else "已发现" if discovered else "未发现"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", int(round((10.0 * density) if compact else 14.0)))
	status_label.add_theme_color_override("font_color", Color("4f8330") if discovered else Color("8b7a64"))
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(status_label)
	return card
func _refresh_encounter_panel() -> void:
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(GameState.current_encounter_id)
	if spirit == null:
		return
	encounter_title.text = "遇见萌灵！  %s" % spirit.display_name
	_set_storybook_title(encounter_panel, "遇见萌灵！")
	encounter_portrait.texture = PORTRAIT_CATALOG.get_texture(spirit.spirit_id)
	encounter_stats.text = "属性：%s · 稀有度：%s" % [_element_label(spirit.element), _rarity_label(spirit.rarity)]
	encounter_body.text = spirit.description
	encounter_capture_button.visible = true
	encounter_capture_button.text = "观察"
func _make_battle_prep_card(spirit_id: String, spirit: SpiritData, pet: Dictionary, selected: bool) -> Button:
	var card: Button = Button.new()
	card.custom_minimum_size = BATTLE_CARD_SIZE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.clip_text = true
	card.tooltip_text = "%s Lv.%d" % [spirit.display_name, int(pet.level)]
	_style_modal_button(card, selected)

	var content_box: VBoxContainer = VBoxContainer.new()
	content_box.name = "Content"
	content_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_box.offset_left = 10
	content_box.offset_top = 6
	content_box.offset_right = -10
	content_box.offset_bottom = -8
	content_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.add_theme_constant_override("separation", 2)

	var portrait: TextureRect = TextureRect.new()
	portrait.custom_minimum_size = Vector2(52.0, 52.0)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = PORTRAIT_CATALOG.get_texture(spirit_id)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var caption: Label = Label.new()
	caption.text = "%s  Lv.%d" % [spirit.display_name, int(pet.level)]
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.clip_text = true
	caption.add_theme_font_size_override("font_size", 15)
	caption.add_theme_color_override("font_color", Color.WHITE if selected else Color("6f5945"))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE

	content_box.add_child(portrait)
	content_box.add_child(caption)
	card.add_child(content_box)

	if selected:
		var selected_badge: Label = Label.new()
		selected_badge.name = "SelectedBadge"
		selected_badge.text = "✓"
		selected_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		selected_badge.offset_left = -30
		selected_badge.offset_top = 4
		selected_badge.offset_right = -8
		selected_badge.offset_bottom = 26
		selected_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		selected_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		selected_badge.add_theme_color_override("font_color", Color.WHITE)
		selected_badge.add_theme_font_size_override("font_size", 18)
		selected_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(selected_badge)

	return card
func _refresh_battle_prep_panel() -> void:
	battle_spirit_select.clear()
	for child in battle_spirit_grid.get_children():
		child.queue_free()

	var selectable_ids: Array[String] = []
	var party_ids: Array[String] = SaveManager.get_party_ids()
	for spirit_id in party_ids:
		var spirit: SpiritData = GameCatalog.get_spirit_by_id(spirit_id)
		var pet: Dictionary = SaveManager.get_pet_state(spirit_id)
		if spirit == null or pet.is_empty():
			continue
		battle_spirit_select.add_item("%s Lv.%d" % [spirit.display_name, int(pet.level)])
		battle_spirit_select.set_item_metadata(battle_spirit_select.item_count - 1, spirit_id)
		selectable_ids.append(spirit_id)

	if selectable_ids.is_empty():
		battle_empty_label.visible = true
		battle_spirit_scroll.visible = false
		battle_scroll_hint.visible = false
		battle_prep_info.text = "先让一只萌灵加入队伍，再回来发起挑战。"
		battle_prep_start_button.disabled = true
		return

	var selected_index: int = selectable_ids.find(GameState.selected_battle_spirit_id)
	if selected_index < 0:
		selected_index = 0
	battle_spirit_select.select(selected_index)
	GameState.selected_battle_spirit_id = selectable_ids[selected_index]
	battle_empty_label.visible = false
	battle_spirit_scroll.visible = true
	battle_scroll_hint.visible = selectable_ids.size() > battle_spirit_grid.columns * 2

	for index in range(selectable_ids.size()):
		var spirit_id: String = selectable_ids[index]
		var spirit: SpiritData = GameCatalog.get_spirit_by_id(spirit_id)
		var pet: Dictionary = SaveManager.get_pet_state(spirit_id)
		var card: Button = _make_battle_prep_card(spirit_id, spirit, pet, index == selected_index)
		battle_spirit_grid.add_child(card)
		card.pressed.connect(_select_battle_spirit.bind(index))

	battle_prep_start_button.disabled = false
	var enemy_spirit: SpiritData = GameCatalog.get_spirit_by_id(String(BattleManager.battle_state.enemy_spirit_id))
	battle_prep_info.text = "对手：%s。选择一只状态最好的萌灵出战。" % enemy_spirit.display_name if enemy_spirit != null else "选择一只出战萌灵。"
func _select_battle_spirit(index: int) -> void:
	battle_spirit_select.select(index)
	_on_battle_spirit_selected(index)
	_refresh_battle_prep_panel()
func _open_main_menu() -> void:
	if GameState.current_panel != "hud" or WorldState.dialogue_open:
		return
	AudioManager.play_ui()
	_sync_settings_controls()
	_refresh_main_menu_data()
	main_menu.call("open")
	InputRouter.set_exploration_blocked(&"gameplay_ui", true)
	touch_controls.call("set_menu_open", true)
	_refresh_visibility()


func _request_close_main_menu() -> void:
	main_menu.call("close")


func _on_main_menu_closed() -> void:
	AudioManager.play_ui()
	InputRouter.set_exploration_blocked(&"gameplay_ui", GameState.current_panel != "hud")
	touch_controls.call("set_menu_open", false)
	_refresh_visibility()


func _on_touch_menu_requested() -> void:
	InputRouter.consume_menu(false)
	if main_menu.visible:
		main_menu.call("close")
	elif GameState.current_panel == "hud" and not WorldState.dialogue_open:
		_open_main_menu()


func _on_touch_confirm_requested() -> void:
	InputRouter.consume_confirm(false)
	if WorldState.dialogue_open:
		return
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if focus_owner is Button and focus_owner.visible and not (focus_owner as Button).disabled:
		(focus_owner as Button).pressed.emit()


func _set_main_menu_page(page_name: String, play_sound: bool = true) -> void:
	_main_menu_page = page_name
	main_menu_party_page.visible = page_name == "party"
	main_menu_inventory_page.visible = page_name == "inventory"
	main_menu_settings_page.visible = page_name == "settings"
	for pair in [[main_menu_party_tab, "party"], [main_menu_inventory_tab, "inventory"], [main_menu_settings_tab, "settings"]]:
		var button: Button = pair[0]
		button.modulate = Color("dff0bc") if String(pair[1]) == page_name else Color.WHITE
	if page_name == "settings":
		_sync_settings_controls()
	else:
		_refresh_main_menu_data()
	if play_sound:
		AudioManager.play_ui()


func _refresh_main_menu_data() -> void:
	for child in main_menu_party_list.get_children():
		child.queue_free()
	for child in main_menu_inventory_list.get_children():
		child.queue_free()
	var compact: bool = DisplayManager.is_mobile_layout() or get_viewport().get_visible_rect().size.y < 560.0
	var party_ids: Array[String] = SaveManager.get_party_ids() if SaveManager.has_method("get_party_ids") else []
	if party_ids.is_empty():
		main_menu_party_list.add_child(_make_menu_data_label("队伍尚未组建；获得首宠后会显示在这里。", compact))
	else:
		for index in range(party_ids.size()):
			var spirit_id: String = party_ids[index]
			var spirit: SpiritData = GameCatalog.get_spirit_by_id(spirit_id)
			var pet: Dictionary = SaveManager.get_pet_state(spirit_id)
			var display_name: String = spirit.display_name if spirit != null else spirit_id
			main_menu_party_list.add_child(_make_menu_data_label("%d. %s  Lv.%d" % [index + 1, display_name, int(pet.get("level", 1))], compact))
	var inventory: Dictionary = Dictionary(SaveManager.get_save_data().get("inventory", {}))
	var ordered_items: Array[String] = ["star", "pink", "gold", "rainbow", "food", "cleaning_tool", "healing_item"]
	for raw_id in inventory.keys():
		var item_id: String = String(raw_id)
		if not ordered_items.has(item_id):
			ordered_items.append(item_id)
	for item_id in ordered_items:
		if inventory.has(item_id):
			main_menu_inventory_list.add_child(_make_menu_data_label("%s  × %d" % [_item_display_name(item_id), max(0, int(inventory[item_id]))], compact))
	if main_menu_inventory_list.get_child_count() == 0:
		main_menu_inventory_list.add_child(_make_menu_data_label("背包目前是空的。", compact))


func _make_menu_data_label(text_value: String, compact: bool) -> Label:
	var label: Label = Label.new()
	var density: float = DisplayManager.get_canvas_density_scale() if compact else 1.0
	label.text = text_value
	label.add_theme_font_size_override("font_size", int(round((12.0 if compact else 17.0) * density)))
	label.add_theme_color_override("font_color", Color("4a3b2c"))
	label.custom_minimum_size.y = (20.0 if compact else 30.0) * density
	return label


func _item_display_name(item_id: String) -> String:
	return {
		"star": "普通收服球",
		"pink": "粉彩收服球",
		"gold": "金辉收服球",
		"rainbow": "彩虹收服球",
		"food": "食物",
		"cleaning_tool": "清洁工具",
		"healing_item": "恢复道具"
	}.get(item_id, item_id)


func _setup_settings_controls() -> void:
	_sync_settings_controls()
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	master_slider.drag_ended.connect(_on_settings_slider_drag_ended)
	music_slider.drag_ended.connect(_on_settings_slider_drag_ended)
	sfx_slider.drag_ended.connect(_on_settings_slider_drag_ended)


func _sync_settings_controls() -> void:
	if not is_node_ready():
		return
	_settings_syncing = true
	var settings: Dictionary = SettingsManager.get_settings()
	master_slider.value = float(settings.get("master_volume", 0.85))
	music_slider.value = float(settings.get("music_volume", 0.72))
	sfx_slider.value = float(settings.get("sfx_volume", 0.82))
	fullscreen_check.button_pressed = bool(settings.get("fullscreen", false))
	_update_setting_value(master_value, master_slider.value)
	_update_setting_value(music_value, music_slider.value)
	_update_setting_value(sfx_value, sfx_slider.value)
	_settings_syncing = false


func _on_master_volume_changed(value: float) -> void:
	_update_setting_value(master_value, value)
	if not _settings_syncing:
		SettingsManager.set_master_volume(value)


func _on_music_volume_changed(value: float) -> void:
	_update_setting_value(music_value, value)
	if not _settings_syncing:
		SettingsManager.set_music_volume(value)


func _on_sfx_volume_changed(value: float) -> void:
	_update_setting_value(sfx_value, value)
	if not _settings_syncing:
		SettingsManager.set_sfx_volume(value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	if _settings_syncing:
		return
	SettingsManager.set_fullscreen(enabled)
	AudioManager.play_ui()


func _on_settings_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		AudioManager.play_ui()


func _update_setting_value(label: Label, value: float) -> void:
	label.text = "%d%%" % int(round(value * 100.0))

func _start_explore() -> void:
	GameState.start_explore()

func _observe_encounter() -> void:
	GameState.set_message("先观察一下 %s 的习性。" % _encounter_display_name())

func _encounter_display_name() -> String:
	var spirit: SpiritData = GameCatalog.get_spirit_by_id(GameState.current_encounter_id)
	return spirit.display_name if spirit != null else "这只萌灵"

func _open_battle_from_encounter() -> void:
	if GameState.current_encounter_id != "":
		BattleManager.prepare_battle(GameState.current_encounter_id, GameState.current_encounter_habitat_id)

func _leave_encounter() -> void:
	GameState.leave_encounter()

func _return_to_encounter() -> void:
	GameState.current_panel = "encounter"
	GameState.ui_state_changed.emit(GameState.current_panel)

func _open_dex() -> void:
	AudioManager.play_ui()
	GameState.open_dex()


func _open_home() -> void:
	AudioManager.play_ui()
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

func _on_battle_spirit_selected(index: int) -> void:
	GameState.selected_battle_spirit_id = String(battle_spirit_select.get_item_metadata(index))

func _scene_intro_parts(scene_id: String) -> PackedStringArray:
	match scene_id:
		"test_world":
			return PackedStringArray(["新手岛", "迎风广场"])
		"grove_gate":
			return PackedStringArray(["第二探索区", "林间入口"])
		_:
			return PackedStringArray(["新手岛", "迎风广场"])

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

func _apply_display_profile(_profile: DeviceProfile) -> void:
	var ui_scale: float = DisplayManager.get_ui_scale()
	var font_scale: float = DisplayManager.get_font_scale()
	var density: float = DisplayManager.get_canvas_density_scale()
	var safe_margins: Vector4i = DisplayManager.get_safe_margins()
	var compact: bool = DisplayManager.is_mobile_layout() or get_viewport().get_visible_rect().size.y < 560.0
	var hud_scale: float = 0.82 * density if compact else min(ui_scale, 1.0)
	var hud_font_scale: float = 0.86 * density if compact else min(font_scale, 1.0)
	_apply_hud_layout(hud_scale, hud_font_scale, safe_margins)
	_apply_panel_typography(ui_scale, font_scale, compact, density)
	_apply_button_sizes(ui_scale, compact, density)
	_apply_modal_layout(ui_scale, compact, density)
	_apply_main_menu_layout(compact, density)


func _apply_modal_layout(ui_scale: float, compact: bool, density: float) -> void:
	if habitat_modal == null or encounter_modal == null or battle_prep_modal == null:
		return
	var scale_factor: float = density if compact else min(ui_scale, 1.08)
	habitat_modal.call("set_preferred_size", Vector2(740.0, 320.0) * scale_factor if compact else HABITAT_MODAL_SIZE * scale_factor)
	encounter_modal.call("set_preferred_size", Vector2(650.0, 300.0) * scale_factor if compact else ENCOUNTER_MODAL_SIZE * scale_factor)
	battle_prep_modal.call("set_preferred_size", Vector2(740.0, 320.0) * scale_factor if compact else BATTLE_PREP_MODAL_SIZE * scale_factor)
	battle_spirit_scroll.custom_minimum_size.y = (82.0 if compact else 190.0) * scale_factor


func _apply_hud_layout(ui_scale: float, font_scale: float, safe_margins: Vector4i) -> void:
	hud_margin.add_theme_constant_override("margin_left", int(round(BASE_HUD_MARGIN * ui_scale)) + safe_margins.x)
	hud_margin.add_theme_constant_override("margin_top", int(round(BASE_HUD_MARGIN * ui_scale)) + safe_margins.y)
	hud_margin.add_theme_constant_override("margin_right", int(round(BASE_HUD_MARGIN * ui_scale)) + safe_margins.z)
	hud_margin.add_theme_constant_override("margin_bottom", int(round(BASE_HUD_MARGIN * ui_scale)) + safe_margins.w)
	screen_layout.add_theme_constant_override("separation", int(round(12 * ui_scale)))
	top_hud.add_theme_constant_override("separation", int(round(BASE_HUD_SPACING * ui_scale)))
	action_buttons.add_theme_constant_override("separation", int(round(BASE_HUD_SPACING * ui_scale)))
	location_card.custom_minimum_size = BASE_LOCATION_CARD_SIZE * ui_scale
	island_label.add_theme_font_size_override("font_size", int(round(BASE_LOCATION_FONT * font_scale)))
	location_label.add_theme_font_size_override("font_size", int(round(16 * font_scale)))
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
	interaction_prompt.offset_left = -140.0 * ui_scale
	interaction_prompt.offset_right = 140.0 * ui_scale
	interaction_prompt.offset_bottom = -20.0 - float(safe_margins.w)
	interaction_prompt.offset_top = interaction_prompt.offset_bottom - 52.0 * ui_scale


func _apply_panel_typography(ui_scale: float, font_scale: float, compact: bool, density: float) -> void:
	var panel_padding: int = int(round(6.0 * density)) if compact else int(round(18.0 * ui_scale))
	var spacing: int = int(round(6.0 * density)) if compact else int(round(14.0 * ui_scale))
	for margin in [habitat_margin, encounter_margin, battle_prep_margin]:
		margin.add_theme_constant_override("margin_left", panel_padding)
		margin.add_theme_constant_override("margin_top", panel_padding)
		margin.add_theme_constant_override("margin_right", panel_padding)
		margin.add_theme_constant_override("margin_bottom", panel_padding)
	for box in [habitat_box, encounter_box, battle_prep_box]:
		box.add_theme_constant_override("separation", spacing)
	for label in [habitat_title, encounter_title, battle_prep_title]:
		label.add_theme_font_size_override("font_size", int(round((20.0 * density) if compact else BASE_PANEL_TITLE_FONT * font_scale)))
	for label in [habitat_body, encounter_body, battle_prep_info]:
		label.add_theme_font_size_override("font_size", int(round((13.0 * density) if compact else BASE_PANEL_BODY_FONT * font_scale)))
	for label in [habitat_status, encounter_stats, battle_empty_label, battle_scroll_hint]:
		label.add_theme_font_size_override("font_size", int(round((12.0 * density) if compact else BASE_PANEL_STATUS_FONT * font_scale)))
	habitat_preview_row.add_theme_constant_override("separation", int(round((6.0 * density) if compact else 10.0 * ui_scale)))
	battle_prep_footer.add_theme_constant_override("separation", int(round((6.0 * density) if compact else 12.0 * ui_scale)))
	battle_spirit_select.add_theme_font_size_override("font_size", int(round((13.0 * density) if compact else BASE_PANEL_BODY_FONT * font_scale)))


func _apply_button_sizes(ui_scale: float, compact: bool, density: float) -> void:
	var compact_scale: float = density if compact else 1.0
	var button_height: float = 42.0 * compact_scale if compact else BASE_BUTTON_HEIGHT * ui_scale
	for button in [habitat_explore_button, habitat_back_button, encounter_capture_button, encounter_battle_button, encounter_back_button, battle_prep_back_button]:
		button.custom_minimum_size.y = button_height
	battle_spirit_select.custom_minimum_size.y = 38.0 * compact_scale if compact else BASE_BUTTON_HEIGHT * ui_scale
	battle_prep_start_button.custom_minimum_size = Vector2(190.0, 44.0) * compact_scale if compact else Vector2(260.0 * ui_scale, BASE_LARGE_BUTTON_HEIGHT * ui_scale)
	battle_prep_back_button.custom_minimum_size.x = 110.0 * compact_scale if compact else 160.0 * ui_scale
	encounter_portrait.custom_minimum_size.y = 92.0 * compact_scale if compact else 190.0 * ui_scale
	habitat_icon.custom_minimum_size = Vector2(74.0, 74.0) * compact_scale if compact else Vector2(108.0 * ui_scale, 108.0 * ui_scale)


func _apply_main_menu_layout(compact: bool, density: float) -> void:
	var compact_scale: float = density if compact else 1.0
	main_menu.call("set_preferred_size", Vector2(740.0, 318.0) * compact_scale if compact else Vector2(760.0, 500.0))
	main_menu_page_host.custom_minimum_size.y = 140.0 * compact_scale if compact else 290.0
	for button in [main_menu_party_tab, main_menu_inventory_tab, main_menu_settings_tab, main_menu_close_button]:
		button.custom_minimum_size = Vector2(104.0, 36.0) * compact_scale if compact else Vector2(132.0, 48.0)
		button.add_theme_font_size_override("font_size", int(round((13.0 * compact_scale) if compact else 16.0 * DisplayManager.get_font_scale())))
	for row_name in ["MasterRow", "MusicRow", "SfxRow"]:
		var row: HBoxContainer = main_menu_settings_page.get_node(row_name) as HBoxContainer
		var slider: HSlider = row.get_node("Slider") as HSlider
		slider.custom_minimum_size = Vector2(260.0, 30.0) * compact_scale if compact else Vector2(380.0, 48.0)
		(row.get_node("Label") as Label).add_theme_font_size_override("font_size", int(round((12.0 * compact_scale) if compact else 16.0)))
		(row.get_node("Value") as Label).add_theme_font_size_override("font_size", int(round((12.0 * compact_scale) if compact else 16.0)))
	fullscreen_check.custom_minimum_size.y = 30.0 * compact_scale if compact else 48.0
	fullscreen_check.add_theme_font_size_override("font_size", int(round((12.0 * compact_scale) if compact else 16.0)))
	for page in [main_menu_party_page, main_menu_inventory_page, main_menu_settings_page]:
		page.add_theme_constant_override("separation", int(round((4.0 * compact_scale) if compact else 10.0)))
	main_menu_party_page.get_node("Hint").visible = not compact
	main_menu_inventory_page.get_node("Hint").visible = not compact

func _configure_modal_panels() -> void:
	if not DisplayManager.is_mobile_layout():
		_configure_habitat_story_layout()
		_configure_encounter_story_layout()
	habitat_modal = _wrap_secondary_modal("HabitatModal", "栖息地详情", habitat_panel, HABITAT_MODAL_SIZE)
	encounter_modal = _wrap_secondary_modal("EncounterModal", "遇见萌灵！", encounter_panel, ENCOUNTER_MODAL_SIZE)
	battle_prep_modal = _wrap_secondary_modal("BattlePrepModal", "出战准备", battle_prep_panel, BATTLE_PREP_MODAL_SIZE)
	habitat_title.visible = true
	encounter_title.visible = true
	battle_prep_title.visible = true
	_style_modal_button(habitat_explore_button, true)
	_style_modal_button(habitat_back_button, false)
	_style_modal_button(encounter_capture_button, false)
	_style_modal_button(encounter_battle_button, true)
	_style_modal_button(encounter_back_button, false)
	_style_modal_button(battle_prep_start_button, true)
	_style_modal_button(battle_prep_back_button, false)
	battle_spirit_select.add_theme_color_override("font_color", Color("5b4028"))
	battle_spirit_select.add_theme_stylebox_override("normal", _build_button_style(Color("fff6df"), Color("b58d61")))


func _wrap_secondary_modal(node_name: String, title_text: String, panel: PanelContainer, preferred_size: Vector2) -> Control:
	var shell: Control = MODAL_SHELL_SCENE.instantiate() as Control
	shell.name = node_name
	shell.set("title", title_text)
	shell.z_index = 120
	root.add_child(shell)
	shell.call("set_preferred_size", preferred_size)
	shell.connect("close_requested", GameState.close_panel)
	var content: MarginContainer = shell.get_node("ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content") as MarginContainer
	panel.reparent(content)
	panel.visible = true
	panel.custom_minimum_size = Vector2.ZERO
	panel.position = Vector2.ZERO
	panel.size = Vector2.ZERO
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	return shell

func _configure_habitat_story_layout() -> void:
	if habitat_split.get_node_or_null("HabitatLeftColumn") != null:
		return
	habitat_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	habitat_split.add_theme_constant_override("separation", 28)

	var left_column: VBoxContainer = VBoxContainer.new()
	left_column.name = "HabitatLeftColumn"
	left_column.custom_minimum_size = Vector2(410.0, 0.0)
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 12)
	habitat_split.add_child(left_column)
	habitat_split.move_child(left_column, 0)

	var art_card: PanelContainer = PanelContainer.new()
	art_card.name = "HabitatArtCard"
	art_card.custom_minimum_size = Vector2(0.0, 245.0)
	art_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_card.add_theme_stylebox_override("panel", _build_habitat_art_style())
	left_column.add_child(art_card)
	var art_margin: MarginContainer = MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		art_margin.add_theme_constant_override(side, 16)
	art_card.add_child(art_margin)
	var art_canvas: Control = Control.new()
	art_canvas.custom_minimum_size = Vector2(360.0, 210.0)
	art_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_margin.add_child(art_canvas)
	habitat_icon.reparent(art_canvas)
	habitat_icon.set_anchors_preset(Control.PRESET_CENTER)
	habitat_icon.offset_left = -115.0
	habitat_icon.offset_top = -105.0
	habitat_icon.offset_right = 115.0
	habitat_icon.offset_bottom = 105.0
	habitat_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	habitat_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var habitat_preview: Control = habitat_box.get_node("HabitatPreview") as Control
	habitat_preview.reparent(left_column)
	var preview_title: Label = habitat_preview.get_node("PreviewTitle") as Label
	preview_title.text = "可能遇到的萌灵"
	preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	habitat_preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	habitat_preview_row.add_theme_constant_override("separation", 10)

	habitat_info.custom_minimum_size = Vector2(420.0, 0.0)
	habitat_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	habitat_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	habitat_info.add_theme_constant_override("separation", 18)
	habitat_title.add_theme_font_size_override("font_size", 34)
	habitat_title.add_theme_color_override("font_color", Color("5b4028"))
	habitat_body.add_theme_font_size_override("font_size", 18)
	habitat_body.add_theme_color_override("font_color", Color("6f5945"))
	habitat_status.visible = false

	var rule: HSeparator = HSeparator.new()
	habitat_info.add_child(rule)
	habitat_info.move_child(rule, 1)

	var stats_row: HBoxContainer = HBoxContainer.new()
	stats_row.name = "HabitatStatsRow"
	stats_row.add_theme_constant_override("separation", 12)
	habitat_info.add_child(stats_row)
	habitat_discovered_badge = _add_habitat_stat_badge(stats_row, "已发现  0/0", Color("76a93d"))
	habitat_resident_badge = _add_habitat_stat_badge(stats_row, "已入住  0/0", Color("d97932"))

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	habitat_info.add_child(spacer)
	var habitat_buttons: HBoxContainer = habitat_box.get_node("HabitatButtons") as HBoxContainer
	habitat_buttons.reparent(habitat_info)
	habitat_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	habitat_explore_button.text = "开始探索"
	habitat_back_button.text = "关闭"
	habitat_explore_button.custom_minimum_size = Vector2(230.0, 64.0)
	habitat_back_button.custom_minimum_size = Vector2(150.0, 64.0)

func _add_habitat_stat_badge(parent: HBoxContainer, text: String, accent: Color) -> Label:
	var badge: PanelContainer = PanelContainer.new()
	badge.custom_minimum_size = Vector2(190.0, 70.0)
	badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badge.add_theme_stylebox_override("panel", _build_stat_badge_style())
	parent.add_child(badge)
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", accent)
	badge.add_child(label)
	return label

func _build_habitat_art_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("f5f1cf")
	style.border_color = Color("d7b36f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	return style

func _build_stat_badge_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("fff6df")
	style.border_color = Color("dfbc82")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style

func _configure_encounter_story_layout() -> void:
	if encounter_box.get_node_or_null("StorySplit") != null:
		return
	var split: HBoxContainer = HBoxContainer.new()
	split.name = "StorySplit"
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 18)
	encounter_box.add_child(split)
	encounter_box.move_child(split, 1)

	var portrait_card: PanelContainer = PanelContainer.new()
	portrait_card.custom_minimum_size = Vector2(300.0, 0.0)
	portrait_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_card.add_theme_stylebox_override("panel", _build_button_style(Color("f4f0cb"), Color("c9ad78")))
	split.add_child(portrait_card)
	var portrait_margin: MarginContainer = MarginContainer.new()
	portrait_margin.add_theme_constant_override("margin_left", 16)
	portrait_margin.add_theme_constant_override("margin_top", 16)
	portrait_margin.add_theme_constant_override("margin_right", 16)
	portrait_margin.add_theme_constant_override("margin_bottom", 16)
	portrait_card.add_child(portrait_margin)
	encounter_portrait.reparent(portrait_margin)
	encounter_portrait.custom_minimum_size = Vector2(260.0, 260.0)

	var info_card: PanelContainer = PanelContainer.new()
	info_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_card.add_theme_stylebox_override("panel", _build_button_style(Color("fffaf0"), Color("ddc59a")))
	split.add_child(info_card)
	var info_margin: MarginContainer = MarginContainer.new()
	info_margin.add_theme_constant_override("margin_left", 22)
	info_margin.add_theme_constant_override("margin_top", 22)
	info_margin.add_theme_constant_override("margin_right", 22)
	info_margin.add_theme_constant_override("margin_bottom", 22)
	info_card.add_child(info_margin)
	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 14)
	info_margin.add_child(info_box)
	encounter_stats.reparent(info_box)
	encounter_body.reparent(info_box)
	encounter_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	encounter_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
func _set_storybook_title(panel: PanelContainer, text: String) -> void:
	var shell: Control = habitat_modal if panel == habitat_panel else encounter_modal if panel == encounter_panel else battle_prep_modal
	if shell != null:
		shell.set("title", text)

func _style_modal_button(button: Button, primary: bool) -> void:
	button.add_theme_color_override("font_color", Color.WHITE if primary else Color("5b4028"))
	var normal_color: Color = Color("76b947") if primary else Color("f6e7c9")
	var hover_color: Color = Color("8ac95c") if primary else Color("e7f0bd")
	var pressed_color: Color = Color("5e9d3a") if primary else Color("d9e3a5")
	var border: Color = Color("4f8330") if primary else Color("ae875c")
	button.add_theme_stylebox_override("normal", _build_button_style(normal_color, border))
	button.add_theme_stylebox_override("hover", _build_button_style(hover_color, border))
	button.add_theme_stylebox_override("pressed", _build_button_style(pressed_color, border))
	button.add_theme_stylebox_override("disabled", _build_button_style(Color("d8cfbd"), Color("b9ad9b")))

func _build_button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style
func _configure_static_hud() -> void:
	var toast_style: StyleBoxFlat = _build_card_style(Color(0.964706, 0.933333, 0.862745, 0.92))
	area_intro_toast.add_theme_stylebox_override("panel", toast_style)
	area_intro_toast.visible = false
	quest_card.visible = false
	dex_button.text = ""
	home_button.text = ""
	dex_button.tooltip_text = "打开萌灵图鉴"
	home_button.tooltip_text = "进入萌灵小屋"

func _set_world_action_hover(button: Button, hovered: bool) -> void:
	var icon: TextureRect = button.get_node("Content/Icon") as TextureRect
	var highlighted: bool = hovered or button.has_focus() or button.is_hovered()
	button.pivot_offset = button.size * 0.5
	icon.pivot_offset = icon.size * 0.5
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(button, "position:y", -2.0 if highlighted else 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", Vector2(1.04, 1.04) if highlighted else Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
func _set_world_action_pressed(button: Button, pressed: bool) -> void:
	button.pivot_offset = button.size * 0.5
	var target_scale: Vector2 = Vector2(0.975, 0.975) if pressed else Vector2.ONE
	var duration: float = 0.09 if pressed else 0.1
	var tween: Tween = create_tween()
	tween.tween_property(button, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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