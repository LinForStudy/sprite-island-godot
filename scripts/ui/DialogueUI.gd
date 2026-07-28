extends CanvasLayer

const BASE_PANEL_MARGINS: Vector4 = Vector4(26.0, 22.0, 26.0, 22.0)
const BASE_PANEL_HEIGHT: float = 172.0
const BASE_SPEAKER_FONT: int = 26
const BASE_BODY_FONT: int = 22
const BASE_HINT_FONT: int = 18

@onready var panel: Control = $Root
@onready var margin_container: MarginContainer = $Root/MarginContainer
@onready var content: VBoxContainer = $Root/MarginContainer/Content
@onready var speaker_label: Label = $Root/MarginContainer/Content/Speaker
@onready var body_label: Label = $Root/MarginContainer/Content/Body
@onready var hint_label: Label = $Root/MarginContainer/Content/Hint


func _ready() -> void:
	DisplayManager.profile_changed.connect(_apply_display_profile)
	InputRouter.touch_confirm_requested.connect(_on_touch_confirm_requested)
	InputRouter.touch_cancel_requested.connect(_on_touch_cancel_requested)
	_apply_display_profile(DisplayManager.get_active_profile())
	hide_dialogue()


func _exit_tree() -> void:
	InputRouter.set_exploration_blocked(&"dialogue", false)
	if DisplayManager.profile_changed.is_connected(_apply_display_profile):
		DisplayManager.profile_changed.disconnect(_apply_display_profile)
	if InputRouter.touch_confirm_requested.is_connected(_on_touch_confirm_requested):
		InputRouter.touch_confirm_requested.disconnect(_on_touch_confirm_requested)
	if InputRouter.touch_cancel_requested.is_connected(_on_touch_cancel_requested):
		InputRouter.touch_cancel_requested.disconnect(_on_touch_cancel_requested)


func toggle_dialogue(speaker: String, text: String) -> void:
	if panel.visible:
		hide_dialogue()
	else:
		show_dialogue(speaker, text)


func show_dialogue(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	body_label.text = text
	hint_label.text = "点按确认或返回关闭" if DisplayManager.uses_virtual_controls() else "按交互键关闭"
	panel.visible = true
	visible = true
	WorldState.set_dialogue_open(true)
	InputRouter.set_exploration_blocked(&"dialogue", true)
	_apply_display_profile(DisplayManager.get_active_profile())


func hide_dialogue() -> void:
	panel.visible = false
	visible = false
	WorldState.set_dialogue_open(false)
	InputRouter.set_exploration_blocked(&"dialogue", false)


func _on_touch_confirm_requested() -> void:
	if panel.visible:
		hide_dialogue()


func _on_touch_cancel_requested() -> void:
	if panel.visible:
		hide_dialogue()


func _apply_display_profile(_profile: DeviceProfile) -> void:
	if not is_node_ready():
		return
	var ui_scale: float = DisplayManager.get_ui_scale()
	var font_scale: float = DisplayManager.get_font_scale()
	var safe_margins: Vector4i = DisplayManager.get_safe_margins()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var compact: bool = DisplayManager.is_mobile_layout() or viewport_size.y < 600.0
	var density: float = DisplayManager.get_canvas_density_scale() if compact else 1.0
	var side_gap: float = (28.0 * density) if compact else 96.0
	var bottom_gap: float = (18.0 * density) if compact else 42.0
	var panel_height: float = min(BASE_PANEL_HEIGHT * (0.9 * density if compact else ui_scale), viewport_size.y * 0.46)
	panel.offset_left = float(safe_margins.x) + side_gap
	panel.offset_right = -float(safe_margins.z) - side_gap
	panel.offset_bottom = -float(safe_margins.w) - bottom_gap
	panel.offset_top = panel.offset_bottom - panel_height
	var padding_scale: float = 0.78 * density if compact else ui_scale
	margin_container.add_theme_constant_override("margin_left", int(round(BASE_PANEL_MARGINS.x * padding_scale)))
	margin_container.add_theme_constant_override("margin_top", int(round(BASE_PANEL_MARGINS.y * padding_scale)))
	margin_container.add_theme_constant_override("margin_right", int(round(BASE_PANEL_MARGINS.z * padding_scale)))
	margin_container.add_theme_constant_override("margin_bottom", int(round(BASE_PANEL_MARGINS.w * padding_scale)))
	content.add_theme_constant_override("separation", int(round((7.0 * density) if compact else 10.0 * ui_scale)))
	var responsive_font_scale: float = 0.9 * density if compact else font_scale
	speaker_label.add_theme_font_size_override("font_size", int(round(BASE_SPEAKER_FONT * responsive_font_scale)))
	body_label.add_theme_font_size_override("font_size", int(round(BASE_BODY_FONT * responsive_font_scale)))
	hint_label.add_theme_font_size_override("font_size", int(round(BASE_HINT_FONT * responsive_font_scale)))