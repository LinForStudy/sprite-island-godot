extends Control

const PORTRAIT_CATALOG: Script = preload("res://scripts/ui/components/spirit_portrait_catalog.gd")
const CARD_SCENE: PackedScene = preload("res://scenes/ui/components/spirit_portrait_card.tscn")

@onready var grid: GridContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/DexContent/Catalog/Scroll/SpiritGrid
@onready var name_label: Label = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/DexContent/Detail/Margin/DetailLayout/Name
@onready var info_label: Label = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/DexContent/Detail/Margin/DetailLayout/Info
@onready var portrait: TextureRect = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/DexContent/Detail/Margin/DetailLayout/Portrait
@onready var progress_label: Label = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/Filters/Progress
@onready var all_filter: Button = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/Filters/All
@onready var residents_filter: Button = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/Filters/Residents
@onready var discovered_filter: Button = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/Filters/Discovered
@onready var unknown_filter: Button = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/Filters/Unknown
@onready var modal_shell: Control = $ModalShell
@onready var layout: VBoxContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout
@onready var filters: HBoxContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/Filters
@onready var dex_content: HBoxContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/DexContent
@onready var catalog: VBoxContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/DexContent/Catalog
@onready var detail: PanelContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/DexContent/Detail
@onready var detail_layout: VBoxContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/DexContent/Detail/Margin/DetailLayout

var filter_mode: String = "all"
var selected_card: Button
var selected_spirit_id: String = ""

func _ready() -> void:
	for button in [all_filter, residents_filter, discovered_filter, unknown_filter]:
		_style_filter(button)
	all_filter.pressed.connect(func() -> void: set_filter("all"))
	residents_filter.pressed.connect(func() -> void: set_filter("resident"))
	discovered_filter.pressed.connect(func() -> void: set_filter("discovered"))
	unknown_filter.pressed.connect(func() -> void: set_filter("unknown"))
	$ModalShell.close_requested.connect(GameState.close_panel)
	DisplayManager.profile_changed.connect(_apply_display_profile)
	_style_detail()
	_apply_display_profile(DisplayManager.get_active_profile())
	_refresh_cards()

func _exit_tree() -> void:
	if DisplayManager.profile_changed.is_connected(_apply_display_profile):
		DisplayManager.profile_changed.disconnect(_apply_display_profile)

func refresh() -> void:
	if not $ModalShell.visible:
		$ModalShell.open()
	_refresh_cards()

func set_filter(mode: String) -> void:
	if filter_mode == mode:
		return
	filter_mode = mode
	_refresh_cards()

func _refresh_cards() -> void:
	for child in grid.get_children():
		child.queue_free()
	selected_card = null
	var catalog: Array[SpiritData] = GameCatalog.get_spirits()
	var discovered_count: int = 0
	for spirit in catalog:
		if SaveManager.has_discovered(spirit.spirit_id):
			discovered_count += 1
	progress_label.text = "已发现 %d / %d · 已入住 %d" % [discovered_count, catalog.size(), SaveManager.get_captured_spirit_ids().size()]
	for spirit in catalog:
		var discovered: bool = SaveManager.has_discovered(spirit.spirit_id)
		var resident: bool = SaveManager.has_captured(spirit.spirit_id)
		if filter_mode == "resident" and not resident:
			continue
		if filter_mode == "discovered" and not discovered:
			continue
		if filter_mode == "unknown" and discovered:
			continue
		var card: Button = CARD_SCENE.instantiate()
		var texture: Texture2D = _portrait_for(spirit.spirit_id) if discovered else null
		var state: int = card.CardState.RESIDENT if resident else card.CardState.NORMAL if discovered else card.CardState.UNKNOWN
		card.tooltip_text = spirit.display_name if discovered else "未发现的萌灵"
		grid.add_child(card)
		card.configure(spirit.display_name, texture, state, _element_label(spirit.element), _rarity_label(spirit.rarity))
		_configure_card_layout(card)
		card.pressed.connect(func() -> void: _select_spirit(card, spirit, discovered, resident, texture))
		if spirit.spirit_id == selected_spirit_id or selected_card == null:
			_select_spirit(card, spirit, discovered, resident, texture)
	_update_filter_states()

func _select_spirit(card: Button, spirit: SpiritData, discovered: bool, resident: bool, texture: Texture2D) -> void:
	if selected_card != null and is_instance_valid(selected_card) and selected_card != card:
		selected_card.set_card_state(selected_card.CardState.UNKNOWN if selected_card.get_meta("unknown", false) else selected_card.CardState.RESIDENT if selected_card.get_meta("resident", false) else selected_card.CardState.NORMAL)
	selected_card = card
	selected_spirit_id = spirit.spirit_id
	card.set_meta("unknown", not discovered)
	card.set_meta("resident", resident)
	card.set_card_state(card.CardState.SELECTED)
	if not discovered:
		name_label.text = "未知萌灵"
		info_label.text = "状态：尚未记录\n\n继续探索岛屿，解锁这只萌灵的属性、稀有度和故事。"
		portrait.texture = PORTRAIT_CATALOG.get_texture(spirit.spirit_id)
		portrait.modulate = Color(0.22, 0.2, 0.16, 0.28)
		return
	name_label.text = spirit.display_name
	portrait.texture = texture
	portrait.modulate = Color.WHITE
	info_label.text = "属性：%s\n稀有度：%s\n状态：%s\n栖息地：%s\n最爱：%s\n\n%s" % [_element_label(spirit.element), _rarity_label(spirit.rarity), "已入住" if resident else "已发现", _habitat_label(spirit.habitat_id), spirit.favorite_food, spirit.description]

