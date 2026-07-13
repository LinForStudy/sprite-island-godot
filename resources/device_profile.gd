extends Resource
class_name DeviceProfile

@export var profile_id: StringName = &"desktop"
@export var display_name: String = "Desktop"
@export var camera_zoom: Vector2 = Vector2.ONE
@export_range(0.5, 3.0, 0.05) var ui_scale: float = 1.0
@export_range(0.5, 2.0, 0.05) var font_scale: float = 1.0
@export var safe_margin_left: int = 0
@export var safe_margin_top: int = 0
@export var safe_margin_right: int = 0
@export var safe_margin_bottom: int = 0
@export var touch_button_size: Vector2 = Vector2(96, 96)
@export var show_virtual_controls: bool = false
@export var notes: String = ""

func get_safe_margins() -> Vector4i:
	return Vector4i(safe_margin_left, safe_margin_top, safe_margin_right, safe_margin_bottom)
