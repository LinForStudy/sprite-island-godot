extends Button

const PRIMARY_FILL := Color("76b947")
const PRIMARY_HOVER := Color("8bc75a")
const PRIMARY_PRESSED := Color("5f9e3d")
const PRIMARY_BORDER := Color("4f8232")
const DISABLED_FILL := Color("d8d2c4")
const DISABLED_BORDER := Color("aaa294")
const BUTTON_RADIUS: int = 12

func _ready() -> void:
	tooltip_text = "关闭"
	text = "×"
	focus_mode = Control.FOCUS_ALL
	add_theme_font_size_override("font_size", 34)
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_stylebox_override("normal", _box(PRIMARY_FILL, PRIMARY_BORDER))
	add_theme_stylebox_override("hover", _box(PRIMARY_HOVER, PRIMARY_BORDER))
	add_theme_stylebox_override("pressed", _box(PRIMARY_PRESSED, PRIMARY_BORDER.darkened(0.1)))
	add_theme_stylebox_override("focus", _box(Color("e3f0bb"), PRIMARY_BORDER))
	add_theme_stylebox_override("disabled", _box(DISABLED_FILL, DISABLED_BORDER))

func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(BUTTON_RADIUS)
	return box