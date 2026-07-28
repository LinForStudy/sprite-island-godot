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
	_style_detail()
	_refresh_cards()

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