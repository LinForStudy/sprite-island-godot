extends CanvasLayer

# The dialogue layer is intentionally minimal in phase one.
# It only supports a single speaker line and toggle open/close behavior.

const BASE_PANEL_OFFSETS: Vector4 = Vector4(96.0, -214.0, -96.0, -42.0)
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
	_apply_display_profile(DisplayManager.get_active_profile())
	DisplayManager.profile_changed.connect(_apply_display_profile)
	hide_dialogue()


func _exit_tree() -> void:
	if DisplayManager.profile_changed.is_connected(_apply_display_profile):
		DisplayManager.profile_changed.disconnect(_apply_display_profile)


func toggle_dialogue(speaker: String, text: String) -> void:
	if panel.visible:
		hide_dialogue()
	else:
		show_dialogue(speaker, text)


func show_dialogue(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	body_label.text = text
	hint_label.text = "按交互键关闭"
	panel.visible = true
	visible = true
	WorldState.set_dialogue_open(true)


func hide_dialogue() -> void:
	panel.visible = false
	visible = false
	WorldState.set_dialogue_open(false)


func _apply_display_profile(profile: DeviceProfile) -> void:
	var ui_scale: float = profile.ui_scale if profile != null else 1.0
	var font_scale: float = profile.font_scale if profile != null else 1.0
	var safe_margins: Vector4i = profile.get_safe_margins() if profile != null else Vector4i.ZERO
	panel.offset_left = BASE_PANEL_OFFSETS.x + float(safe_margins.x)
	panel.offset_top = BASE_PANEL_OFFSETS.y - (BASE_PANEL_HEIGHT * (ui_scale - 1.0))
	panel.offset_right = BASE_PANEL_OFFSETS.z - float(safe_margins.z)
	panel.offset_bottom = BASE_PANEL_OFFSETS.w
	margin_container.add_theme_constant_override("margin_left", int(round(BASE_PANEL_MARGINS.x * ui_scale)))
	margin_container.add_theme_constant_override("margin_top", int(round(BASE_PANEL_MARGINS.y * ui_scale)))
	margin_container.add_theme_constant_override("margin_right", int(round(BASE_PANEL_MARGINS.z * ui_scale)))
	margin_container.add_theme_constant_override("margin_bottom", int(round(BASE_PANEL_MARGINS.w * ui_scale)))
	content.add_theme_constant_override("separation", int(round(10 * ui_scale)))
	speaker_label.add_theme_font_size_override("font_size", int(round(BASE_SPEAKER_FONT * font_scale)))
	body_label.add_theme_font_size_override("font_size", int(round(BASE_BODY_FONT * font_scale)))
	hint_label.add_theme_font_size_override("font_size", int(round(BASE_HINT_FONT * font_scale)))