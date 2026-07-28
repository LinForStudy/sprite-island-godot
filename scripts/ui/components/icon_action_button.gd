extends Button

const BUTTON_RADIUS: int = 12
const PRIMARY_FILL := Color("f8e6bf")
const PRIMARY_HOVER := Color("e3f0bb")
const PRIMARY_PRESSED := Color("c7de8b")
const PRIMARY_BORDER := Color("ad8558")
const HOVER_BORDER := Color("6e9b49")
const PRESSED_BORDER := Color("5b893b")
const DISABLED_FILL := Color("dfd4c1")
const DISABLED_BORDER := Color("b8aa96")

@export var caption: String = "操作"
@export var action_icon: Texture2D
@onready var icon_view: TextureRect = $Layout/Icon
@onready var caption_label: Label = $Layout/Caption

func _ready() -> void:
	caption_label.text = caption
	icon_view.texture = action_icon
	focus_mode = Control.FOCUS_ALL
	caption_label.add_theme_color_override("font_color", Color("5b4028"))
	add_theme_stylebox_override("normal", _box(PRIMARY_FILL, PRIMARY_BORDER))
	add_theme_stylebox_override("hover", _box(PRIMARY_HOVER, HOVER_BORDER))
	add_theme_stylebox_override("pressed", _box(PRIMARY_PRESSED, PRESSED_BORDER))
	add_theme_stylebox_override("focus", _box(Color("fff9e9"), HOVER_BORDER))
	add_theme_stylebox_override("disabled", _box(DISABLED_FILL, DISABLED_BORDER))

func configure(label_text: String, icon_texture: Texture2D, is_disabled: bool = false) -> void:
	caption = label_text
	action_icon = icon_texture
	disabled = is_disabled
	if is_instance_valid(caption_label):
		caption_label.text = caption
		icon_view.texture = action_icon

func _box(color: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(BUTTON_RADIUS)
	return box