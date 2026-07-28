extends PanelContainer

const ELEMENTS := {
	"water": ["水", Color("54aedd")],
	"grass": ["叶", Color("76b947")],
	"fire": ["火", Color("d96157")],
	"wind": ["风", Color("79b8a2")],
	"earth": ["土", Color("b88a54")]
}

@onready var icon_label: Label = $Margin/Icon
@onready var text_label: Label = $Margin/Text

func _ready() -> void:
	configure("water")

func configure(element: String, caption: String = "") -> void:
	var definition: Array = ELEMENTS.get(element, ["·", Color("978875")])
	if not is_instance_valid(icon_label):
		return
	icon_label.text = str(definition[0])
	text_label.text = caption
	var color: Color = definition[1]
	icon_label.add_theme_color_override("font_color", color)
	text_label.add_theme_color_override("font_color", Color("756553"))
	add_theme_stylebox_override("panel", _box(color))

func _box(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color("fff9e9")
	box.border_color = color.darkened(0.2)
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	box.content_margin_left = 7
	box.content_margin_right = 7
	return box