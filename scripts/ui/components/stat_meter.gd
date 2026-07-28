extends VBoxContainer

const BAR_RADIUS: int = 8
const BAR_BACKGROUND := Color("ead9b8")
const BAR_BACKGROUND_BORDER := Color("ddc7a1")
const GOOD_FILL := Color("78b84f")
const WARN_FILL := Color("f0b55c")
const LOW_FILL := Color("d96157")

@export var label_text: String = "状态"
@onready var label: Label = $Header/Label
@onready var value_label: Label = $Header/Value
@onready var bar: ProgressBar = $Bar

func _ready() -> void:
	label.text = label_text
	label.add_theme_color_override("font_color", Color("5b4028"))
	value_label.add_theme_color_override("font_color", Color("7f664b"))
	bar.add_theme_stylebox_override("background", _box(BAR_BACKGROUND, BAR_BACKGROUND_BORDER, BAR_RADIUS))
	bar.add_theme_stylebox_override("fill", _box(GOOD_FILL, GOOD_FILL.darkened(0.2), BAR_RADIUS))

func set_value(value: float, maximum: float, animate: bool = true) -> void:
	bar.max_value = maxf(maximum, 1.0)
	value_label.text = "%d / %d" % [roundi(value), roundi(maximum)]
	var target: float = clampf(value, 0.0, bar.max_value)
	_apply_fill_color(target / bar.max_value)
	if animate:
		var tween: Tween = create_tween()
		tween.tween_property(bar, "value", target, 0.18)
	else:
		bar.value = target

func _apply_fill_color(ratio: float) -> void:
	var fill: Color = GOOD_FILL
	if ratio <= 0.3:
		fill = LOW_FILL
	elif ratio <= 0.6:
		fill = WARN_FILL
	bar.add_theme_stylebox_override("fill", _box(fill, fill.darkened(0.2), BAR_RADIUS))

func _box(color: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	return box