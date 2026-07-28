extends Node

signal profile_changed(profile: DeviceProfile)

const MOBILE_PROFILE_PATH := "res://resources/mobile_landscape_profile.tres"
const DESKTOP_PROFILE_PATH := "res://resources/desktop_profile.tres"
const COMPACT_LANDSCAPE_MAX_HEIGHT: float = 540.0
const COMPACT_LANDSCAPE_MIN_ASPECT: float = 1.45

var forced_mode: StringName = &"auto"
var active_profile: DeviceProfile
var _active_profile_path: String = ""


func _ready() -> void:
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_reload_active_profile(true)


func _exit_tree() -> void:
	if get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)


func get_active_profile() -> DeviceProfile:
	if active_profile == null:
		_reload_active_profile(true)
	return active_profile


func get_camera_zoom() -> Vector2:
	var profile: DeviceProfile = get_active_profile()
	return profile.camera_zoom if profile != null else Vector2.ONE


func get_canvas_density_scale() -> float:
	var window_size: Vector2 = Vector2(get_tree().root.size)
	var viewport_size: Vector2 = get_tree().root.get_visible_rect().size
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return 1.0
	return max(1.0, viewport_size.x / window_size.x, viewport_size.y / window_size.y)


func get_ui_scale() -> float:
	var profile: DeviceProfile = get_active_profile()
	var profile_scale: float = profile.ui_scale if profile != null else 1.0
	return profile_scale * get_canvas_density_scale()


func get_font_scale() -> float:
	var profile: DeviceProfile = get_active_profile()
	var profile_scale: float = profile.font_scale if profile != null else 1.0
	return profile_scale * get_canvas_density_scale()


func uses_virtual_controls() -> bool:
	var profile: DeviceProfile = get_active_profile()
	return profile != null and profile.show_virtual_controls and is_landscape()


func get_safe_margins() -> Vector4i:
	var profile: DeviceProfile = get_active_profile()
	var configured_raw: Vector4i = profile.get_safe_margins() if profile != null else Vector4i.ZERO
	var density: float = get_canvas_density_scale()
	var configured: Vector4i = Vector4i(
		int(round(float(configured_raw.x) * density)),
		int(round(float(configured_raw.y) * density)),
		int(round(float(configured_raw.z) * density)),
		int(round(float(configured_raw.w) * density))
	)
	var system: Vector4i = _get_system_safe_margins()
	return Vector4i(
		configured.x + system.x,
		configured.y + system.y,
		configured.z + system.z,
		configured.w + system.w
	)


func get_profile_safe_margins() -> Vector4i:
	var profile: DeviceProfile = get_active_profile()
	return profile.get_safe_margins() if profile != null else Vector4i.ZERO


func set_forced_mode(mode: StringName) -> void:
	if mode not in [&"auto", &"mobile", &"desktop"]:
		push_warning("DisplayManager ignored unsupported forced mode: %s" % String(mode))
		return
	if mode == forced_mode:
		return
	forced_mode = mode
	_reload_active_profile(true)


func clear_forced_mode() -> void:
	set_forced_mode(&"auto")


func is_mobile_layout() -> bool:
	match forced_mode:
		&"mobile":
			return true
		&"desktop":
			return false
	var viewport_size: Vector2 = Vector2(get_tree().root.size)
	var compact_landscape: bool = (
		viewport_size.y > 0.0
		and viewport_size.y <= COMPACT_LANDSCAPE_MAX_HEIGHT
		and viewport_size.x / viewport_size.y >= COMPACT_LANDSCAPE_MIN_ASPECT
	)
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or compact_landscape


func is_landscape() -> bool:
	var viewport_size: Vector2 = Vector2(get_tree().root.size)
	return viewport_size.x >= viewport_size.y


func describe_active_profile() -> Dictionary:
	var profile: DeviceProfile = get_active_profile()
	if profile == null:
		return {}
	return {
		"forced_mode": String(forced_mode),
		"profile_id": String(profile.profile_id),
		"display_name": profile.display_name,
		"camera_zoom": profile.camera_zoom,
		"ui_scale": get_ui_scale(),
		"font_scale": get_font_scale(),
		"canvas_density_scale": get_canvas_density_scale(),
		"profile_safe_margins": profile.get_safe_margins(),
		"system_safe_margins": _get_system_safe_margins(),
		"safe_margins": get_safe_margins(),
		"window_size": get_tree().root.size,
		"viewport_size": get_tree().root.get_visible_rect().size,
		"orientation": "landscape" if is_landscape() else "portrait",
		"show_virtual_controls": uses_virtual_controls()
	}


func _on_viewport_size_changed() -> void:
	_reload_active_profile(true)


func _reload_active_profile(force_emit: bool = false) -> void:
	var profile_path: String = MOBILE_PROFILE_PATH if is_mobile_layout() else DESKTOP_PROFILE_PATH
	var changed: bool = profile_path != _active_profile_path or active_profile == null
	if changed:
		var loaded: Resource = load(profile_path)
		if loaded is DeviceProfile:
			active_profile = loaded as DeviceProfile
			_active_profile_path = profile_path
		else:
			push_warning("DisplayManager failed to load profile: %s" % profile_path)
			active_profile = null
			_active_profile_path = ""
	if changed or force_emit:
		profile_changed.emit(active_profile)


func _get_system_safe_margins() -> Vector4i:
	var viewport_size: Vector2 = get_tree().root.get_visible_rect().size
	var window_size: Vector2i = DisplayServer.window_get_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or window_size.x <= 0 or window_size.y <= 0:
		return Vector4i.ZERO
	var screen_index: int = DisplayServer.window_get_current_screen()
	var screen_position: Vector2i = DisplayServer.screen_get_position(screen_index)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_index)
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
			safe_rect = DisplayServer.screen_get_usable_rect(screen_index)
		else:
			return Vector4i.ZERO
	if screen_size.x <= 0 or screen_size.y <= 0:
		return Vector4i.ZERO
	var safe_local_position: Vector2i = safe_rect.position - screen_position
	var raw_left: int = max(0, safe_local_position.x)
	var raw_top: int = max(0, safe_local_position.y)
	var raw_right: int = max(0, screen_size.x - safe_local_position.x - safe_rect.size.x)
	var raw_bottom: int = max(0, screen_size.y - safe_local_position.y - safe_rect.size.y)
	var scale_to_viewport: Vector2 = Vector2(viewport_size.x / float(window_size.x), viewport_size.y / float(window_size.y))
	return Vector4i(
		int(round(raw_left * scale_to_viewport.x)),
		int(round(raw_top * scale_to_viewport.y)),
		int(round(raw_right * scale_to_viewport.x)),
		int(round(raw_bottom * scale_to_viewport.y))
	)