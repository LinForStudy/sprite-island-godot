extends Node

signal settings_changed(settings: Dictionary)

const SETTINGS_PATH := "user://settings.json"
const DEFAULT_SETTINGS: Dictionary = {
	"master_volume": 0.85,
	"music_volume": 0.72,
	"sfx_volume": 0.82,
	"fullscreen": false
}

var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)
	if FileAccess.file_exists(SETTINGS_PATH):
		var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				for key in DEFAULT_SETTINGS.keys():
					if Dictionary(parsed).has(key):
						settings[key] = Dictionary(parsed)[key]
	_normalize()
	apply_settings()


func save_settings() -> void:
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SettingsManager could not open %s" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify(settings, "\t"))
	settings_changed.emit(settings.duplicate(true))


func get_settings() -> Dictionary:
	return settings.duplicate(true)


func set_master_volume(value: float) -> void:
	_set_volume("master_volume", value, "Master")


func set_music_volume(value: float) -> void:
	_set_volume("music_volume", value, "Music")


func set_sfx_volume(value: float) -> void:
	_set_volume("sfx_volume", value, "SFX")


func set_fullscreen(enabled: bool) -> void:
	settings["fullscreen"] = enabled
	_apply_window_mode()
	save_settings()


func apply_settings() -> void:
	_apply_bus_volume("Master", float(settings.master_volume))
	_apply_bus_volume("Music", float(settings.music_volume))
	_apply_bus_volume("SFX", float(settings.sfx_volume))
	_apply_window_mode()
	settings_changed.emit(settings.duplicate(true))


func _set_volume(key: String, value: float, bus_name: String) -> void:
	settings[key] = clampf(value, 0.0, 1.0)
	_apply_bus_volume(bus_name, float(settings[key]))
	save_settings()


func _normalize() -> void:
	settings.master_volume = clampf(float(settings.get("master_volume", 0.85)), 0.0, 1.0)
	settings.music_volume = clampf(float(settings.get("music_volume", 0.72)), 0.0, 1.0)
	settings.sfx_volume = clampf(float(settings.get("sfx_volume", 0.82)), 0.0, 1.0)
	settings.fullscreen = bool(settings.get("fullscreen", false))


func _apply_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear_value, 0.0001)))
	AudioServer.set_bus_mute(bus_index, linear_value <= 0.0001)


func _apply_window_mode() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if bool(settings.fullscreen) else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
