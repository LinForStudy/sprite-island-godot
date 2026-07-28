extends Control

signal close_requested

@export var title: String = "页面标题":
	set(value):
		title = value
		if is_instance_valid(title_label):
			title_label.text = title

@onready var dimmer: Button = $Dimmer
@onready var title_label: Label = $ModalCenter/ModalPanel/PanelMargin/PanelLayout/Header/Title
@onready var close_button: Button = $ModalCenter/ModalPanel/PanelMargin/PanelLayout/Header/CloseButton

func _ready() -> void:
	dimmer.pressed.connect(close)
	close_button.pressed.connect(close)
	title_label.text = title

func open() -> void:
	visible = true
	close_button.grab_focus()

func close() -> void:
	if not visible:
		return
	visible = false
	close_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if visible and what == NOTIFICATION_WM_GO_BACK_REQUEST:
		close()

func _close_box(color: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	return box