func _portrait_for(spirit_id: String) -> Texture2D:
	return PORTRAIT_CATALOG.get_texture(spirit_id)

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
			return "传说"
		"mythic":
			return "神话"
		_:
			return rarity

func _habitat_label(habitat_id: String) -> String:
	var habitat: HabitatData = GameCatalog.get_habitat_by_id(habitat_id)
	return habitat.display_name if habitat != null else habitat_id

func _style_filter(button: Button) -> void:
	button.add_theme_color_override("font_color", Color("5b4028"))
	button.add_theme_color_override("font_hover_color", Color("355c24"))
	button.add_theme_stylebox_override("normal", _box(Color("f4e7c9"), Color("b38a5d"), 2, 10))
	button.add_theme_stylebox_override("hover", _box(Color("e6f0bd"), Color("719c48"), 2, 10))
	button.add_theme_stylebox_override("pressed", _box(Color("c9df8c"), Color("5d8b3c"), 2, 10))

func _update_filter_states() -> void:
	for pair in [[all_filter, "all"], [residents_filter, "resident"], [discovered_filter, "discovered"], [unknown_filter, "unknown"]]:
		var button: Button = pair[0]
		if pair[1] == filter_mode:
			button.add_theme_stylebox_override("normal", _box(Color("c9df8c"), Color("5d8b3c"), 2, 10))
		else:
			button.add_theme_stylebox_override("normal", _box(Color("f4e7c9"), Color("b38a5d"), 2, 10))

func _style_detail() -> void:
	var shell: PanelContainer = $ModalShell/ModalCenter/ModalPanel
	var detail: PanelContainer = $ModalShell/ModalCenter/ModalPanel/PanelMargin/PanelLayout/Content/Layout/DexContent/Detail
	shell.add_theme_stylebox_override("panel", _shell_style())
	detail.add_theme_stylebox_override("panel", _box(Color("fff9ea"), Color("c29a6c"), 2, 16))
	name_label.add_theme_color_override("font_color", Color("4f3723"))

func _box(color: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	return box

func _shell_style() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color("fff9e9")
	box.set_corner_radius_all(20)
	return box
func _apply_display_profile(_profile: DeviceProfile) -> void:
	if not is_node_ready():
		return
	var compact: bool = DisplayManager.is_mobile_layout() or get_viewport().get_visible_rect().size.y < 560.0
	var density: float = min(DisplayManager.get_canvas_density_scale(), 1.35) if compact else 1.0
	modal_shell.call("set_preferred_size", Vector2(740.0, 340.0) * density if compact else Vector2(1080.0, 610.0))
	layout.add_theme_constant_override("separation", int(round((6.0 * density) if compact else 12.0)))
	filters.add_theme_constant_override("separation", int(round((6.0 * density) if compact else 8.0)))
	dex_content.add_theme_constant_override("separation", int(round((10.0 * density) if compact else 20.0)))
	catalog.custom_minimum_size = Vector2(300.0, 0.0) * density if compact else Vector2(380.0, 0.0)
	detail.custom_minimum_size = Vector2(292.0, 0.0) * density if compact else Vector2(460.0, 0.0)
	portrait.custom_minimum_size.y = 104.0 * density if compact else 242.0
	name_label.add_theme_font_size_override("font_size", int(round((22.0 * density) if compact else 30.0 * DisplayManager.get_font_scale())))
	info_label.add_theme_font_size_override("font_size", int(round((13.0 * density) if compact else 16.0 * DisplayManager.get_font_scale())))
	progress_label.add_theme_font_size_override("font_size", int(round((13.0 * density) if compact else 16.0 * DisplayManager.get_font_scale())))
	detail_layout.add_theme_constant_override("separation", int(round((4.0 * density) if compact else 8.0)))
	grid.columns = 4 if compact else 3
	grid.add_theme_constant_override("h_separation", int(round((6.0 * density) if compact else 10.0)))
	grid.add_theme_constant_override("v_separation", int(round((6.0 * density) if compact else 10.0)))
	for button in [all_filter, residents_filter, discovered_filter, unknown_filter]:
		button.custom_minimum_size = Vector2(68.0, 34.0) * density if compact else Vector2(84.0, 42.0)
		button.add_theme_font_size_override("font_size", int(round((13.0 * density) if compact else 16.0 * DisplayManager.get_font_scale())))
	_refresh_cards()


func _configure_card_layout(card: Button) -> void:
	var compact: bool = DisplayManager.is_mobile_layout() or get_viewport().get_visible_rect().size.y < 560.0
	var density: float = min(DisplayManager.get_canvas_density_scale(), 1.35) if compact else 1.0
	card.custom_minimum_size = Vector2(68.0, 98.0) * density if compact else Vector2(104.0, 140.0)
	var card_portrait: TextureRect = card.get_node("Card/Layout/Portrait") as TextureRect
	var card_name: Label = card.get_node("Card/Layout/Name") as Label
	var card_status: Label = card.get_node("Card/Layout/Status") as Label
	card_portrait.custom_minimum_size = Vector2(62.0, 56.0) * density if compact else Vector2(94.0, 92.0)
	card_name.add_theme_font_size_override("font_size", int(round((12.0 * density) if compact else 16.0)))
	card_status.add_theme_font_size_override("font_size", int(round((10.0 * density) if compact else 12.0)))