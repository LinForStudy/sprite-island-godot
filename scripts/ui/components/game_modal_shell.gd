extends Control

signal close_requested

@export var title: String = "页面标题":
	set(value):
		title = value
		if is_instance_valid(title_label):
			title_label.text = title

@onready var dimmer: Button = $Dimmer
@onready var modal_center: CenterContainer = $ModalCenter
@onready var modal_panel: PanelContainer = $ModalCenter/ModalPanel
@onready var panel_margin: MarginContainer = $ModalCenter/ModalPanel/PanelMargin
@onready var panel_layout: VBoxContainer = $ModalCenter/ModalPanel/PanelMargin/PanelLayout
@onready var title_label: Label = $ModalCenter/ModalPanel/PanelMargin/PanelLayout/Header/Title
@onready var close_button: Button = $ModalCenter/ModalPanel/PanelMargin/PanelLayout/Header/CloseButton

var _preferred_size: Vector2 = Vector2(720.0, 440.0)


func _ready() -> void:
	_preferred_size = modal_panel.custom_minimum_size
	dimmer.pressed.connect(close)
	close_button.pressed.connect(close)
	title_label.text = title
	DisplayManager.profile_changed.connect(_apply_display_profile)
	InputRouter.touch_cancel_requested.connect(_on_touch_cancel_requested)
	_apply_display_profile(DisplayManager.get_active_profile())


func _exit_tree() -> void:
	if DisplayManager.profile_changed.is_connected(_apply_display_profile):
		DisplayManager.profile_changed.disconnect(_apply_display_profile)
	if InputRouter.touch_cancel_requested.is_connected(_on_touch_cancel_requested):
		InputRouter.touch_cancel_requested.disconnect(_on_touch_cancel_requested)


func set_preferred_size(value: Vector2) -> void:
	_preferred_size = value
	_apply_display_profile(DisplayManager.get_active_profile())


func open() -> void:
	_apply_display_profile(DisplayManager.get_active_profile())
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


func _on_touch_cancel_requested() -> void:
	if visible and not WorldState.dialogue_open:
		close()


func _apply_display_profile(_profile: DeviceProfile) -> void:
	if not is_node_ready():
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var safe: Vector4i = DisplayManager.get_safe_margins()
	var compact: bool = DisplayManager.is_mobile_layout() or viewport_size.y < 560.0
	var density: float = min(DisplayManager.get_canvas_density_scale(), 1.35) if compact else 1.0
	var outer_gap: float = (12.0 * density) if compact else 24.0
	modal_center.offset_left = float(safe.x) + outer_gap
	modal_center.offset_top = float(safe.y) + outer_gap
	modal_center.offset_right = -float(safe.z) - outer_gap
	modal_center.offset_bottom = -float(safe.w) - outer_gap
	var available: Vector2 = Vector2(
		max(320.0 * density, viewport_size.x - float(safe.x + safe.z) - outer_gap * 2.0),
		max(240.0 * density, viewport_size.y - float(safe.y + safe.w) - outer_gap * 2.0)
	)
	modal_panel.custom_minimum_size = Vector2(min(_preferred_size.x, available.x), min(_preferred_size.y, available.y))
	var padding_x: int = int(round((14.0 * density) if compact else 28.0))
	var padding_y: int = int(round((12.0 * density) if compact else 24.0))
	panel_margin.add_theme_constant_override("margin_left", padding_x)
	panel_margin.add_theme_constant_override("margin_top", padding_y)
	panel_margin.add_theme_constant_override("margin_right", padding_x)
	panel_margin.add_theme_constant_override("margin_bottom", padding_y)
	panel_layout.add_theme_constant_override("separation", int(round((10.0 * density) if compact else 18.0)))
	title_label.add_theme_font_size_override("font_size", int(round((22.0 * density) if compact else 30.0 * DisplayManager.get_font_scale())))
	close_button.custom_minimum_size = Vector2(44.0, 44.0) * density if compact else Vector2(56.0, 56.0)