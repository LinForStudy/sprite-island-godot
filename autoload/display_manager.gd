extends Node

signal profile_changed(profile: DeviceProfile)

const MOBILE_PROFILE_PATH := "res://resources/mobile_landscape_profile.tres"
const DESKTOP_PROFILE_PATH := "res://resources/desktop_profile.tres"

var forced_mode: StringName = &"auto"
var active_profile: DeviceProfile

func _ready() -> void:
	_reload_active_profile()


func get_active_profile() -> DeviceProfile:
	if active_profile == null:
		_reload_active_profile()
	return active_profile


func get_camera_zoom() -> Vector2:
	var profile: DeviceProfile = get_active_profile()
	return profile.camera_zoom if profile != null else Vector2.ONE


func get_ui_scale() -> float:
	var profile: DeviceProfile = get_active_profile()
	return profile.ui_scale if profile != null else 1.0


func uses_virtual_controls() -> bool:
	var profile: DeviceProfile = get_active_profile()
	return profile.show_virtual_controls if profile != null else false


func get_safe_margins() -> Vector4i:
	var profile: DeviceProfile = get_active_profile()
	return profile.get_safe_margins() if profile != null else Vector4i.ZERO


func set_forced_mode(mode: StringName) -> void:
	if mode == forced_mode:
		return
	forced_mode = mode
	_reload_active_profile()


func clear_forced_mode() -> void:
	set_forced_mode(&"auto")


func is_mobile_layout() -> bool:
	match forced_mode:
		&"mobile":
			return true
		&"desktop":
			return false
		_:
			return OS.has_feature("mobile")


func describe_active_profile() -> Dictionary:
	var profile: DeviceProfile = get_active_profile()
	if profile == null:
		return {}
	return {
		"forced_mode": String(forced_mode),
		"profile_id": String(profile.profile_id),
		"display_name": profile.display_name,
		"camera_zoom": profile.camera_zoom,
		"ui_scale": profile.ui_scale,
		"font_scale": profile.font_scale,
		"safe_margins": profile.get_safe_margins(),
		"show_virtual_controls": profile.show_virtual_controls
	}


func _reload_active_profile() -> void:
	var profile_path: String = MOBILE_PROFILE_PATH if is_mobile_layout() else DESKTOP_PROFILE_PATH
	var loaded: Resource = load(profile_path)
	if loaded is DeviceProfile:
		active_profile = loaded as DeviceProfile
	else:
		push_warning("DisplayManager failed to load profile: %s" % profile_path)
		active_profile = null
	profile_changed.emit(active_profile)
