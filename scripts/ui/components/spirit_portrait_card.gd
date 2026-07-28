extends Button

signal card_state_changed(state: CardState)

enum CardState { NORMAL, SELECTED, UNKNOWN, RESIDENT }

@onready var card: PanelContainer = $Card
@onready var portrait: TextureRect = $Card/Layout/Portrait
@onready var name_label: Label = $Card/Layout/Name
@onready var status_label: Label = $Card/Layout/Status
@onready var unknown_silhouette: Polygon2D = $Card/UnknownSilhouette

var card_state: CardState = CardState.NORMAL
var element_tag: String = ""
var rarity_tag: String = ""

func _ready() -> void:
	pressed.connect(func() -> void: set_card_state(CardState.SELECTED))
	_apply_state()

func configure(display_name: String, texture: Texture2D, state: CardState, element_text: String = "", rarity_text: String = "") -> void:
	element_tag = element_text
	rarity_tag = rarity_text
	name_label.text = display_name if state != CardState.UNKNOWN else "未发现"
	portrait.texture = texture if state != CardState.UNKNOWN else null
	set_card_state(state)

func set_card_state(state: CardState) -> void:
	card_state = state
	_apply_state()
	card_state_changed.emit(card_state)

func _apply_state() -> void:
	if not is_instance_valid(card):
		return
	var is_unknown: bool = card_state == CardState.UNKNOWN
	var is_selected: bool = card_state == CardState.SELECTED
	var is_resident: bool = card_state == CardState.RESIDENT
	unknown_silhouette.visible = is_unknown
	var state_text: String = "尚未记录" if is_unknown else "已入住" if is_resident else "已发现"
	if not is_unknown and element_tag != "" and rarity_tag != "":
		state_text = "%s · %s · %s" % [element_tag, rarity_tag, state_text]
	status_label.text = "✓ %s" % state_text if is_selected else state_text
	portrait.modulate = Color(0.34, 0.28, 0.20, 1.0) if is_unknown else Color.WHITE
	name_label.add_theme_color_override("font_color", Color("5b4028"))
	status_label.add_theme_color_override("font_color", Color("7d9260") if is_resident else Color("987b5b"))
	card.add_theme_stylebox_override("panel", _card_box(is_unknown, is_selected, is_resident))

func _card_box(is_unknown: bool, is_selected: bool, is_resident: bool) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color("e7dcc6") if is_unknown else Color("fdf5e4")
	if is_selected:
		box.bg_color = Color("edf6d6")
	box.border_color = Color("aa865b")
	if is_selected:
		box.border_color = Color("6fae47")
	elif is_resident:
		box.border_color = Color("87a65d")
	box.set_border_width_all(3 if is_selected else 2)
	box.set_corner_radius_all(12)
	box.content_margin_left = 4
	box.content_margin_top = 5
	box.content_margin_right = 4
	box.content_margin_bottom = 4
	return box