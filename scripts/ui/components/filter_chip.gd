extends Button

signal filter_selected(filter_id: String)

const CHIP_RADIUS: int = 12
const SELECTED_FILL := Color("b8dc7a")
const SELECTED_BORDER := Color("76b947")
const NORMAL_FILL := Color("fff9e9")
const NORMAL_BORDER := Color("c8a26e")

@export var filter_id: String = "all"
@export var selected: bool = false:
	set(value):
		selected = value
		if is_inside_tree():
			_apply_style()

func _ready() -> void:
	pressed.connect(func() -> void: filter_selected.emit(filter_id))
	focus_mode = Control.FOCUS_ALL
	_apply_style()

func configure(caption: String, id: String, is_selected: bool) -> void:
	text = caption
	filter_id = id
	selected = is_selected
	if is_inside_tree():
		_apply_style()

func _apply_style() -> void:
	add_theme_font_size_override("font_size", 17)
	add_theme_color_override("font_color", Color("4a3b2c") if selected else Color("756553"))
	add_theme_stylebox_override("normal", _box(SELECTED_FILL if selected else NORMAL_FILL, SELECTED_BORDER if selected else NORMAL_BORDER))
	add_theme_stylebox_override("hover", _box(Color("dceeb7"), SELECTED_BORDER))
	add_theme_stylebox_override("pressed", _box(Color("a4cf64"), SELECTED_BORDER.darkened(0.1)))
	add_theme_stylebox_override("focus", _box(Color("fff9e9"), SELECTED_BORDER))

func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(CHIP_RADIUS)
	box.content_margin_left = 14
	box.content_margin_right = 14
	return box